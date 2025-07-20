import 'package:endoscopy_ai/routes.dart';
import 'package:flutter/material.dart';
import 'package:fvp/fvp.dart' as fvp;
import 'package:endoscopy_ai/features/ai/endo_ai.dart';

class FeatureInitializer extends StatefulWidget {
  static bool componentsInitialized = false;

  const FeatureInitializer({Key? key}) : super(key: key);

  @override
  _FeatureInitializerState createState() => _FeatureInitializerState();
}

class _FeatureInitializerState extends State<FeatureInitializer> {
  String _currentState = 'Начало инициализации';
  bool _initializationError = false;
  bool _initializationComplete = false;

  void _setStage(String stage) {
    print('INIT: $stage');
    // Schedule UI update only if we're still mounted
    if (mounted) {
      setState(() => _currentState = stage);
    }
  }

  Future<void> _initializeAppComponents() async {
    try {
      _setStage('Начало инициализации');
      await Future.delayed(Duration(seconds: 1));

      _setStage("Инициализация видеокомпонентов");
      // Wrap synchronous operation in future to avoid blocking UI
      await Future.microtask(() => fvp.registerWith());

      // Initialize EndoAi with progress updates
      await Future.microtask(() async => await EndoAi.initialize((stage) {
            if (mounted) {
              setState(() => _currentState = stage);
            }
          }));

      if (mounted) {
        setState(() {
          FeatureInitializer.componentsInitialized = true;
          _initializationComplete = true;
        });
      }
    } catch (e) {
      print('Initialization error: $e');
      if (mounted) {
        setState(() {
          _initializationError = true;
          _currentState = 'Ошибка инициализации: $e';
        });
      }
      rethrow;
    }
  }

  @override
  void initState() {
    super.initState();
    // Start initialization after first frame render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!FeatureInitializer.componentsInitialized) {
        _initializeAppComponents().then((_) {
          if (mounted && _initializationComplete) {
            Navigator.pushReplacementNamed(context, Routes.homePage);
          }
        }).catchError((_) {
          // Error already handled in _initializeAppComponents
        });
      } else {
        Navigator.pushReplacementNamed(context, Routes.homePage);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FlutterLogo(size: 100),
              const SizedBox(height: 40),

              // Progress indicator with error state
              SizedBox(
                width: 60,
                height: 60,
                child: _initializationError
                    ? const Icon(Icons.error_outline,
                        color: Colors.red, size: 40)
                    : const CircularProgressIndicator(strokeWidth: 6),
              ),

              const SizedBox(height: 30),

              // Initialization status text
              Text(
                _currentState,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // Retry button for errors
              if (_initializationError)
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _initializationError = false;
                      _currentState = 'Повторная инициализация...';
                    });
                    _initializeAppComponents().then((_) {
                      if (mounted && _initializationComplete) {
                        Navigator.pushReplacementNamed(
                            context, Routes.homePage);
                      }
                    });
                  },
                  child: const Text("Повторить"),
                )
            ],
          ),
        ),
      ),
    );
  }
}
