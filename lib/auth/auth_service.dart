import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_ability.dart';
import '../online/server_config.dart';

const _prefsTokenKey = 'auth_token';
const _prefsUsernameKey = 'auth_username';

class AuthException implements Exception {
  AuthException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class UserAchievement {
  UserAchievement({required this.id, required this.unlockedAt});
  final String id;
  final DateTime unlockedAt;
}

class HistoryGame {
  HistoryGame({
    required this.gameId,
    required this.opponentName,
    required this.color,
    required this.result,
    required this.rated,
    required this.createdAt,
    this.ratingBefore,
    this.ratingAfter,
    this.reason,
  });

  final String gameId;
  final String opponentName;
  final String color;
  final String result;
  final bool rated;
  final int? ratingBefore;
  final int? ratingAfter;
  final String? reason;
  final DateTime createdAt;

  int? get ratingDelta {
    if (ratingBefore == null || ratingAfter == null) return null;
    return ratingAfter! - ratingBefore!;
  }
}

class AuthService extends ChangeNotifier {
  AuthService({String? httpBaseUrl})
      : _httpBase = httpBaseUrl ?? defaultHttpBaseUrl();

  final String _httpBase;
  String? _token;
  String? _username;
  String? _userId;
  int _rating = 1500;
  int _gamesPlayed = 0;
  int _abilitiesUnlocked = 0;
  int _abilitiesTotal = GameAbility.values.length;
  List<UserAchievement> _achievements = const [];
  bool _ready = false;

  bool get isReady => _ready;
  bool get isLoggedIn => _token != null && _username != null;
  String? get token => _token;
  String? get username => _username;
  String? get userId => _userId;
  int get rating => _rating;
  int get gamesPlayed => _gamesPlayed;
  int get abilitiesUnlocked => _abilitiesUnlocked;
  int get abilitiesTotal => _abilitiesTotal;
  List<UserAchievement> get achievements => _achievements;
  bool get hasCollectorAchievement =>
      _achievements.any((a) => a.id == 'all_abilities');

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_prefsTokenKey);
    _username = prefs.getString(_prefsUsernameKey);
    if (_token != null) {
      try {
        await refreshMe();
      } catch (_) {
        await logout();
      }
    }
    _ready = true;
    notifyListeners();
  }

  Future<void> register({
    required String username,
    required String password,
  }) async {
    final data = await _post('/auth/register', {
      'username': username,
      'password': password,
    });
    await _applySession(data);
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    final data = await _post('/auth/login', {
      'username': username,
      'password': password,
    });
    await _applySession(data);
  }

  Future<void> refreshMe() async {
    final token = _token;
    if (token == null) return;
    final response = await http.get(
      Uri.parse('$_httpBase/auth/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
    if (response.statusCode == 401) {
      await logout();
      throw AuthException('Unauthorized', statusCode: 401);
    }
    if (response.statusCode == 503) {
      throw AuthException('Auth unavailable', statusCode: 503);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(
        _errorMessage(response) ?? 'Request failed',
        statusCode: response.statusCode,
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    _applyProfile(body);
    final prefs = await SharedPreferences.getInstance();
    if (_username != null) {
      await prefs.setString(_prefsUsernameKey, _username!);
    }
    notifyListeners();
  }

  Future<List<HistoryGame>> fetchHistory({int limit = 30}) async {
    final token = _token;
    if (token == null) return const [];
    final response = await http.get(
      Uri.parse('$_httpBase/user/history?limit=$limit'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(
        _errorMessage(response) ?? 'Request failed',
        statusCode: response.statusCode,
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final games = body['games'] as List<dynamic>? ?? const [];
    return [
      for (final g in games)
        if (g is Map)
          HistoryGame(
            gameId: '${g['gameId']}',
            opponentName: '${g['opponentName'] ?? 'Anonymous'}',
            color: '${g['color']}',
            result: '${g['result']}',
            rated: g['rated'] == true,
            ratingBefore: g['ratingBefore'] as int?,
            ratingAfter: g['ratingAfter'] as int?,
            reason: g['reason'] as String?,
            createdAt: DateTime.tryParse('${g['createdAt']}') ??
                DateTime.fromMillisecondsSinceEpoch(0),
          ),
    ];
  }

  Future<void> reportGameResult({
    required String gameId,
    required String color,
    required String? winner,
    required String? reason,
    required List<String> abilities,
    String? opponentName,
  }) async {
    final token = _token;
    if (token == null) return;
    final response = await http.post(
      Uri.parse('$_httpBase/games/result'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'gameId': gameId,
        'color': color,
        'winner': winner,
        'reason': reason,
        'abilities': abilities,
        'opponentName': opponentName,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      // Non-fatal for the player.
      debugPrint('game result report failed: ${response.statusCode}');
      return;
    }
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final profile = body['profile'];
      if (profile is Map<String, dynamic>) {
        _applyProfile(profile);
        notifyListeners();
      } else {
        await refreshMe();
      }
    } catch (_) {}
  }

  Future<void> logout() async {
    _token = null;
    _username = null;
    _userId = null;
    _rating = 1500;
    _gamesPlayed = 0;
    _abilitiesUnlocked = 0;
    _achievements = const [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsTokenKey);
    await prefs.remove(_prefsUsernameKey);
    notifyListeners();
  }

  Future<void> _applySession(Map<String, dynamic> data) async {
    final token = data['token'] as String?;
    final username = data['username'] as String?;
    if (token == null || username == null) {
      throw AuthException('Invalid server response');
    }
    _token = token;
    _applyProfile(data);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsTokenKey, token);
    await prefs.setString(_prefsUsernameKey, username);
    notifyListeners();
  }

  void _applyProfile(Map<String, dynamic> data) {
    _username = data['username'] as String? ?? _username;
    _userId = data['id'] as String? ?? _userId;
    _rating = data['rating'] as int? ?? _rating;
    _gamesPlayed = data['gamesPlayed'] as int? ?? _gamesPlayed;
    _abilitiesUnlocked =
        data['abilitiesUnlocked'] as int? ?? _abilitiesUnlocked;
    _abilitiesTotal = data['abilitiesTotal'] as int? ??
        GameAbility.values.length;
    final raw = data['achievements'];
    if (raw is List) {
      _achievements = [
        for (final a in raw)
          if (a is Map)
            UserAchievement(
              id: '${a['id']}',
              unlockedAt: DateTime.tryParse('${a['unlockedAt']}') ??
                  DateTime.fromMillisecondsSinceEpoch(0),
            ),
      ];
    }
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      Uri.parse('$_httpBase$path'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode == 503) {
      throw AuthException('Auth unavailable', statusCode: 503);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(
        _errorMessage(response) ?? 'Request failed',
        statusCode: response.statusCode,
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    throw AuthException('Invalid server response');
  }

  String? _errorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['error'] is String) {
        return decoded['error'] as String;
      }
    } catch (_) {}
    return null;
  }
}
