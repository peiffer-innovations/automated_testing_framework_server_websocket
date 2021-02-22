import 'dart:io';

import 'package:args/args.dart';
import 'package:automated_testing_framework_server_websocket/automated_testing_framework_server_websocket.dart';
import 'package:logging/logging.dart';

Future<void> main(List<String> args) async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print(
      '${record.level.name}: ${record.time}: [${record.loggerName}]: ${record.message}',
    );
    if (record.error != null) {
      // ignore: avoid_print
      print('${record.error}');
    }
    if (record.stackTrace != null) {
      // ignore: avoid_print
      print('${record.stackTrace}');
    }
  });

  var parser = ArgParser();
  parser.addOption(
    'address',
    abbr: 'a',
    defaultsTo: '0.0.0.0',
    help: 'The hostname or address for the server to listen on.',
  );

  parser.addOption(
    'port',
    abbr: 'p',
    defaultsTo: '15333',
    help: 'Port for the server to listen on.',
  );

  var parsed = parser.parse(args);

  var secrets = <String, dynamic>{};

  var server = Server(
    address: InternetAddress.tryParse(parsed['address']),
    deviceSecret: secrets['device'],
    driverSecret: secrets['driver'],
    port: int.tryParse(parsed['port']),
  );

  await server.listen();
}
