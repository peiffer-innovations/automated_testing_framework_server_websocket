import 'package:automated_testing_framework_server_websocket/automated_testing_framework_server_websocket.dart';
import 'package:test/test.dart';

void main() {
  test('ServerConfiguration', () {
    var config = ServerConfiguration();
    expect(config != null, true);
  });
}
