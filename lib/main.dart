import 'package:flutter/material.dart';
import 'package:fvp/fvp.dart' as fvp;
import 'package:endoscopy_ai/features/ai/endo_ai.dart';

import 'app.dart';

void main() async {
  fvp.registerWith(); // инициаллизация fvp
  WidgetsFlutterBinding.ensureInitialized(); // еще какаято инициализация
  await EndoAi.initialize();

  runApp(const App());
}
