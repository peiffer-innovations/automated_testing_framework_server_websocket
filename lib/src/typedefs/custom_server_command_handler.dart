import 'package:automated_testing_framework_models/automated_testing_framework_models.dart';
import 'package:automated_testing_framework_server_websocket/automated_testing_framework_server_websocket.dart';

typedef CustomServerCommandHandler = Future<void> Function({
  required Application? app,
  required DeviceCommand command,
  required WebSocketCommunicator? comm,
});
