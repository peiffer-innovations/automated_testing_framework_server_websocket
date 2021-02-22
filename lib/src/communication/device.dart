import 'package:automated_testing_framework_models/automated_testing_framework_models.dart';
import 'package:automated_testing_framework_server_websocket/automated_testing_framework_server_websocket.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

class Device extends WebSocketCommunicator {
  Device({
    @required this.appIdentifier,
    @required this.device,
    this.driverName,
    this.testControllerState,
  })  : assert(appIdentifier != null),
        assert(device != null),
        super(
          logger: Logger(device.id),
        );

  final String appIdentifier;
  final TestDeviceInfo device;
  String driverName;
  TestControllerState testControllerState;

  ConnectedDevice toConnectedDevice() => ConnectedDevice(
        device: device,
        driverName: driverName,
        testControllerState: testControllerState,
      );
}
