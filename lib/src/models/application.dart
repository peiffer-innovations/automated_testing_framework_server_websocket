import 'dart:async';

import 'package:automated_testing_framework_server_websocket/automated_testing_framework_server_websocket.dart';

class Application {
  factory Application({
    required String appIdentifier,
    Duration staleTimeout = const Duration(minutes: 15),
  }) =>
      _applications[appIdentifier] ??
      Application.create(
        appIdentifier: appIdentifier,
        staleTimeout: staleTimeout,
      );

  Application.create({
    required this.appIdentifier,
    required Duration staleTimeout,
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

      if (devices.isEmpty == true &&
          drivers.isEmpty == true &&
          sessions.isEmpty == true) {
        stop();
      }
    });
  }

  static final Map<String, Application> _applications = {};
  static Iterable<Application> get all => _applications.values;

  final String appIdentifier;

  final Map<String, Device> devices = {};
  final Map<String, Driver> drivers = {};
  final Map<String, Session> sessions = {};

  Timer? _timer;

  void stop() {
    _timer?.cancel();
    _timer = null;

    _applications.remove(appIdentifier);
  }
}
