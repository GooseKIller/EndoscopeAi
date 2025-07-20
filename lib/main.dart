import 'package:endoscopy_ai/features/storage_system/storage_system.dart';
import 'package:flutter/material.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // еще какаято инициализация
  await StorageSystem.initialize();

  runApp(const App());
}
