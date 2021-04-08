import 'package:automated_testing_framework_server_websocket/automated_testing_framework_server_websocket.dart';
import 'package:logging/logging.dart';

class Driver extends WebSocketCommunicator {
  Driver({
    required this.appIdentifier,
    required this.driverId,
    required this.driverName,
  }) : super(
          logger: Logger('DRIVER: $driverName - $driverId'),
        ) {
    logger.fine(toString());
  }

  final String appIdentifier;
  final String driverId;
  final String driverName;

  @override
  String toString() =>
      '[DRIVER] - [$appIdentifier] - [$driverId] - [$driverName]';
}
