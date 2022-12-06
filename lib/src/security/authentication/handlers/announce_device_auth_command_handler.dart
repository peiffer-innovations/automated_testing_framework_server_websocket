import 'package:automated_testing_framework_models/automated_testing_framework_models.dart';
import 'package:automated_testing_framework_server_websocket/automated_testing_framework_server_websocket.dart';
import 'package:logging/logging.dart';

class AnnounceDeviceAuthCommandHandler extends AuthenticationCommandHandler {
  AnnounceDeviceAuthCommandHandler(this._secret)
      : super(logger: Logger('AnnounceDeviceAuthCommandHandler'));

  final String _secret;

  @override
  Future<void> handle({
    required DeviceCommand command,
    required AuthenticationState state,
  }) async {
    final cmd = command as AnnounceDeviceCommand;

    respondToChallenge(
      commandId: cmd.id,
      salt: cmd.salt,
      secret: _secret,
      socket: state.socket,
      timestamp: cmd.timestamp,
    );

    final app = getApplication(command.appIdentifier);
    final device = getDevice(
      app: app,
      deviceInfo: cmd.device,
      testControllerState: cmd.testControllerState,
    );

    final challenge = ChallengeCommand(
      salt: DriverSignatureHelper().createSalt(),
    );
    state.communicator = device;
    state.challenge = challenge;

    state.socket.add(challenge.toString());
    logger.info(
      '[DEVICE]: received announcement: [${cmd.device.id}]',
    );
  }
}
