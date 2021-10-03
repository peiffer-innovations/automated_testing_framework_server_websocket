import 'package:automated_testing_framework_server_websocket/automated_testing_framework_server_websocket.dart';
import 'package:logging/logging.dart';

/// A connected test driver.
class Driver extends WebSocketCommunicator {
  Driver({
    required Application app,
    required this.appIdentifier,
    required this.driverId,
    required this.driverName,
    Duration? timeout,
  }) : super(
          app: app,
          logger: Logger('DRIVER: $driverName - $driverId'),
          timeout: timeout ?? const Duration(minutes: 5),
        ) {
    logger.fine(toString());
  }

  /// The application identifier the driver knows how to drive.
  final String appIdentifier;

  /// The unique identifier for the driver.
  final String driverId;

  /// The human readable display name for the driver.
  final String driverName;

  @override
  String toString() =>
      '[DRIVER] - [$appIdentifier] - [$driverId] - [$driverName]';
}
