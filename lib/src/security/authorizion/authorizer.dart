import 'package:automated_testing_framework_models/automated_testing_framework_models.dart';
import 'package:automated_testing_framework_server_websocket/automated_testing_framework_server_websocket.dart';
import 'package:logging/logging.dart';

/// Class that authorizes commands sent from a [WebSocketCommunicator].
abstract class Authorizer {
  Authorizer({
    Logger? logger,
  }) : logger = logger ?? Logger('Authorizer');

  final Logger logger;

  /// Authorizes the given [command] sent in from the [communicator].  This must
  /// resolve the [Future] with [true] if the [communicator] is authorized to
  /// send / request the [command] and [false] otherwise.
  Future<bool> authorize({
    required DeviceCommand command,
    required WebSocketCommunicator communicator,
  });
}
