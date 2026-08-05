import 'package:flutter/foundation.dart';

/// WebSocket matchmaking URL.
///
/// Override at build/run time:
/// `flutter run --dart-define=SUPERCHESS_SERVER_URL=wss://your-app.fly.dev/ws`
/// `flutter build web --dart-define=SUPERCHESS_SERVER_URL=wss://your-app.fly.dev/ws`
const String kServerUrlDefine = String.fromEnvironment(
  'SUPERCHESS_SERVER_URL',
);

/// Production default used when [kServerUrlDefine] is empty and this is a
/// release web/mobile build. Update after the first Fly.io deploy.
const String kProductionServerUrl = 'wss://superchess-api.fly.dev/ws';

/// Local development defaults (desktop / web on the same machine).
const String kLocalServerUrl = 'ws://127.0.0.1:8080/ws';

/// Android emulator → host machine loopback.
const String kAndroidEmulatorServerUrl = 'ws://10.0.2.2:8080/ws';

String defaultServerUrl() {
  if (kServerUrlDefine.isNotEmpty) {
    return kServerUrlDefine;
  }

  // Release clients talk to the public matchmaking server.
  if (kReleaseMode) {
    return kProductionServerUrl;
  }

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return kAndroidEmulatorServerUrl;
  }

  return kLocalServerUrl;
}
