import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:automated_testing_framework_models/automated_testing_framework_models.dart';
import 'package:automated_testing_framework_server_websocket/automated_testing_framework_server_websocket.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

class Server {
  Server({
    InternetAddress address,
    Map<String, CustomServerCommandHandler> handlers,
    String deviceSecret,
    String driverSecret,
    Function(WebSocket socket) onDone,
    this.port = 5333,
  })  : address = address ?? InternetAddress.anyIPv4,
        _customHandlers = handlers ?? {},
        _deviceSecret = deviceSecret ??
            Platform.environment['ATF_DEVICE_SECRET'] ??
            Uuid().v4(),
        _driverSecret = driverSecret ??
            Platform.environment['ATF_DRIVER_SECRET'] ??
            Uuid().v4(),
        _onDone = onDone;

  static final Logger _logger = Logger('Server');

  final InternetAddress address;
  final int port;

  final Map<String, Application> _applications = {};
  final Map<String, CustomServerCommandHandler> _customHandlers;
  final String _deviceSecret;
  final String _driverSecret;
  final Function(WebSocket socket) _onDone;

  final Map<String, ServerCommandHandler> _handlers = {
    GoodbyeCommand.kCommandType: GoodbyeHandler().handle,
    ListDevicesCommand.kCommandType: ListDevicesHandler().handle,
    ReserveDeviceCommand.kCommandType: ReserveDeviceHandler().handle,
  };

  Future<void> listen() async {
    var server = await HttpServer.bind(
      address,
      port,
    );
    _logger.info('[SERVER]: listening at ${server.address}:${server.port}');

    await for (var req in server) {
      await runZonedGuarded(() async {
        _logger.info(
          '[CONNECTION]: connection received -- ${req.headers['host']}',
        );

        // Upgrade a HttpRequest to a WebSocket connection.
        var socket = await WebSocketTransformer.upgrade(req);
        var timer = Timer(Duration(minutes: 2), () async {
          try {
            _logger.info(
              '[CONNECTION]: connection timed out -- ${req.connectionInfo.remoteAddress}',
            );
            await socket?.close();
            socket = null;
          } catch (e) {
            // no-op
          }
        });

        Application app;
        WebSocketCommunicator comm;
        var challenge = ChallengeCommand(
          salt: DriverSignatureHelper().createSalt(),
        );
        Session session;

        socket.listen(
          (event) {
            DeviceCommand cmd;

            try {
              cmd = DeviceCommand.fromDynamic(json.decode(event));
            } catch (e, stack) {
              _logger.severe('[COMMAND]: unable to parse command.', e, stack);
            }

            if (cmd == null) {
              socket.close();
            } else {
              var customHandler = _customHandlers[cmd.type];
              if (customHandler != null) {
                customHandler(
                  command: cmd,
                  communicator: comm,
                  onUpgradeCommunicator: (communicator) {
                    comm = communicator;
                    _logger.info(
                        '[CUSTOM]: received upgrade request to [${communicator.runtimeType}]');
                  },
                  server: this,
                  socket: socket,
                );
                if (comm != null) {
                  timer?.cancel();
                  timer = null;
                }
              } else if (comm == null) {
                if (cmd is AnnounceDeviceCommand) {
                  timer?.cancel();
                  timer = null;

                  respondToChallenge(
                    commandId: cmd.id,
                    salt: cmd.salt,
                    secret: _deviceSecret,
                    socket: socket,
                    timestamp: cmd.timestamp,
                  );

                  app = _getApplication(cmd.appIdentifier);
                  challenge = ChallengeCommand(
                    salt: DriverSignatureHelper().createSalt(),
                  );
                  socket.add(challenge.toString());
                  comm = _getDevice(app, cmd.device, cmd.testControllerState);
                  _logger.info(
                    '[DEVICE]: received announcement: [${cmd.device.id}]',
                  );
                } else if (cmd is AnnounceDriverCommand) {
                  timer?.cancel();
                  timer = null;

                  respondToChallenge(
                    commandId: cmd.id,
                    salt: cmd.salt,
                    secret: _driverSecret,
                    socket: socket,
                    timestamp: cmd.timestamp,
                  );

                  app = _getApplication(cmd.appIdentifier);
                  var driver = _getDriver(app, cmd.driverId, cmd.driverName);
                  challenge = ChallengeCommand(
                    salt: DriverSignatureHelper().createSalt(),
                  );
                  socket.add(challenge.toString());
                  comm = driver;
                  _logger.info(
                    '[DRIVER]: received announcement: [${cmd.driverId}] -- [${cmd.driverName}]',
                  );
                } else {
                  _logger.info(
                    '[UNKNOWN]: unknown command, closing socket!',
                  );
                  // unknown command
                  socket.close();
                }
              } else {
                if (cmd is ChallengeResponseCommand) {
                  if ((DateTime.now().millisecondsSinceEpoch -
                              challenge.timestamp.millisecondsSinceEpoch)
                          .abs() >
                      300000) {
                    // more than 5 minutes on either side of the clock, go away.
                    socket.close();
                  } else {
                    if (DriverSignatureHelper().createSignature(
                            comm is Device ? _deviceSecret : _driverSecret, [
                          challenge.salt,
                          challenge.timestamp.millisecondsSinceEpoch.toString(),
                        ]) ==
                        cmd.signature) {
                      comm.attachSocket(socket);

                      if (comm is Driver) {
                        comm.onCommandReceived = (command) async {
                          var handler = _handlers[command.type];
                          if (handler != null) {
                            await handler(
                              app: app,
                              command: command,
                              comm: comm,
                            );
                          }
                        };
                      }
                    } else {
                      _logger.info(
                        '[CHALLENGE]: challenge response has invalid signature',
                      );
                      socket.close();
                    }
                  }
                } else {
                  comm.onCommandReceived(cmd);
                }
              }
            }
          },
          onDone: () {
            if (comm is Driver && session == null) {
              app.drivers.remove((comm as Driver).driverId);
              comm?.close();
            }

            if (_onDone != null) {
              _onDone(socket);
            }
          },
          onError: (e, stack) {
            if (comm is Driver && session == null) {
              app.drivers.remove((comm as Driver).driverId);
              comm?.close();
            }
          },
        );
      }, (e, stack) {
        // no-op, ignore.  Just don't kill the server because of it.
      });
    }
  }

  void respondToChallenge({
    @required String commandId,
    @required String salt,
    @required String secret,
    @required WebSocket socket,
    @required DateTime timestamp,
  }) {
    if ((DateTime.now().millisecondsSinceEpoch -
                timestamp.millisecondsSinceEpoch)
            .abs() >=
        300000) {
      throw Exception('[EXPIRED]: received expired challenge');
    }

    socket.add(
      ChallengeResponseCommand(
        commandId: commandId,
        signature: DriverSignatureHelper().createSignature(
          secret,
          [
            salt,
            timestamp.millisecondsSinceEpoch.toString(),
          ],
        ),
      ).toString(),
    );
  }

  Application _getApplication(String appIdentifier) {
    var app = _applications[appIdentifier];
    if (app == null) {
      app = Application(appIdentifier: appIdentifier);
      _applications[appIdentifier] = app;
    }

    return app;
  }

  Device _getDevice(
    Application app,
    TestDeviceInfo testDevice,
    TestControllerState testControllerState,
  ) {
    var result = app.devices[testDevice.id];

    if (result == null) {
      result = Device(
        appIdentifier: app.appIdentifier,
        device: testDevice,
        testControllerState: testControllerState,
      );
      app.devices[testDevice.id] = result;
    }
    result.testControllerState = testControllerState;

    return result;
  }

  Driver _getDriver(
    Application app,
    String driverId,
    String driverName,
  ) {
    var result = app.drivers[driverId];

    if (result == null) {
      result = Driver(
        appIdentifier: app.appIdentifier,
        driverId: driverId,
        driverName: driverName,
      );
      app.drivers[driverId] = result;
    }

    return result;
  }
}
