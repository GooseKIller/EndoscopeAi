// ====================================================
//  Windows-specific camera helper to handle known issues
//  with camera_windows plugin and threading problems
// ====================================================

import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class WindowsCameraHelper {
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(milliseconds: 500);
  static const Duration _disposeDelay = Duration(milliseconds: 1000);

  /// Safely initializes a camera controller with Windows-specific workarounds
  static Future<CameraController> initializeCamera(
    CameraDescription cameraDescription, {
    ResolutionPreset resolution = ResolutionPreset.medium,
    bool enableAudio = true,
  }) async {
    // Ensure we're running on Windows
    if (!Platform.isWindows) {
      throw UnsupportedError('WindowsCameraHelper is only for Windows platform');
    }

    // Get available cameras and validate the target camera
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw CameraException('no_cameras_available', 'No cameras found on the system');
    }

    CameraDescription? targetCamera;
    for (final camera in cameras) {
      if (camera.name == cameraDescription.name) {
        targetCamera = camera;
        break;
      }
    }

    if (targetCamera == null) {
      if (kDebugMode) {
        print('Target camera not found, using first available camera');
      }
      targetCamera = cameras.first;
    }

    // Create controller with Windows-optimized settings
    final controller = CameraController(
      targetCamera!,
      resolution,
      enableAudio: enableAudio,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    // Initialize with retry logic
    await _initializeWithRetry(controller);

    // Additional Windows-specific setup
    await _setupWindowsCamera(controller);

    return controller;
  }

  /// Safely dispose a camera controller with proper cleanup
  static Future<void> disposeCamera(CameraController? controller) async {
    if (controller == null) return;

    try {
      // Stop any ongoing recording
      if (controller.value.isRecordingVideo) {
        try {
          await controller.stopVideoRecording();
        } catch (e) {
          if (kDebugMode) {
            print('Error stopping video recording during dispose: $e');
          }
        }
      }

      // Dispose the controller
      await controller.dispose();
      
      // Add delay to ensure complete cleanup on Windows
      await Future.delayed(_disposeDelay);
      
    } catch (e) {
      if (kDebugMode) {
        print('Error disposing camera controller: $e');
      }
    }
  }

  /// Initialize camera controller with retry logic for Windows
  static Future<void> _initializeWithRetry(CameraController controller) async {
    int retryCount = 0;
    
    while (retryCount < _maxRetries) {
      try {
        await controller.initialize();
        
        // Verify initialization was successful
        if (controller.value.isInitialized) {
          return; // Success
        } else {
          throw CameraException('initialization_failed', 'Controller not properly initialized');
        }
      } catch (e) {
        retryCount++;
        
        if (retryCount >= _maxRetries) {
          if (kDebugMode) {
            print('Camera initialization failed after $retryCount attempts: $e');
          }
          rethrow;
        }
        
        if (kDebugMode) {
          print('Camera initialization attempt $retryCount failed: $e. Retrying...');
        }
        
        // Progressive delay between retries
        await Future.delayed(Duration(milliseconds: _retryDelay.inMilliseconds * retryCount));
      }
    }
  }

  /// Apply Windows-specific camera settings
  static Future<void> _setupWindowsCamera(CameraController controller) async {
    try {
      // Disable flash if available (common cause of issues on Windows)
      await controller.setFlashMode(FlashMode.off);
    } catch (e) {
      if (kDebugMode) {
        print('Could not set flash mode: $e');
      }
    }

    try {
      // Set exposure mode to auto if supported
      await controller.setExposureMode(ExposureMode.auto);
    } catch (e) {
      if (kDebugMode) {
        print('Could not set exposure mode: $e');
      }
    }

    try {
      // Set focus mode to auto if supported
      await controller.setFocusMode(FocusMode.auto);
    } catch (e) {
      if (kDebugMode) {
        print('Could not set focus mode: $e');
      }
    }
  }

  /// Check if a camera is currently in use by another application
  static Future<bool> isCameraInUse(CameraDescription camera) async {
    try {
      final testController = CameraController(
        camera,
        ResolutionPreset.low,
        enableAudio: false,
      );
      
      await testController.initialize();
      await testController.dispose();
      
      return false; // Camera is available
    } catch (e) {
      return true; // Camera is likely in use
    }
  }

  /// Get detailed error information for Windows camera errors
  static String getWindowsCameraErrorDescription(dynamic error) {
    if (error is CameraException) {
      switch (error.code) {
        case 'camera_error':
          if (error.description?.contains('handle is invalid') == true) {
            return 'Camera handle is invalid. The camera may be in use by another application or the driver needs to be restarted.';
          } else if (error.description?.contains('already exists') == true) {
            return 'Camera is already in use. Please close other applications using the camera and try again.';
          } else if (error.description?.contains('access denied') == true) {
            return 'Camera access denied. Please check Windows privacy settings for camera access.';
          }
          break;
        case 'not_available':
          return 'Camera is not available. Please check if the camera is connected and drivers are installed.';
        case 'not_initialized':
          return 'Camera failed to initialize. Try restarting the application.';
      }
    }
    
    return 'Unknown camera error: ${error.toString()}';
  }
}
