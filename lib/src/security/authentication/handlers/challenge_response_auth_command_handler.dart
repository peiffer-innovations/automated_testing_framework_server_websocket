import 'package:automated_testing_framework_models/automated_testing_framework_models.dart';
import 'package:automated_testing_framework_server_websocket/automated_testing_framework_server_websocket.dart';
import 'package:logging/logging.dart';

class ChallengeResponseAuthCommandHandler extends AuthenticationCommandHandler {
  ChallengeResponseAuthCommandHandler(this._secrets)
      : super(logger: Logger('ChallengeResponseAuthCommandHandler'));

  /// The mapping of handlers to the appropriate secret key that it requires.
  /// The key for the map is the runtime type of the [WebSocketCommunicator]
  /// that the key is needed for.
  final Map<Type, String> _secrets;

  @override
  Future<void> handle({
    required DeviceCommand command,
    required AuthenticationState state,
  }) async {
    var cmd = command as ChallengeResponseCommand;

    var secret = _secrets[state.communicator!.runtimeType];

    var valid = secret == null
        ? false
        : validateChallengeResponse(
            challenge: state.challenge!,
            command: cmd,
            secret: secret,
          );

    state.success = valid;
  }
}
