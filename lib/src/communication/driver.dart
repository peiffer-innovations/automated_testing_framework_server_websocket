import 'package:automated_testing_framework_server_websocket/automated_testing_framework_server_websocket.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

class Driver extends WebSocketCommunicator {
  Driver({
    @required this.appIdentifier,
    @required this.driverId,
    @required this.driverName,
  })  : assert(appIdentifier != null),
        assert(driverId != null),
        assert(driverName != null),
        super(
          logger: Logger('$driverName - $driverId'),
        );

  final String appIdentifier;
  final String driverId;
  final String driverName;
}
