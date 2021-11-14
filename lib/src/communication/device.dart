import 'package:automated_testing_framework_models/automated_testing_framework_models.dart';
import 'package:automated_testing_framework_server_websocket/automated_testing_framework_server_websocket.dart';
import 'package:logging/logging.dart';

/// Represents a connected device capable of receiving test commands.
class Device extends WebSocketCommunicator {
  Device({
    required Application app,
    required this.appIdentifier,
    required this.device,
    this.driverName,
    this.testControllerState,
    Duration? timeout,
  }) : super(
          app: app,
          logger: Logger('DEVICE: ${device.id}'),
          timeout: timeout ?? const Duration(minutes: 5),
        ) {
    logger.fine('[APPLICATION]: $appIdentifier');
    logger.fine(toString());
  }

  /// The unique identifier for the application.
  final String appIdentifier;

  /// The test device information.
  TestDeviceInfo device;

  /// The name of the connected driver, if one exists.
  String? driverName;

  /// The current state of the device with regards to the testing framework, if
  /// known.
  TestControllerState? testControllerState;

  /// Closes the session with the device and releases it back to the available
  /// pool should it reconnect.
  @override
  void close() {
    sendCommand(ReleaseDeviceCommand(deviceId: device.id)).catchError(
      (e, stack) => logger.info('[CLOSE]: Error sending close command'),
    );

    super.close();
  }

  /// Mapping utility that converts this model into a [ConnectedDevice]
  /// instance suitable for transmission across the socket.
  ConnectedDevice toConnectedDevice() => ConnectedDevice(
        device: device,
        driverName: driverName,
        testControllerState: testControllerState!,
      );

  @override
  String toString() =>
      '[DEVICE]: ${device.os} | ${device.manufacturer} | ${device.brand} | ${device.device} | ${device.model} | ${device.buildNumber}';
}
