import 'package:endoscopy_ai/src/rust/frb_generated.dart';
import 'package:flutter/material.dart';
import 'package:fvp/fvp.dart' as fvp;

import 'app.dart';

void main() async {
  fvp.registerWith(); // инициаллизация fvp
  WidgetsFlutterBinding.ensureInitialized(); // еще какаято инициализация
  await RustLib.init();

  runApp(const App());
}
