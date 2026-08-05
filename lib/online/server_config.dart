/// WebSocket matchmaking URL.
///
/// Override at build/run time:
/// `flutter run --dart-define=SUPERCHESS_SERVER_URL=wss://superchess-api.onrender.com/ws`
/// Local server:
/// `flutter run --dart-define=SUPERCHESS_SERVER_URL=ws://127.0.0.1:8080/ws`
/// Android emulator → host:
/// `flutter run --dart-define=SUPERCHESS_SERVER_URL=ws://10.0.2.2:8080/ws`
const String kServerUrlDefine = String.fromEnvironment(
  'SUPERCHESS_SERVER_URL',
);

/// Production default after Render deploy.
const String kProductionServerUrl = 'wss://superchess-api.onrender.com/ws';

/// Local development defaults (desktop / web on the same machine).
const String kLocalServerUrl = 'ws://127.0.0.1:8080/ws';

/// Android emulator → host machine loopback.
const String kAndroidEmulatorServerUrl = 'ws://10.0.2.2:8080/ws';

/// By default always talk to the public Render API so phone debug builds
/// match the website. Pass `--dart-define=SUPERCHESS_SERVER_URL=...` for local.
String defaultServerUrl() {
  if (kServerUrlDefine.isNotEmpty) {
    return kServerUrlDefine;
  }
  return kProductionServerUrl;
}
