import 'dart:io';

import 'package:automated_testing_framework_models/automated_testing_framework_models.dart';
import 'package:automated_testing_framework_server_websocket/automated_testing_framework_server_websocket.dart';
import 'package:logging/logging.dart';

/// Abstract class to provide authentication against incoming connections.  The
/// authenticator is responsible for determining what type of
/// [WebSocketCommunicator] the incoming socket represenst, if any.
///
/// See also:
///  * [Device]
///  * [Driver]
abstract class Authenticator {
  Authenticator({
    Logger? logger,
  }) : logger = logger ?? Logger('Authenticator');

  final Logger logger;

  /// Authenticates the current communicator.  The [Future] will resolve with
  /// a valid [WebSocketCommunicator] if the authentication is successful and
  /// `null` otherwise.
  Future<WebSocketCommunicator?> authenticate({
    required Stream<DeviceCommand> commandStream,
    required WebSocket socket,
  });
}
