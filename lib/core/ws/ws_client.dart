import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../storage/storage.dart';

class WsClient {
  static WsClient? _instance;
  static WsClient get instance => _instance ??= WsClient._();

  WsClient._();

  WebSocket? _socket;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get stream => _controller.stream;

  bool get isConnected => _socket != null && _socket!.readyState == WebSocket.open;

  Future<void> connect(String url) async {
    if (_socket != null && _socket!.readyState == WebSocket.open) return;
    
    try {
      final token = await AppStorage.getAccessToken();
      // Most Django Channels setups expect token in query params or headers
      // Since WebSocket.connect in dart:io doesn't easily support headers for all platforms,
      // we'll try query param first.
      final wsUrl = '$url?token=$token';
      
      debugPrint('Connecting to WS: $wsUrl');
      _socket = await WebSocket.connect(wsUrl).timeout(const Duration(seconds: 10));
      
      _socket!.listen(
        (data) {
          try {
            final decoded = jsonDecode(data.toString());
            _controller.add(decoded as Map<String, dynamic>);
          } catch (e) {
            debugPrint('WS Decode error: $e');
          }
        },
        onDone: () {
          debugPrint('WS Connection closed');
          _socket = null;
          // Auto-reconnect
          _reconnect(url);
        },
        onError: (e) {
          debugPrint('WS Error: $e');
          _socket = null;
          _reconnect(url);
        },
      );
      debugPrint('WS Connected successfully');
    } catch (e) {
      debugPrint('WS Connection error: $e');
      _reconnect(url);
    }
  }

  void _reconnect(String url) {
    Future.delayed(const Duration(seconds: 5), () {
      if (_socket == null) connect(url);
    });
  }

  void send(Map<String, dynamic> data) {
    if (_socket != null && _socket!.readyState == WebSocket.open) {
      _socket!.add(jsonEncode(data));
    } else {
      debugPrint('WS: Cannot send, socket not connected');
    }
  }

  void disconnect() {
    _socket?.close();
    _socket = null;
  }
}
