import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:super_chess_engine/super_chess_engine.dart';

import 'auth.dart';
import 'db.dart';

void mountPlatformRoutes(
  Router router, {
  required AuthDatabase? Function() db,
  required AuthTokens? Function() tokens,
  required Set<String> Function() onlineUserIds,
}) {
  Response json(Object body, {int status = 200}) => Response(
        status,
        body: jsonEncode(body),
        headers: {'content-type': 'application/json'},
      );

  Future<UserRecord?> userOf(Request request) async {
    final d = db();
    final t = tokens();
    if (d == null || t == null) return null;
    final auth = request.headers['authorization'] ?? '';
    if (!auth.toLowerCase().startsWith('bearer ')) return null;
    final payload = t.verify(auth.substring(7).trim());
    if (payload == null) return null;
    final id = payload['sub'] as String?;
    if (id == null) return null;
    return d.findById(id);
  }

  router.get('/meta/time-controls', (Request request) {
    return json({
      'controls': [for (final tc in kLobbyTimeControls) tc.toJson()],
    });
  });

  router.get('/user/profile/<username>', (Request request, String username) async {
    final d = db();
    if (d == null) return json({'error': 'unavailable'}, status: 503);
    final profile = await d.publicProfile(username);
    if (profile == null) return json({'error': 'not found'}, status: 404);
    final id = profile['id'] as String?;
    if (id != null) {
      profile['online'] = onlineUserIds().contains(id);
    }
    return json(profile);
  });

  router.post('/user/profile', (Request request) async {
    final d = db();
    final user = await userOf(request);
    if (d == null || user == null) return json({'error': 'auth'}, status: 401);
    final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    await d.updateProfile(
      userId: user.id,
      bio: body['bio'] as String?,
      country: body['country'] as String?,
      avatarUrl: body['avatarUrl'] as String?,
    );
    return json({'ok': true});
  });

  router.post('/user/follow/<id>', (Request request, String id) async {
    final d = db();
    final user = await userOf(request);
    if (d == null || user == null) return json({'error': 'auth'}, status: 401);
    await d.follow(user.id, id);
    return json({'ok': true});
  });

  router.delete('/user/follow/<id>', (Request request, String id) async {
    final d = db();
    final user = await userOf(request);
    if (d == null || user == null) return json({'error': 'auth'}, status: 401);
    await d.unfollow(user.id, id);
    return json({'ok': true});
  });

  router.get('/user/<id>/followers', (Request request, String id) async {
    final d = db();
    if (d == null) return json({'error': 'unavailable'}, status: 503);
    return json({'followers': await d.listFollowers(id)});
  });

  router.get('/user/<id>/following', (Request request, String id) async {
    final d = db();
    if (d == null) return json({'error': 'unavailable'}, status: 503);
    return json({'following': await d.listFollowing(id)});
  });

  router.get('/user/friends/messages/<peerId>', (Request request, String peerId) async {
    final d = db();
    final user = await userOf(request);
    if (d == null || user == null) return json({'error': 'auth'}, status: 401);
    return json({'messages': await d.listFriendMessages(user.id, peerId)});
  });

  router.post('/user/friends/messages/<peerId>', (Request request, String peerId) async {
    final d = db();
    final user = await userOf(request);
    if (d == null || user == null) return json({'error': 'auth'}, status: 401);
    final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final text = '${body['body'] ?? ''}'.trim();
    if (text.isEmpty) return json({'error': 'empty'}, status: 400);
    final msg = await d.sendFriendMessage(
      fromId: user.id,
      toId: peerId,
      body: text,
    );
    return json(msg);
  });

  router.get('/games/<id>/pgn', (Request request, String id) async {
    final d = db();
    if (d == null) return json({'error': 'unavailable'}, status: 503);
    final pgn = await d.getGamePgn(id);
    if (pgn == null) return json({'error': 'not found'}, status: 404);
    return Response.ok(pgn, headers: {'content-type': 'application/x-chess-pgn'});
  });

  router.get('/games/<id>/fairplay', (Request request, String id) async {
    final d = db();
    if (d == null) return json({'error': 'unavailable'}, status: 503);
    final report = await d.getFairPlayReport(id);
    if (report == null) {
      return json({'gameId': id, 'sides': [], 'recentSamples': []});
    }
    return json(report);
  });

  router.get('/fairplay/flags', (Request request) async {
    final d = db();
    final user = await userOf(request);
    if (d == null || user == null) return json({'error': 'auth'}, status: 401);
    final flags = await d.listFairPlayFlags();
    return json({'flags': flags});
  });

  router.get('/games/<id>/analysis', (Request request, String id) async {
    final d = db();
    if (d == null) return json({'error': 'unavailable'}, status: 503);
    final a = await d.getAnalysis(id);
    if (a == null) return json({'status': 'none'});
    return json(a);
  });

  router.post('/games/<id>/analysis', (Request request, String id) async {
    final d = db();
    final user = await userOf(request);
    if (d == null || user == null) return json({'error': 'auth'}, status: 401);
    final jobId = await d.enqueueAnalysis(id);
    return json({'jobId': jobId, 'status': 'pending'});
  });

  router.post('/puzzles/seed', (Request request) async {
    final d = db();
    final user = await userOf(request);
    if (d == null || user == null) return json({'error': 'auth'}, status: 401);
    final body = jsonDecode(await request.readAsString());
    final list = body is List ? body : (body is Map ? body['puzzles'] : null);
    if (list is! List) return json({'error': 'list'}, status: 400);
    var n = 0;
    for (final raw in list) {
      if (raw is! Map) continue;
      final p = Map<String, dynamic>.from(raw);
      final id = '${p['id'] ?? ''}';
      if (id.isEmpty) continue;
      await d.upsertPuzzle(
        id: id,
        setupJson: p,
        goal: '${p['goal'] ?? 'checkmate'}',
        themes: [
          if (p['hintAbility'] != null) '${p['hintAbility']}',
          '${p['goal'] ?? 'checkmate'}',
        ],
        titleRu: p['titleRu'] as String?,
        titleEn: p['titleEn'] as String?,
      );
      n++;
    }
    return json({'seeded': n});
  });

  router.get('/puzzles/next', (Request request) async {
    final d = db();
    if (d == null) return json({'error': 'unavailable'}, status: 503);
    final themes = request.url.queryParameters['themes'];
    final puzzle = await d.nextPuzzle(
      themes: themes == null || themes.isEmpty ? null : themes.split(','),
    );
    if (puzzle == null) return json({'error': 'empty'}, status: 404);
    return json(puzzle);
  });

  router.post('/puzzles/<id>/result', (Request request, String id) async {
    final d = db();
    final user = await userOf(request);
    if (d == null || user == null) return json({'error': 'auth'}, status: 401);
    final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final solved = body['solved'] == true;
    final rating = await d.recordPuzzleResult(
      userId: user.id,
      puzzleId: id,
      solved: solved,
    );
    return json(rating);
  });

  router.get('/puzzles/me', (Request request) async {
    final d = db();
    final user = await userOf(request);
    if (d == null || user == null) return json({'error': 'auth'}, status: 401);
    return json(await d.getUserPuzzleRating(user.id));
  });

  router.get('/clubs', (Request request) async {
    final d = db();
    if (d == null) return json({'error': 'unavailable'}, status: 503);
    return json({'clubs': await d.listClubs()});
  });

  router.post('/clubs', (Request request) async {
    final d = db();
    final user = await userOf(request);
    if (d == null || user == null) return json({'error': 'auth'}, status: 401);
    final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final name = '${body['name'] ?? ''}'.trim();
    if (name.isEmpty) return json({'error': 'name'}, status: 400);
    final club = await d.createClub(
      name: name,
      description: body['description'] as String?,
      ownerId: user.id,
    );
    return json(club);
  });

  router.get('/clubs/<id>', (Request request, String id) async {
    final d = db();
    if (d == null) return json({'error': 'unavailable'}, status: 503);
    final club = await d.getClub(id);
    if (club == null) return json({'error': 'not found'}, status: 404);
    return json(club);
  });

  router.post('/clubs/<id>/join', (Request request, String id) async {
    final d = db();
    final user = await userOf(request);
    if (d == null || user == null) return json({'error': 'auth'}, status: 401);
    await d.joinClub(id, user.id);
    return json({'ok': true});
  });

  router.get('/forum/categories', (Request request) async {
    final d = db();
    if (d == null) return json({'error': 'unavailable'}, status: 503);
    final clubId = request.url.queryParameters['clubId'];
    return json({'categories': await d.listCategories(clubId: clubId)});
  });

  router.post('/forum/topics', (Request request) async {
    final d = db();
    final user = await userOf(request);
    if (d == null || user == null) return json({'error': 'auth'}, status: 401);
    final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final topic = await d.createTopic(
      categoryId: '${body['categoryId']}',
      authorId: user.id,
      title: '${body['title'] ?? ''}'.trim(),
    );
    return json(topic);
  });

  router.get('/forum/topics', (Request request) async {
    final d = db();
    if (d == null) return json({'error': 'unavailable'}, status: 503);
    final cat = request.url.queryParameters['categoryId'];
    if (cat == null) return json({'error': 'categoryId'}, status: 400);
    return json({'topics': await d.listTopics(cat)});
  });

  router.post('/forum/posts', (Request request) async {
    final d = db();
    final user = await userOf(request);
    if (d == null || user == null) return json({'error': 'auth'}, status: 401);
    final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final post = await d.createPost(
      topicId: '${body['topicId']}',
      authorId: user.id,
      body: '${body['body'] ?? ''}',
    );
    return json(post);
  });

  router.get('/forum/posts', (Request request) async {
    final d = db();
    if (d == null) return json({'error': 'unavailable'}, status: 503);
    final topicId = request.url.queryParameters['topicId'];
    if (topicId == null) return json({'error': 'topicId'}, status: 400);
    return json({'posts': await d.listPosts(topicId)});
  });

  router.post('/user/devices', (Request request) async {
    final d = db();
    final user = await userOf(request);
    if (d == null || user == null) return json({'error': 'auth'}, status: 401);
    final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final token = '${body['token'] ?? ''}'.trim();
    if (token.isEmpty) return json({'error': 'token'}, status: 400);
    await d.registerDevice(
      userId: user.id,
      token: token,
      platform: '${body['platform'] ?? 'unknown'}',
    );
    return json({'ok': true});
  });
}
