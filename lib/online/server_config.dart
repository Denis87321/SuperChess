/// HTTP + WebSocket endpoints for the matchmaking/auth API.
library;

const String kServerUrlDefine = String.fromEnvironment(
  'SUPERCHESS_SERVER_URL',
);

/// Production default after Render deploy.
const String kProductionServerUrl = 'wss://superchess-api-qqpu.onrender.com/ws';

/// Local development defaults (desktop / web on the same machine).
const String kLocalServerUrl = 'ws://127.0.0.1:8080/ws';

/// Android emulator → host machine loopback.
const String kAndroidEmulatorServerUrl = 'ws://10.0.2.2:8080/ws';

/// By default always talk to the public Render API.
String defaultServerUrl() {
  if (kServerUrlDefine.isNotEmpty) {
    return kServerUrlDefine;
  }
  return kProductionServerUrl;
}

/// Derive REST base (`https://host`) from WebSocket URL (`wss://host/ws`).
String defaultHttpBaseUrl({String? wsUrl}) {
  final ws = wsUrl ?? defaultServerUrl();
  var url = ws;
  if (url.startsWith('wss://')) {
    url = 'https://${url.substring(6)}';
  } else if (url.startsWith('ws://')) {
    url = 'http://${url.substring(5)}';
  }
  if (url.endsWith('/ws')) {
    url = url.substring(0, url.length - 3);
  }
  if (url.endsWith('/')) {
    url = url.substring(0, url.length - 1);
  }
  return url;
}
