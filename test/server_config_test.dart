import 'package:flutter_test/flutter_test.dart';
import 'package:super_chess/online/server_config.dart';

void main() {
  test('production URL is wss for HTTPS sites and mobile release', () {
    expect(kProductionServerUrl.startsWith('wss://'), isTrue);
    expect(kProductionServerUrl.endsWith('/ws'), isTrue);
    expect(kProductionServerUrl.contains('onrender.com'), isTrue);
  });

  test('local URL is ws for development', () {
    expect(kLocalServerUrl, 'ws://127.0.0.1:8080/ws');
    expect(kAndroidEmulatorServerUrl, 'ws://10.0.2.2:8080/ws');
  });

  test('dart-define override constant is readable', () {
    // When SUPERCHESS_SERVER_URL is not passed, define is empty.
    // Release builds then fall back to kProductionServerUrl via defaultServerUrl.
    expect(kServerUrlDefine, anyOf(isEmpty, startsWith('ws')));
  });
}
