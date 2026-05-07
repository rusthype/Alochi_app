import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../storage/storage.dart';

enum WsStatus { disconnected, connecting, connected, unavailable }

class WsClient {
  static WsClient? _instance;
  static WsClient get instance => _instance ??= WsClient._();

  WsClient._();

  WebSocket? _socket;
  WsStatus _status = WsStatus.disconnected;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  final _statusController = StreamController<WsStatus>.broadcast();

  Stream<Map<String, dynamic>> get stream => _controller.stream;
  Stream<WsStatus> get statusStream => _statusController.stream;
  WsStatus get status => _status;

  bool get isConnected => _status == WsStatus.connected;

  Future<void> connect(String url) async {
    if (_status == WsStatus.connected || _status == WsStatus.connecting) {
      return;
    }
    if (_status == WsStatus.unavailable) {
      // Endpoint not available — skip silently
      return;
    }

    _setStatus(WsStatus.connecting);

    try {
      final token = await AppStorage.getAccessToken();
      final wsUrl = '$url?token=$token';
      debugPrint('WS: Connecting to $wsUrl');

      _socket = await WebSocket.connect(wsUrl).timeout(
        const Duration(seconds: 8),
      );

      _setStatus(WsStatus.connected);
      debugPrint('WS: Connected');

      _socket!.listen(
        (data) {
          try {
            final decoded = jsonDecode(data.toString());
            _controller.add(decoded as Map<String, dynamic>);
          } catch (e) {
            debugPrint('WS decode error: $e');
          }
        },
        onDone: () {
          debugPrint('WS: Connection closed');
          _socket = null;
          _setStatus(WsStatus.disconnected);
          // Retry after 5s if not manually disconnected
          Future.delayed(const Duration(seconds: 5), () {
            if (_status == WsStatus.disconnected) {
              connect(url);
            }
          });
        },
        onError: (e) {
          debugPrint('WS error: $e');
          _socket = null;
          _setStatus(WsStatus.disconnected);
        },
        cancelOnError: true,
      );
    } on SocketException catch (e) {
      debugPrint('WS SocketException (endpoint unavailable): $e');
      _socket = null;
      // Mark as unavailable so we don't keep retrying
      _setStatus(WsStatus.unavailable);
    } on TimeoutException catch (e) {
      debugPrint('WS timeout: $e');
      _socket = null;
      _setStatus(WsStatus.unavailable);
    } catch (e) {
      debugPrint('WS connect error: $e');
      _socket = null;
      // 404 / other errors = endpoint not available
      if (e.toString().contains('404') ||
          e.toString().contains('not found') ||
          e.toString().contains('handshake')) {
        _setStatus(WsStatus.unavailable);
      } else {
        _setStatus(WsStatus.disconnected);
      }
    }
  }

  void send(Map<String, dynamic> data) {
    if (!isConnected) return;
    try {
      _socket?.add(jsonEncode(data));
    } catch (e) {
      debugPrint('WS send error: $e');
    }
  }

  Future<void> disconnect() async {
    _setStatus(WsStatus.disconnected);
    await _socket?.close();
    _socket = null;
  }

  void _setStatus(WsStatus s) {
    _status = s;
    _statusController.add(s);
  }
}
