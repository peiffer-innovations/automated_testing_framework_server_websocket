import 'package:automated_testing_framework_models/automated_testing_framework_models.dart';
import 'package:automated_testing_framework_server_websocket/automated_testing_framework_server_websocket.dart';

class ListDevicesHandler {
  Future<void> handle({
    Application? app,
    DeviceCommand? command,
    WebSocketCommunicator? comm,
  }) async {
    if (command is ListDevicesCommand) {
      var devices = app!.devices.values
          .where((device) =>
              device.online == true &&
              (device.driverName == null || command.availableOnly != true))
          .toList();
      devices.sort();

      var reply = CommandAck(
        commandId: command.id,
        response: ListDevicesResponse(
          devices: devices
              .map(
                (device) => device.toConnectedDevice(),
              )
              .toList(),
        ),
      );

      await comm!.sendCommand(reply);
    }
  }
}
