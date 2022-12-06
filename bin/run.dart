import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:automated_testing_framework_models/automated_testing_framework_models.dart';
import 'package:automated_testing_framework_server_websocket/automated_testing_framework_server_websocket.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

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

  final parser = ArgParser();
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

  parser.addFlag('help', abbr: 'h');

  final parsed = parser.parse(args);

  if (parsed['help'] == true) {
    // ignore: avoid_print
    print('''
Usage: run [<options>]

Starts the websocket server for the testing framework.

-a, --address=<address>        The hostname or address for the server to listen on.
-h, --help                     Display this help message.
-p, --port=<port>              Port for the server to listen on.
''');

    exit(0);
  }

  final secrets = <String, dynamic>{};
  final file = File('secret/keys.json');
  if (file.existsSync()) {
    final data = file.readAsStringSync();
    if (data.trim().isNotEmpty == true) {
      try {
        final result = json.decode(data);
        secrets['device'] = result['device'];
        secrets['driver'] = result['driver'];
      } catch (e) {
        // no-op
      }
    }
  }

  final deviceSecret = secrets['device'] ??
      Platform.environment['ATF_DEVICE_SECRET'] ??
      const Uuid().v4();

  final driverSecret = secrets['driver'] ??
      Platform.environment['ATF_DRIVER_SECRET'] ??
      const Uuid().v4();

  var running = true;
  final sigintSub = ProcessSignal.sigint.watch().listen((event) {
    running = false;

    // ignore: avoid_print
    print('SIGINT received');

    Timer(const Duration(seconds: 2), () {
      // ignore: avoid_print
      print('force quitting');
      exit(0);
    });
  });
  try {
    while (running) {
      final server = Server(
        address: InternetAddress.tryParse(parsed['address']),
        authenticator: DefaultAuthenticator(handlers: {
          AnnounceDeviceCommand.kCommandType:
              AnnounceDeviceAuthCommandHandler(deviceSecret),
          AnnounceDriverCommand.kCommandType:
              AnnounceDriverAuthCommandHandler(driverSecret),
          ChallengeResponseCommand.kCommandType:
              ChallengeResponseAuthCommandHandler({
            Device: deviceSecret,
            Driver: driverSecret,
          }),
        }),
        port: int.tryParse(parsed['port']),
      );

      await server.listen();
    }
  } finally {
    await sigintSub.cancel();
  }

  // ignore: avoid_print
  print('server shutdown');
  exit(0);
}
