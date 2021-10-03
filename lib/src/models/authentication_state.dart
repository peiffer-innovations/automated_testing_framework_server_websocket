import 'dart:io';

import 'package:automated_testing_framework_models/automated_testing_framework_models.dart';
import 'package:automated_testing_framework_server_websocket/automated_testing_framework_server_websocket.dart';

/// State object that can be used by [Authenticator] classes to pass information
/// between handlers.
class AuthenticationState {
  /// Creates the state with associated client's socket, and the command stream
  /// that sends the commands via
  AuthenticationState({
    required this.commandStream,
    required this.socket,
  });

  static const key_application = 'application';
  static const key_command = 'command';
  static const key_communicator = 'communicator';
  static const key_success = 'success';

  /// The command stream that the authenticator can listen to.
  final Stream<DeviceCommand> commandStream;

  /// The socket connected to the client to send commands to.
  final WebSocket socket;

  /// Dynamic parameters that custom [Authenticator] classes can use to pass
  /// custom values back and forth.
  final Map<String, dynamic> _params = {};

  /// Returns the current [Application] from the state.  This will be `null` if
  /// the client has not yet sent the application.
  Application? get application {
    var result = _params[key_application];

    return result is Application ? result : null;
  }

  /// Returns the current challenge that has been sent from the [Authenticator]
  /// to the client.  This will be `null` if no challenge has yet been sent.
  ChallengeCommand? get challenge {
    var result = _params[key_command];

    return result is ChallengeCommand ? result : null;
  }

  /// Returns the communicator from the state.  This is only guaranteed to be
  /// not `null` if [success] returns `true`.
  WebSocketCommunicator? get communicator {
    var result = _params[key_communicator];

    return result is WebSocketCommunicator ? result : null;
  }

  /// Returns whether or not the authentication has completed and been
  /// successful.  A value of `null` means the authentication has not yet
  /// completed.  A value of `true` means the authentication is complete and
  /// successful.  Finally, `false` means the authentication is complete and not
  /// successful.
  bool? get success {
    var result = _params[key_success];

    return result is bool ? result : null;
  }

  /// Sets the current [Application] from the client on the state.
  set application(Application? application) =>
      _params[key_application] = application;

  /// Sets the current challenge that has been sent from the [Authenticator] to
  /// the client.
  set challenge(ChallengeCommand? command) => _params[key_command] = command;

  /// Sets the current communicator on the state.
  set communicator(WebSocketCommunicator? communicator) =>
      _params[key_communicator] = communicator;

  /// Sets whether or not the authentaction is successful.
  set success(bool? success) => _params[key_success] = success;

  /// The value for the given [key], or `null` if [key] is not in the state.
  dynamic operator [](Object? key) => _params[key];

  /// Associates the [key] with the given [value].
  ///
  /// If the key was already in the state, its associated value is changed.
  /// Otherwise the key/value pair is added to the state.
  void operator []=(String key, dynamic value) => _params[key] = value;

  /// Clears the values from the state.
  void clear() => _params.clear();

  /// Whether this state contains the given [key].
  ///
  /// Returns true if any of the keys in the state are equal to [key].
  bool containsKey(String key) => _params.containsKey(key);

  /// Removes the [key] from the state and returns the associated value, if one
  /// exists.
  dynamic remove(String key) => _params.remove(key);
}
