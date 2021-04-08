import 'package:automated_testing_framework_models/automated_testing_framework_models.dart';
import 'package:automated_testing_framework_server_websocket/automated_testing_framework_server_websocket.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

class Session {
  Session({
    required this.device,
    required this.driver,
    Logger? logger,
    required this.onClose,
  }) : _logger = logger ??
            Logger(
              'Session - [${device.device.id}] [${driver.driverName}]',
            ) {
    _logger.info('[SESSION]: opened');
  }

  final Device device;
  final Driver driver;
  final String id = Uuid().v4();
  final Future<void> Function() onClose;

  final Logger _logger;

  bool _closed = false;
  bool get closed => _closed;

  void close() async {
    if (_closed != true) {
      _logger.info('[SESSION]: closed');
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
        if (command is! PingCommand && command is! GoodbyeCommand) {
          await driver.sendCommand(command);
        }

        if (command is ReleaseDeviceCommand) {
          _logger.info('[COMMAND]: device self released');
          close();
        } else if (command is GoodbyeCommand) {
          _logger.info(
            '[COMMAND]: device goodbye received -- [${command.complete}]',
          );
          if (command.complete == true) {
            await driver.sendCommand(
              ReleaseDeviceCommand(deviceId: device.device.id),
            );

            close();
          }
        }
      } catch (e, stack) {
        _logger.severe('[ERROR]: device error receiving command', e, stack);
        close();
      }
    }
  }

  Future<void> _onDriverCommand(DeviceCommand command) async {
    if (_closed != true) {
      try {
        if (command is! PingCommand && command is! GoodbyeCommand) {
          await device.sendCommand(command);
        } else if (command is ReleaseDeviceCommand) {
          _logger.info('[COMMAND]: driver released device');
          close();
        } else if (command is GoodbyeCommand) {
          _logger.info(
            '[COMMAND]: driver goodbye received -- [${command.complete}]',
          );
          if (command.complete == true) {
            await device.sendCommand(
              ReleaseDeviceCommand(deviceId: device.device.id),
            );

            close();
          }
        }
      } catch (e, stack) {
        _logger.severe('[ERROR]: driver error receiving command', e, stack);
        close();
      }
    }
  }
}
