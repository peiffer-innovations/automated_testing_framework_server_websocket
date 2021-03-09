import 'package:json_class/json_class.dart';

class ServerConfiguration {
  factory ServerConfiguration() => _singleton;
  ServerConfiguration._internal();

  static const kDefaultReservationTimeout = Duration(seconds: 10);
  static const kDefaultMaxConnectionTime = Duration(minutes: 45);

  static final ServerConfiguration _singleton = ServerConfiguration._internal();

  static void fromDynamic(dynamic map) {
    if (map != null) {
      _singleton.maxConnectionTime = JsonClass.parseDurationFromMillis(
            map['maxConnectionTime'],
          ) ??
          kDefaultMaxConnectionTime;
      _singleton.reservationTimeout = JsonClass.parseDurationFromMillis(
            map['reservationTimeout'],
          ) ??
          kDefaultReservationTimeout;
    }
  }

  Duration maxConnectionTime = kDefaultMaxConnectionTime;
  Duration reservationTimeout = kDefaultReservationTimeout;
}
