import 'package:json_class/json_class.dart';

class ServerConfiguration {
  factory ServerConfiguration() => _singleton;
  ServerConfiguration._internal();

  static const kDefaultReservationTimeout = Duration(seconds: 10);
  static const kDefaultPingTimeout = Duration(minutes: 5);
  static const kDefaultMaxConnectionTime = Duration(minutes: 45);

  static final ServerConfiguration _singleton = ServerConfiguration._internal();

  static void fromDynamic(dynamic map) {
    if (map != null) {
      _singleton.reservationTimeout = JsonClass.parseDurationFromMillis(
        map['reservationTimeout'],
      );
    }
  }

  Duration _maxConnectionTime = kDefaultMaxConnectionTime;
  Duration _pingTimeout = kDefaultPingTimeout;
  Duration _reservationTimeout = kDefaultReservationTimeout;

  Duration get maxConnectionTime => _maxConnectionTime;
  Duration get pingTimeout => _pingTimeout;
  Duration get reservationTimeout => _reservationTimeout;

  set maxConnectionTime(Duration maxConnectionTime) =>
      _maxConnectionTime = maxConnectionTime ?? kDefaultMaxConnectionTime;
  set pingTimeout(Duration pingTimeout) =>
      _pingTimeout = pingTimeout ?? kDefaultPingTimeout;
  set reservationTimeout(Duration timeout) =>
      _reservationTimeout = timeout ?? kDefaultReservationTimeout;
}
