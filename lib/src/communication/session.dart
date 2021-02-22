import 'package:automated_testing_framework_models/automated_testing_framework_models.dart';
import 'package:automated_testing_framework_server_websocket/automated_testing_framework_server_websocket.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

class Session {
  Session({
    @required this.device,
    @required this.driver,
    @required this.onClose,
  })  : assert(device != null),
        assert(driver != null),
        assert(onClose != null);

  final Device device;
  final Driver driver;
  final String id = Uuid().v4();
  final Future<void> Function() onClose;

  bool _closed = false;
  bool get closed => _closed;

  void close() async {
    if (_closed != true) {
      _closed = true;

      device.close();
      driver.close();

      await onClose();
    }
  }

  void start() {
    device.onCommandReceived = _onDeviceCommand;
    driver.onCommandReceived = _onDriverCommand;
  }

  Future<void> _onDeviceCommand(DeviceCommand command) async {
    if (_closed != true) {
      try {
        await driver.sendCommand(command);

        if (command is ReleaseDeviceCommand) {
          await close();
        } else if (command is GoodbyeCommand) {
          if (command.complete == true) {
            await driver.sendCommand(
              ReleaseDeviceCommand(deviceId: device.device.id),
            );

            await close();
          }
        }
      } catch (e) {
        close();
      }
    }
  }

  Future<void> _onDriverCommand(DeviceCommand command) async {
    if (_closed != true) {
      try {
        await device.sendCommand(command);

        if (command is ReleaseDeviceCommand) {
          await close();
        } else if (command is GoodbyeCommand) {
          if (command.complete == true) {
            await device.sendCommand(
              ReleaseDeviceCommand(deviceId: device.device.id),
            );

            await close();
          }
        }
      } catch (e) {
        close();
      }
    }
  }
}
