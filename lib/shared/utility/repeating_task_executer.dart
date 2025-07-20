// ====================================================
//  Класс, который выполняет задачу с определенной периодичностью,
//  может быть остановлен или запущен заново
// ====================================================

import 'dart:async';

class RepeatingTaskExecuter {
  final Duration refreshTime;
  final Future<void> Function() task;
  bool _isRunning = false;
  bool _disposed = false;
  Future<void>? _runner = null;

  bool get isRunning => _isRunning && !_disposed;
  set isRunning(bool value) => _isRunning = value;

  RepeatingTaskExecuter({required this.refreshTime, required this.task});

  // начать работу
  void start() {
    if (_runner != null) return;

    _runner = _runTask();
    _isRunning = true;
  }

  // завершить работу
  void dispose() {
    if (_disposed) return;

    _isRunning = false;
    _disposed = true;
  }

  Future<void> _runTask() async {
    while (!_disposed) {
      final beginTime = DateTime.now();

      if (isRunning) await task();

      final endTime = DateTime.now();
      final elapsed = endTime.difference(beginTime);

      print('RepeatingTaskExecuter tick completed at $elapsed sec');
      if (elapsed < refreshTime) {
        await Future.delayed(refreshTime - elapsed);
      }
    }

    _runner = null;
  }
}
