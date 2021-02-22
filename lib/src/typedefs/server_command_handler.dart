import 'package:automated_testing_framework_models/automated_testing_framework_models.dart';
import 'package:automated_testing_framework_server_websocket/automated_testing_framework_server_websocket.dart';

typedef ServerCommandHandler = Future<void> Function({
  Application app,
  DeviceCommand command,
  WebSocketCommunicator comm,
});
