import 'dart:io';

import 'package:automated_testing_framework_models/automated_testing_framework_models.dart';
import 'package:automated_testing_framework_server_websocket/automated_testing_framework_server_websocket.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

abstract class AuthenticationCommandHandler {
  AuthenticationCommandHandler({
    Logger? logger,
  }) : logger = logger ?? Logger('AuthenticationCommandHandler');

  static final Map<String, Application> _applications = {};

  final Logger logger;

  Future<void> handle({
    required DeviceCommand command,
    required AuthenticationState state,
  });

  @protected
  Application getApplication(String appIdentifier) {
    var app = _applications[appIdentifier];
    if (app == null) {
      app = Application(appIdentifier: appIdentifier);
      _applications[appIdentifier] = app;
    }

    return app;
  }

  /// Helper function to get a [Device] from the cache based on the
  /// [deviceInfo].  A [Device] will exist in the cache in the event it was
  /// previously connected and now attempting to reconnect.
  @protected
  Device getDevice({
    required Application app,
    required TestDeviceInfo deviceInfo,
    required TestControllerState testControllerState,
  }) {
    var result = app.devices[deviceInfo.id];

    if (result == null) {
      result = Device(
        app: app,
        appIdentifier: app.appIdentifier,
        device: deviceInfo,
        testControllerState: testControllerState,
      );
      app.devices[deviceInfo.id] = result;
    }
    result.testControllerState = testControllerState;

    return result;
  }

  /// Helper function to get a [Driver] from the cache based on the
  /// [driverId].  A [Driver] will exist in the cache in the event it was
  /// previously connected and now attempting to reconnect.
  ///
  /// The [driverName] is only used if this is a new connection from the
  /// [Driver] as opposed to a reconnection.
  @protected
  Driver getDriver({
    required Application app,
    required String driverId,
    required String driverName,
  }) {
    var result = app.drivers[driverId];

    if (result == null) {
      result = Driver(
        app: app,
        appIdentifier: app.appIdentifier,
        driverId: driverId,
        driverName: driverName,
      );
      app.drivers[driverId] = result;
    } else {
      logger.info('[REATTACHING DRIVER]: $driverId');
    }

    return result;
  }

  /// Helper function to respond to a challenge request.  This will create and
  /// send the appropriate [ChallengeResponseCommand] to the [socket].
  @protected
  void respondToChallenge({
    required String commandId,
    required String salt,
    required String secret,
    required WebSocket socket,
    required DateTime timestamp,
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

  @protected
  bool validateChallengeResponse({
    required ChallengeCommand challenge,
    required DeviceCommand command,
    required String secret,
  }) {
    var result = false;
    if (command is ChallengeResponseCommand) {
      if (command.commandId == challenge.id) {
        if ((DateTime.now().millisecondsSinceEpoch -
                    challenge.timestamp.millisecondsSinceEpoch)
                .abs() >
            300000) {
          // more than 5 minutes on either side of the clock, go away.
          logger.info(
            '[AUTHENTICATE]: rejecting due to expired challenge response.',
          );
        } else {
          final signature = DriverSignatureHelper().createSignature(
            secret,
            [
              challenge.salt,
              challenge.timestamp.millisecondsSinceEpoch.toString(),
            ],
          );
          if (signature == command.signature) {
            result = true;
          } else {
            logger.info(
              '[CHALLENGE]: challenge response has invalid signature',
            );
          }
        }
      }
    }

    return result;
  }
}
