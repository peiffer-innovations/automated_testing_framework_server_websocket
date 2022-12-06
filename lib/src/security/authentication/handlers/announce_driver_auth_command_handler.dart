import 'package:automated_testing_framework_models/automated_testing_framework_models.dart';
import 'package:automated_testing_framework_server_websocket/automated_testing_framework_server_websocket.dart';
import 'package:logging/logging.dart';

class AnnounceDriverAuthCommandHandler extends AuthenticationCommandHandler {
  AnnounceDriverAuthCommandHandler(this._secret)
      : super(logger: Logger('AnnounceDriverAuthCommandHandler'));

  final String _secret;

  @override
  Future<void> handle({
    required DeviceCommand command,
    required AuthenticationState state,
  }) async {
    final cmd = command as AnnounceDriverCommand;

    respondToChallenge(
      commandId: cmd.id,
      salt: cmd.salt,
      secret: _secret,
      socket: state.socket,
      timestamp: cmd.timestamp,
    );

    final app = getApplication(cmd.appIdentifier);
    final driver = getDriver(
      app: app,
      driverId: cmd.driverId,
      driverName: cmd.driverName,
    );

    final challenge = ChallengeCommand(
      salt: DriverSignatureHelper().createSalt(),
    );
    state.communicator = driver;
    state.challenge = challenge;

    state.socket.add(challenge.toString());
    logger.info(
      '[DRIVER]: received announcement: [${cmd.driverId}] -- [${cmd.driverName}]',
    );
  }
}
