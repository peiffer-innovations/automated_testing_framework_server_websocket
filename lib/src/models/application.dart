import 'dart:async';

import 'package:automated_testing_framework_server_websocket/automated_testing_framework_server_websocket.dart';

class Application {
  Application({
    required this.appIdentifier,
    Duration staleTimeout = const Duration(minutes: 15),
  }) {
    _timer = Timer.periodic(Duration(minutes: 1), (timer) {
      var timeout =
          DateTime.now().millisecondsSinceEpoch - staleTimeout.inMilliseconds;

      var staleDevices = devices.keys.where(
          (key) => devices[key]!.lastPing.millisecondsSinceEpoch < timeout);
      var staleDrivers = drivers.keys.where(
          (key) => drivers[key]!.lastPing.millisecondsSinceEpoch < timeout);

      devices.removeWhere((key, value) => staleDevices.contains(value));
      drivers.removeWhere((key, value) => staleDrivers.contains(value));

      var staleSessions = <String>[];
      sessions.forEach((key, value) {
        if (staleDevices.contains(value.device) ||
            staleDrivers.contains(value.driver)) {
          value.close();
          staleSessions.add(key);
        }
      });
      sessions.removeWhere((key, value) => staleSessions.contains(key));
    });
  }

  final String appIdentifier;

  final Map<String, Device> devices = {};
  final Map<String, Driver> drivers = {};
  final Map<String, Session> sessions = {};

  Timer? _timer;

  void stop() {
    _timer?.cancel();
  }
}
