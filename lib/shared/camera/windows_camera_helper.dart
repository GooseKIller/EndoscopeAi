// ====================================================
//  Windows-specific camera helper to handle known issues
//  with camera_windows plugin and threading problems
// ====================================================

import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class WindowsCameraHelper {
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(milliseconds: 500);
  static const Duration _disposeDelay = Duration(milliseconds: 2000);

  // Static tracking to prevent multiple controllers for same camera
  static final Map<String, CameraController> _activeControllers = {};
  static final Map<String, bool> _initializingCameras = {};

  /// Safely initializes a camera controller with Windows-specific workarounds
  static Future<CameraController> initializeCamera(
    CameraDescription cameraDescription, {
    ResolutionPreset resolution = ResolutionPreset.medium,
    bool enableAudio = true,
  }) async {
    // Ensure we're running on Windows
    if (!Platform.isWindows) {
      throw UnsupportedError(
        'WindowsCameraHelper is only for Windows platform',
      );
    }

    final cameraKey = cameraDescription.name;

    // Check if camera is already being initialized and wait for it
    if (_initializingCameras[cameraKey] == true) {
      // Wait for existing initialization to complete
      int waitCount = 0;
      while (_initializingCameras[cameraKey] == true && waitCount < 10) {
        await Future.delayed(Duration(milliseconds: 500));
        waitCount++;
      }

      if (_activeControllers.containsKey(cameraKey)) {
        final existingController = _activeControllers[cameraKey]!;
        if (existingController.value.isInitialized) {
          return existingController;
        }
      }
    }

    // Check if camera already has an active controller and dispose it properly
    if (_activeControllers.containsKey(cameraKey)) {
      final existingController = _activeControllers[cameraKey]!;
      if (existingController.value.isInitialized) {
        await disposeCamera(existingController);
        // Wait a bit more to ensure complete cleanup
        await Future.delayed(Duration(milliseconds: 1000));
      }
    }

    _initializingCameras[cameraKey] = true;

    try {
      // Get available cameras and validate the target camera
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException(
          'no_cameras_available',
          'No cameras found on the system',
        );
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
        targetCamera,
        resolution,
        enableAudio: enableAudio,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      // Initialize with retry logic
      await _initializeWithRetry(controller);

      // Additional Windows-specific setup
      await _setupWindowsCamera(controller);

      // Track the active controller
      _activeControllers[cameraKey] = controller;

      return controller;
    } catch (e) {
      // Clean up on error
      _activeControllers.remove(cameraKey);
      rethrow;
    } finally {
      _initializingCameras[cameraKey] = false;
    }
  }

  /// Safely dispose a camera controller with proper cleanup
  static Future<void> disposeCamera(CameraController? controller) async {
    if (controller == null) return;

    // Find and remove from tracking
    String? cameraKey;
    for (final entry in _activeControllers.entries) {
      if (entry.value == controller) {
        cameraKey = entry.key;
        break;
      }
    }

    if (cameraKey != null) {
      _activeControllers.remove(cameraKey);
      _initializingCameras[cameraKey] = false;
    }

    if (!controller.value.isInitialized) return;

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

  /// Clear all active camera controllers (useful for app shutdown)
  static Future<void> disposeAllCameras() async {
    final controllers = List<CameraController>.from(_activeControllers.values);
    _activeControllers.clear();
    _initializingCameras.clear();

    for (final controller in controllers) {
      await disposeCamera(controller);
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
          throw CameraException(
            'initialization_failed',
            'Controller not properly initialized',
          );
        }
      } catch (e) {
        retryCount++;

        // Special handling for "already exists" error
        if (e is CameraException &&
            e.description?.contains('already exists') == true) {
          if (kDebugMode) {
            print(
              'Camera already exists error detected. Waiting longer before retry...',
            );
          }
          // Wait longer for this specific error
          await Future.delayed(Duration(seconds: 2 * retryCount));
        } else {
          // Progressive delay between retries for other errors
          await Future.delayed(
            Duration(milliseconds: _retryDelay.inMilliseconds * retryCount),
          );
        }

        if (retryCount >= _maxRetries) {
          if (kDebugMode) {
            print(
              'Camera initialization failed after $retryCount attempts: $e',
            );
          }
          rethrow;
        }

        if (kDebugMode) {
          print(
            'Camera initialization attempt $retryCount failed: $e. Retrying...',
          );
        }
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

  /// Check if a camera is available and ready for use
  static Future<bool> isCameraAvailable(CameraDescription camera) async {
    try {
      // First check if it's in our active controllers
      if (_activeControllers.containsKey(camera.name)) {
        final controller = _activeControllers[camera.name]!;
        return controller.value.isInitialized;
      }

      // Then check if it's being initialized
      if (_initializingCameras[camera.name] == true) {
        return false; // Still initializing
      }

      // Finally, try a quick test
      return !(await isCameraInUse(camera));
    } catch (e) {
      return false;
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
        case 'not_available':
          return 'Camera is not available. Please check if the camera is connected and drivers are installed.';
        case 'not_initialized':
          return 'Camera failed to initialize. Try restarting the application.';
      }
    }

    return 'Unknown camera error: ${error.toString()}';
  }
}
