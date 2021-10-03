import 'dart:async';
import 'dart:io';

import 'package:automated_testing_framework_models/automated_testing_framework_models.dart';
import 'package:automated_testing_framework_server_websocket/automated_testing_framework_server_websocket.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

abstract class WebSocketCommunicator {
  WebSocketCommunicator({
    required this.app,
    required this.logger,
    this.params = const {},
    this.sendTimeout = const Duration(minutes: 2),
    this.timeout = const Duration(minutes: 5),
  });

  final Application app;
  final Logger logger;
  final Map<String, dynamic> params;
  final Duration sendTimeout;
  final Duration timeout;

  bool _connected = false;
  DateTime _lastPing = DateTime.now();
  Future<void> Function(DeviceCommand)? _onCommandReceived;
  WebSocket? _socket;
  Timer? _timeoutTimer;

  DateTime get lastPing => _lastPing;
  bool get online => _socket?.readyState == WebSocket.open;

  set onCommandReceived(Future<void> Function(DeviceCommand) handler) {
    if (handler == onCommandReceived) {
      throw Exception(
        '[LOOP]: Attempted to register the same handler as [onCommandReceived]; aborting',
      );
    }
    _onCommandReceived = handler;
  }

  Future<void> Function(DeviceCommand) get onCommandReceived =>
      (command) async {
        _lastPing = DateTime.now();
        _resetTimeout();

        if (_onCommandReceived != null) {
          if (command is CommandAck || command is PingCommand) {
            logger.finest('[RECEIVED COMMAND]: received: [${command.type}]');
          } else {
            logger.info('[RECEIVED COMMAND]: received: [${command.type}]');
          }

          await _onCommandReceived!(command);
        }
      };

  void attachSocket(WebSocket? socket) {
    if (_connected == true) {
      logger.info('[SOCKET]: reattached');
    } else {
      logger.info('[SOCKET]: attached');
    }
    _connected = true;
    _socket = socket;
    _lastPing = DateTime.now();

    _resetTimeout();
  }

  @mustCallSuper
  void close() {
    if (_socket != null) {
      logger.info('[SOCKET]: closed');

      _timeoutTimer?.cancel();
      _timeoutTimer = null;

      _socket?.close();
      _socket = null;
    }
  }

  Future<void> sendCommand(DeviceCommand command) async {
    var startTime = DateTime.now().millisecondsSinceEpoch;
    var timeout = sendTimeout.inMilliseconds;
    logger.finest(
      '[SEND COMMAND]: attempting to send command: [${command.type}]',
    );
    if (command is! GoodbyeCommand) {
      while (_socket?.readyState != WebSocket.open) {
        await Future.delayed(Duration(seconds: 1));

        var waitedTime = DateTime.now().millisecondsSinceEpoch - startTime;

        if (waitedTime > timeout) {
          logger.warning(
            '[SEND COMMAND]: timeout attempting to send command: [${command.type}] -- [$waitedTime]',
          );
          throw Exception('Timeout');
        }
      }
    }

    if (_socket?.readyState == WebSocket.open) {
      _socket!.add(command.toString());
      if (command is CommandAck || command is PingCommand) {
        logger.finest('[SEND COMMAND]: sent: [${command.type}]');
      } else {
        logger.fine('[SEND COMMAND]: sent: [${command.type}]');
      }
    }
  }

  void _resetTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;

    var pingTimeout = timeout;
    _timeoutTimer = Timer(pingTimeout, () {
      logger.info('[CLOSED]: closed by lack of ping.');
      close();
    });
  }
}
