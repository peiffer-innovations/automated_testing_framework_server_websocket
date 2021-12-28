import 'dart:async';
import 'dart:io';

import 'package:automated_testing_framework_models/automated_testing_framework_models.dart';
import 'package:automated_testing_framework_server_websocket/automated_testing_framework_server_websocket.dart';
import 'package:logging/logging.dart';

class DefaultAuthenticator extends Authenticator {
  DefaultAuthenticator({
    Map<String, AuthenticationCommandHandler> handlers = const {},
    Logger? logger,
  })  : _handlers = handlers,
        super(logger: logger ?? Logger('DefaultAuthenticator'));

  /// The mapping of handlers to the appropriate [WebSocketCommunicator] that it
  /// generates.  The key is the runtime type of the class.  For example an
  /// authorizer for a [Driver] would have
  final Map<String, AuthenticationCommandHandler> _handlers;

  @override
  Future<WebSocketCommunicator?> authenticate({
    required Stream<DeviceCommand> commandStream,
    required WebSocket socket,
  }) async {
    var state = AuthenticationState(
      commandStream: commandStream,
      socket: socket,
    );

    Completer? completer = Completer<void>();
    var future = completer.future;

    Timer? timer = Timer(Duration(minutes: 2), () async {
      try {
        logger.info(
          '[CONNECTION]: connection timed out.',
        );

        completer?.completeError('[CONNECTION]: connection timed out.');
        completer = null;
      } catch (e) {
        // no-op
      }
    });

    var sub = commandStream.listen((cmd) async {
      if (_handlers.containsKey(cmd.type)) {
        var handler = _handlers[cmd.type];
        await handler!.handle(
          command: cmd,
          state: state,
        );
        if (state.success != null) {
          completer?.complete();
          completer = null;
        }
      } else {
        logger.info(
          '[CLOSE]: unknown command type: [${cmd.type}], ignoring...',
        );
        completer?.complete(null);
        completer = null;
      }
    }, onError: (Object e, StackTrace stack) {
      logger.severe('[SOCKET]: error listening to socket', e, stack);
      completer?.completeError('[SOCKET]: error listening to socket');
      completer = null;
    });

    try {
      await future;
    } catch (e, stack) {
      logger.severe('Error in authenticator', e, stack);
    }
    timer.cancel();

    await sub.cancel();

    if (state.success == true) {
      state.communicator!.attachSocket(socket);
    }

    return state.success == true ? state.communicator : null;
  }
}
