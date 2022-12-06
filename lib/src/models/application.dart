import 'dart:async';

import 'package:automated_testing_framework_server_websocket/automated_testing_framework_server_websocket.dart';
import 'package:logging/logging.dart';

class Application {
  factory Application({
    required String appIdentifier,
    Logger? logger,
    Duration staleTimeout = const Duration(minutes: 15),
  }) =>
      _applications[appIdentifier] ??
      Application.create(
        appIdentifier: appIdentifier,
        logger: logger ?? Logger('Application: $appIdentifier'),
        staleTimeout: staleTimeout,
      );

  Application.create({
    required this.appIdentifier,
    required this.logger,
    required Duration staleTimeout,
  }) {
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      try {
        final timeout =
            DateTime.now().millisecondsSinceEpoch - staleTimeout.inMilliseconds;

        final staleDevices = devices.keys.where(
            (key) => devices[key]!.lastPing.millisecondsSinceEpoch < timeout);
        final staleDrivers = drivers.keys.where(
            (key) => drivers[key]!.lastPing.millisecondsSinceEpoch < timeout);

        devices.removeWhere((key, value) => staleDevices.contains(value));
        drivers.removeWhere((key, value) => staleDrivers.contains(value));

        final staleSessions = <String>[];
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
      } catch (e, stack) {
        logger.severe('Error in application timer', e, stack);
      }
    });
  }

  static final Map<String, Application> _applications = {};

  static Iterable<Application> get all => _applications.values;

  final String appIdentifier;

  final Map<String, Device> devices = {};
  final Map<String, Driver> drivers = {};
  final Logger logger;
  final Map<String, Session> sessions = {};

  Timer? _timer;

  void stop() {
    _timer?.cancel();
    _timer = null;

    _applications.remove(appIdentifier);
  }
}
