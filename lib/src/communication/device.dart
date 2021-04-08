import 'package:automated_testing_framework_models/automated_testing_framework_models.dart';
import 'package:automated_testing_framework_server_websocket/automated_testing_framework_server_websocket.dart';
import 'package:logging/logging.dart';

/// Represents a connected device capable of receiving test commands.
class Device extends WebSocketCommunicator {
  Device({
    required this.appIdentifier,
    required this.device,
    this.driverName,
    this.testControllerState,
  }) : super(
          logger: Logger('DEVICE: ${device.id}'),
        ) {
    logger.fine('[APPLICATION]: $appIdentifier');
    logger.fine(toString());
  }

  /// The unique identifier
  final String appIdentifier;
  final TestDeviceInfo device;
  String? driverName;
  TestControllerState? testControllerState;

  @override
  void close() {
    sendCommand(ReleaseDeviceCommand(deviceId: device.id));

    super.close();
  }

  ConnectedDevice toConnectedDevice() => ConnectedDevice(
        device: device,
        driverName: driverName,
        testControllerState: testControllerState!,
      );

  @override
  String toString() =>
      '[DEVICE]: ${device.os} | ${device.manufacturer} | ${device.brand} | ${device.device} | ${device.model} | ${device.buildNumber}';
}
