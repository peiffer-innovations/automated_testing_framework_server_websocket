import 'dart:async';

import 'package:automated_testing_framework_models/automated_testing_framework_models.dart';
import 'package:automated_testing_framework_server_websocket/automated_testing_framework_server_websocket.dart';

class ReserveDeviceHandler {
  Future<void> handle({
    Application? app,
    DeviceCommand? command,
    WebSocketCommunicator? comm,
  }) async {
    if (command is ReserveDeviceCommand) {
      if (comm is Driver) {
        var device = app!.devices[command.deviceId];

        var deviceReserved = app.sessions.values
                .where(
                    (session) => session.device.device.id == command.deviceId)
                .isNotEmpty ==
            true;

        if (deviceReserved == true || device == null) {
          await comm.sendCommand(CommandAck(
            commandId: command.id,
            message: '[RESERVATION FAILED]: device already reserved',
            success: false,
          ));
        } else {
          comm.logger.info(
            '[RESERVE DEVICE]: sending reservation request to device for [${command.driverName}]',
          );

          var completer = Completer();
          Timer? timer = Timer(
            ServerConfiguration().reservationTimeout,
            () => completer
                .completeError('[TIMEOUT]: reservation request timed out'),
          );
          var onCmd = device.onCommandReceived;
          device.onCommandReceived = (cmd) async {
            if (cmd is CommandAck && cmd.commandId == command.id) {
              comm.onCommandReceived = onCmd;
              if (cmd.success == true) {
                late Session session;
                session = Session(
                  device: device,
                  driver: comm,
                  onClose: () async {
                    comm.close();

                    app.sessions.remove(session.id);
                    app.devices.remove(device.device.id);
                    app.drivers.remove(comm.driverId);
                  },
                );

                session.start();
                app.sessions[session.id] = session;
                timer?.cancel();
                timer = null;
                completer.complete();

                await comm.sendCommand(cmd);
              } else {
                throw Exception('Device rejected reservation');
              }
            }
          };

          try {
            await Future.wait([
              completer.future,
              device.sendCommand(command),
            ]);
          } catch (e, stack) {
            comm.logger.severe(
              '[RESERVATION FAILED]: [${command.driverName}]',
              e,
              stack,
            );
            device.onCommandReceived = onCmd;
            await comm.sendCommand(CommandAck(
              commandId: command.id,
              message: '[RESERVATION FAILED]: $e',
              success: false,
            ));
          }
        }
      }
    }
  }
}
