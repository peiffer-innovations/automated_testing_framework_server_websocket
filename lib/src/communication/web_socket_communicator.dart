import 'dart:async';
import 'dart:io';

import 'package:automated_testing_framework_models/automated_testing_framework_models.dart';
import 'package:automated_testing_framework_server_websocket/automated_testing_framework_server_websocket.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

abstract class WebSocketCommunicator {
  WebSocketCommunicator({
    @required this.logger,
    this.sendTimeout = const Duration(minutes: 1),
    this.timeout = const Duration(minutes: 2),
  }) : assert(logger != null);

  final Logger logger;
  final Duration sendTimeout;
  final Duration timeout;

  DateTime _lastPing = DateTime.now();
  Future<void> Function(DeviceCommand) _onCommandReceived;
  WebSocket _socket;
  Timer _timeoutTimer;

  DateTime get lastPing => _lastPing;
  bool get online => _socket?.readyState == WebSocket.open;

  set onCommandReceived(Future<void> Function(DeviceCommand) handler) =>
      _onCommandReceived = handler;

  Future<void> Function(DeviceCommand) get onCommandReceived =>
      (command) async {
        _lastPing = DateTime.now();
        _resetTimeout();

        if (_onCommandReceived != null) {
          if (command is! CommandAck) {
            logger.info('[RECEIVED COMMAND]: received: [${command.type}]');
          }
          await _onCommandReceived(command);
        }
      };

  void attachSocket(WebSocket socket) {
    logger.info('[SOCKET]: attached');
    _socket = socket;
    _lastPing = DateTime.now();

    _resetTimeout();
  }

  void close() {
    if (_socket != null) {
      logger.info('[SOCKET]: closed');
      try {
        if (_socket.readyState == WebSocket.open) {
          _socket.add(GoodbyeCommand(complete: true).toString());
        }
      } catch (e) {
        // no-op
      }
    }

    _timeoutTimer?.cancel();
    _timeoutTimer = null;

    _socket?.close();
    _socket = null;
  }

  Future<void> sendCommand(DeviceCommand command) async {
    var startTime = DateTime.now();
    while (_socket?.readyState != WebSocket.open) {
      await Future.delayed(Duration(milliseconds: 100));

      if (DateTime.now().millisecondsSinceEpoch -
              startTime.millisecondsSinceEpoch >
          sendTimeout.inMilliseconds) {
        logger.info(
          '[SEND COMMAND]: timeout attempting to send command: [${command.type}]',
        );
        throw Exception('Timeout');
      }
    }

    _socket.add(command.toString());
    logger.info('[SEND COMMAND]: sent: [${command.type}]');
  }

  void _resetTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;

    var pingTimeout = ServerConfiguration().pingTimeout;
    _timeoutTimer = Timer(pingTimeout, () => close());
  }
}
