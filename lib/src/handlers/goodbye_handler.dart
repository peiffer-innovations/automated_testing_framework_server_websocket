import 'package:automated_testing_framework_models/automated_testing_framework_models.dart';
import 'package:automated_testing_framework_server_websocket/automated_testing_framework_server_websocket.dart';

class GoodbyeHandler {
  Future<void> handle({
    Application? app,
    DeviceCommand? command,
    WebSocketCommunicator? comm,
  }) async {
    if (command is GoodbyeCommand) {
      comm!.close();

      if (command.complete == true) {
        app!.devices.removeWhere((_, value) => value == comm);
        app.drivers.removeWhere((_, value) => value == comm);

        app.sessions.removeWhere((_, session) {
          var result = false;

          if (session.device == comm || session.driver == comm) {
            result = true;
            session.close();
          }

          return result;
        });
      }
    }
  }
}
