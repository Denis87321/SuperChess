import 'dart:convert';

import 'package:http/http.dart' as http;

import '../online/server_config.dart';
import 'auth_service.dart';

/// Thin REST client for platform features (profiles, clubs, forum, puzzles…).
class PlatformApi {
  PlatformApi(this.auth, {String? httpBaseUrl})
      : _httpBase = httpBaseUrl ?? defaultHttpBaseUrl();

  final AuthService auth;
  final String _httpBase;

  String? get _token => auth.token;

  Map<String, String> get _jsonHeaders => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Map<String, String> get _authHeaders => {
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<Map<String, dynamic>> getProfile(String username) async {
    return _getJson('/user/profile/${Uri.encodeComponent(username)}');
  }

  Future<void> updateProfile({String? bio, String? country}) async {
    await _postJson('/user/profile', {
      'bio': ?bio,
      'country': ?country,
    });
  }

  Future<void> follow(String userId) async {
    await _postJson('/user/follow/$userId', const {});
  }

  Future<void> unfollow(String userId) async {
    await _delete('/user/follow/$userId');
  }

  Future<List<Map<String, dynamic>>> listFollowers(String userId) async {
    final body = await _getJson('/user/$userId/followers');
    return _mapList(body['followers']);
  }

  Future<List<Map<String, dynamic>>> listFollowing(String userId) async {
    final body = await _getJson('/user/$userId/following');
    return _mapList(body['following']);
  }

  Future<List<Map<String, dynamic>>> listMessages(String peerId) async {
    final body = await _getJson('/user/friends/messages/$peerId');
    return _mapList(body['messages']);
  }

  Future<Map<String, dynamic>> sendMessage(String peerId, String body) async {
    return _postJson('/user/friends/messages/$peerId', {'body': body});
  }

  Future<Map<String, dynamic>> nextPuzzle({List<String>? themes}) async {
    final q = (themes == null || themes.isEmpty)
        ? ''
        : '?themes=${Uri.encodeQueryComponent(themes.join(','))}';
    return _getJson('/puzzles/next$q');
  }

  Future<Map<String, dynamic>> puzzleResult(String id, bool solved) async {
    return _postJson('/puzzles/$id/result', {'solved': solved});
  }

  Future<Map<String, dynamic>> myPuzzleRating() async {
    return _getJson('/puzzles/me');
  }

  Future<List<Map<String, dynamic>>> listClubs() async {
    final body = await _getJson('/clubs');
    return _mapList(body['clubs']);
  }

  Future<Map<String, dynamic>> createClub({
    required String name,
    String? description,
  }) async {
    return _postJson('/clubs', {
      'name': name,
      'description': ?description,
    });
  }

  Future<Map<String, dynamic>> getClub(String id) async {
    return _getJson('/clubs/$id');
  }

  Future<void> joinClub(String id) async {
    await _postJson('/clubs/$id/join', const {});
  }

  Future<List<Map<String, dynamic>>> listForumCategories({String? clubId}) async {
    final q = clubId == null ? '' : '?clubId=${Uri.encodeQueryComponent(clubId)}';
    final body = await _getJson('/forum/categories$q');
    return _mapList(body['categories']);
  }

  Future<List<Map<String, dynamic>>> listForumTopics(String categoryId) async {
    final body = await _getJson(
      '/forum/topics?categoryId=${Uri.encodeQueryComponent(categoryId)}',
    );
    return _mapList(body['topics']);
  }

  Future<Map<String, dynamic>> createForumTopic({
    required String categoryId,
    required String title,
  }) async {
    return _postJson('/forum/topics', {
      'categoryId': categoryId,
      'title': title,
    });
  }

  Future<List<Map<String, dynamic>>> listForumPosts(String topicId) async {
    final body = await _getJson(
      '/forum/posts?topicId=${Uri.encodeQueryComponent(topicId)}',
    );
    return _mapList(body['posts']);
  }

  Future<Map<String, dynamic>> createForumPost({
    required String topicId,
    required String body,
  }) async {
    return _postJson('/forum/posts', {
      'topicId': topicId,
      'body': body,
    });
  }

  Future<String> getPgn(String gameId) async {
    final response = await http.get(
      Uri.parse('$_httpBase/games/$gameId/pgn'),
      headers: _authHeaders,
    );
    _throwIfBad(response);
    return response.body;
  }

  Future<Map<String, dynamic>> getAnalysis(String gameId) async {
    return _getJson('/games/$gameId/analysis');
  }

  Future<Map<String, dynamic>> requestAnalysis(String gameId) async {
    return _postJson('/games/$gameId/analysis', const {});
  }

  Future<void> registerDevice(String token, String platform) async {
    await _postJson('/user/devices', {
      'token': token,
      'platform': platform,
    });
  }

  /// Public URL for downloading a game PGN in a browser.
  String pgnUrl(String gameId) => '$_httpBase/games/$gameId/pgn';

  Future<Map<String, dynamic>> _getJson(String path) async {
    final response = await http.get(
      Uri.parse('$_httpBase$path'),
      headers: _authHeaders,
    );
    _throwIfBad(response);
    return _decodeMap(response);
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      Uri.parse('$_httpBase$path'),
      headers: _jsonHeaders,
      body: jsonEncode(body),
    );
    _throwIfBad(response);
    if (response.body.isEmpty) return const {};
    return _decodeMap(response);
  }

  Future<void> _delete(String path) async {
    final response = await http.delete(
      Uri.parse('$_httpBase$path'),
      headers: _authHeaders,
    );
    _throwIfBad(response);
  }

  void _throwIfBad(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw AuthException(
      _errorMessage(response) ?? 'Request failed',
      statusCode: response.statusCode,
    );
  }

  Map<String, dynamic> _decodeMap(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    throw AuthException('Invalid server response');
  }

  List<Map<String, dynamic>> _mapList(dynamic raw) {
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map) Map<String, dynamic>.from(item),
    ];
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
