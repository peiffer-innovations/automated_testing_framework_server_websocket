import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:automated_testing_framework_models/automated_testing_framework_models.dart';
import 'package:automated_testing_framework_server_websocket/automated_testing_framework_server_websocket.dart';
import 'package:logging/logging.dart';

/// The core of the package.  This creates the websocket server that listens for
/// incoming commands and passes them off to associated handlers, either
/// internal or external.
///
/// The [address] is the address to listen on and defaults to
/// [InternetAddress.anyIPv4].
///
/// This requires an [authenticator] to perform the authentication for the
/// clients.
///
/// The optional [authorizer] allows for authorizing commands against clients.
/// If not set, the default authorizer allows all commands from all clients.
///
/// Custom servers needing specialized commands can pass in command handlers via
/// the [handlers] attribute.
///
/// The optional [onDone] callback allows custom servers the ability to be
/// notified when a socket is closed.
///
/// Finally the [port] parameter provides the application with the ability to
/// specify the port to listen on.
class Server {
  Server({
    InternetAddress? address,
    required Authenticator authenticator,
    Authorizer? authorizer,
    Map<String, CustomServerCommandHandler>? handlers,
    Function(WebSocket? socket)? onDone,
    this.port = 5333,
  })  : address = address ?? InternetAddress.anyIPv4,
        _authenticator = authenticator,
        _authorizer = authorizer ?? AllowAllAutorizer(),
        _customHandlers = handlers ?? {},
        _onDone = onDone;

  static final Logger _logger = Logger('Server');

  final InternetAddress address;
  final Authenticator _authenticator;
  final Authorizer _authorizer;
  final int? port;

  final Map<String, CustomServerCommandHandler> _customHandlers;
  final Function(WebSocket? socket)? _onDone;

  final Map<String, ServerCommandHandler> _handlers = {
    GoodbyeCommand.kCommandType: GoodbyeHandler().handle,
    ListDevicesCommand.kCommandType: ListDevicesHandler().handle,
    ReserveDeviceCommand.kCommandType: ReserveDeviceHandler().handle,
  };

  Future<void> listen() async {
    final server = await HttpServer.bind(
      address,
      port!,
    );
    final sub = ProcessSignal.sigint.watch().listen((event) {
      server.close(force: true);
    });
    try {
      _logger.info('[SERVER]: listening at ${server.address}:${server.port}');

      await for (var req in server) {
        final commandStreamController =
            StreamController<DeviceCommand>.broadcast();
        try {
          _logger.info(
            '[CONNECTION]: connection received -- ${req.headers['host']}',
          );

          WebSocketCommunicator? comm;

          // Upgrade a HttpRequest to a WebSocket connection.
          WebSocket? socket = await WebSocketTransformer.upgrade(req);

          socket.listen(
            (event) {
              DeviceCommand? cmd;

              try {
                cmd = DeviceCommand.fromDynamic(json.decode(event));
              } catch (e, stack) {
                _logger.severe('[COMMAND]: unable to parse command.', e, stack);
              }

              if (cmd == null) {
                _logger.info('[CLOSE]: closing socket due to null command.');
                socket?.close();
                socket = null;
              } else {
                commandStreamController.add(cmd);
              }
            },
            onDone: () {
              commandStreamController.close();
              _logger.info('[CLOSE]: onDone called: [${comm?.toString()}]');

              if (comm is Driver) {
                final driver = comm;
                final inSession = comm.app.sessions.values
                        .where((session) =>
                            driver.driverId == session.driver.driverId)
                        .isNotEmpty ==
                    true;
                if (inSession != true) {
                  _logger.info(
                    '[CLOSE]: no session, driver removed: [${comm.toString()}',
                  );
                  comm.app.drivers.remove(driver.driverId);
                  comm.close();
                }
              }

              if (_onDone != null) {
                _onDone!(socket);
              }
            },
            onError: (e, stack) {
              if (comm is Driver) {
                final driver = comm;
                final inSession = comm.app.sessions.values
                        .where((session) =>
                            driver.driverId == session.driver.driverId)
                        .isNotEmpty ==
                    true;
                if (inSession != true) {
                  driver.app.drivers.remove(driver.driverId);
                  _logger.severe(
                    '[CLOSE]: no session, driver removed: [${driver.toString()}',
                    e,
                    stack,
                  );
                  driver.close();
                }
              }
            },
          );

          if (socket != null) {
            comm = await _authenticator.authenticate(
              commandStream: commandStreamController.stream,
              socket: socket!,
            );
          }

          if (comm == null) {
            throw AuthenticationException(
              '[AUTHENTICATION]: authentication failed',
            );
          }

          if (comm is Driver) {
            final driver = comm;
            final sessions = comm.app.sessions.values.where(
              (session) => session.driver.driverId == driver.driverId,
            );

            if (sessions.isNotEmpty == true) {
              final session = sessions.first;
              session.start();
            } else {
              comm.onCommandReceived = (command) async {
                final handler =
                    _customHandlers[command.type] ?? _handlers[command.type];
                if (handler != null) {
                  await handler(
                    app: driver.app,
                    command: command,
                    comm: comm,
                  );
                }
              };
            }
          } else if (comm is Device) {
            final device = comm;
            final sessions = comm.app.sessions.values.where(
              (session) => session.device.device.id == device.device.id,
            );

            if (sessions.isNotEmpty == true) {
              final session = sessions.first;
              session.start();
            }
          } else {
            comm.onCommandReceived = (command) async {
              final handler =
                  _customHandlers[command.type] ?? _handlers[command.type];
              if (handler != null) {
                await handler(
                  app: comm!.app,
                  command: command,
                  comm: comm,
                );
              }
            };
          }

          commandStreamController.stream.listen(
            (cmd) {
              _authorizer
                  .authorize(
                command: cmd,
                communicator: comm!,
              )
                  .then((authorized) {
                try {
                  if (authorized) {
                    comm!.onCommandReceived(cmd);
                  } else {
                    comm!.sendCommand(
                      CommandAck(
                        commandId: cmd.id,
                        message: 'UNAUTHORIZED',
                        success: false,
                      ),
                    );
                  }
                } catch (e, stack) {
                  _logger.severe('[SERVER]: uncaught error.', e, stack);
                }
              });
            },
          );
        } catch (e, stack) {
          _logger.severe('[SERVER]: uncaught error.', e, stack);
        }
      }
    } finally {
      await sub.cancel();
    }
  }
}
