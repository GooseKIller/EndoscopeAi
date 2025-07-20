import 'package:web_socket_channel/web_socket_channel.dart';

class VoiceControl {
  WebSocketChannel? _channel;
  final void Function(String) onCommand;
  final void Function(String) onError;
  bool _isConnected = false;
  bool _isDisposed = false;

  VoiceControl({
    required this.onCommand,
    required this.onError,
  }) {
    _init();
  }

  void _init() async {
    await _connect();
    _startReconnectTimer();
  }

  Future<void> _connect() async {
    if (_isDisposed) return;
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('ws://localhost:8765'),
      );

      _channel!.stream.listen(
        (data) {
          print("Raw WebSocket data: $data");
          _handleMessage(data.toString());
        },
        onError: (error) {
          print("WebSocket error: $error");
          _isConnected = false;
          onError(error.toString());
        },
        onDone: () {
          print("WebSocket disconnected");
          _isConnected = false;
        },
      );

      _isConnected = true;
      print("WebSocket connected successfully");
    } catch (e) {
      print("Connection failed: $e");
      _isConnected = false;
      onError('Connection failed: $e');
    }
  }

  void _startReconnectTimer() {
    if (_isDisposed) return;

    Future.delayed(Duration(seconds: 5), () {
      if (!_isConnected) {
        print("Attempting to reconnect...");
        _connect();
      }

      _startReconnectTimer();
    });
  }

  void _handleMessage(String text) {
    print("Processing message: $text");
    text = text.toLowerCase();

    final commands = {
      'начать': 'start_recording',
      'стоп': 'stop_recording',
      'остановить запись': 'stop_recording',
      'сделать снимок': 'take_photo',
      'точка': 'take_photo',
    };

    for (final entry in commands.entries) {
      if (text.contains(entry.key)) {
        print("Command detected: ${entry.value}");
        onCommand(entry.value);
        return;
      }
    }

    print("No valid command found in: $text");
  }

  void connect() {
    if (_isDisposed) return;
    print("Connecting to WebSocket...");
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('ws://localhost:8765'),
      );

      print("WebSocket connected. Listening...");

      _channel?.stream.listen(
        (data) {
          print("Received raw data: $data");
          _handleMessage(data as String);
        },
        onError: (error) {
          print("WebSocket error: $error");
          onError(error.toString());
        },
        onDone: () {
          print("WebSocket connection closed");
          onError('Connection closed');
        },
      );
    } catch (e) {
      print("Connection error: $e");
      onError('Connection error: $e');
    }
  }

  void dispose() {
    _channel?.sink.close();
    _isConnected = false;
    _isDisposed = true;
  }
}
