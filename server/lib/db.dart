import 'dart:io';

import 'package:postgres/postgres.dart';

import 'achievements.dart';
import 'elo.dart';
import 'password.dart';

class UserRecord {
  UserRecord({
    required this.id,
    required this.username,
    required this.passwordHash,
    this.rating = 1500,
    this.gamesPlayed = 0,
  });

  final String id;
  final String username;
  final String passwordHash;
  final int rating;
  final int gamesPlayed;
}

class AchievementRecord {
  AchievementRecord({required this.id, required this.unlockedAt});
  final String id;
  final DateTime unlockedAt;
}

class HistoryEntry {
  HistoryEntry({
    required this.gameId,
    required this.opponentName,
    required this.color,
    required this.result,
    required this.rated,
    required this.ratingBefore,
    required this.ratingAfter,
    required this.createdAt,
    this.reason,
  });

  final String gameId;
  final String opponentName;
  final String color;
  final String result; // win | loss | draw
  final bool rated;
  final int? ratingBefore;
  final int? ratingAfter;
  final DateTime createdAt;
  final String? reason;
}

class AuthDatabase {
  AuthDatabase(this._conn);

  final Connection _conn;

  static Future<AuthDatabase?> connect() async {
    final url = Platform.environment['DATABASE_URL'];
    if (url == null || url.isEmpty) return null;

    final uri = Uri.parse(url);
    final userInfo = uri.userInfo.split(':');
    final username = Uri.decodeComponent(userInfo.first);
    final password = userInfo.length > 1
        ? Uri.decodeComponent(userInfo.sublist(1).join(':'))
        : '';
    final database =
        uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
    final useSsl = uri.queryParameters['sslmode'] != 'disable';

    final conn = await Connection.open(
      Endpoint(
        host: uri.host,
        port: uri.hasPort ? uri.port : 5432,
        database: database.isEmpty ? 'postgres' : database,
        username: username,
        password: password,
      ),
      settings: ConnectionSettings(
        sslMode: useSsl ? SslMode.require : SslMode.disable,
      ),
    );

    final db = AuthDatabase(conn);
    await db.ensureSchema();
    return db;
  }

  Future<void> ensureSchema() async {
    await _conn.execute('CREATE EXTENSION IF NOT EXISTS pgcrypto;');
    await _conn.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        username TEXT NOT NULL,
        username_lower TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        rating INT NOT NULL DEFAULT 1500,
        games_played INT NOT NULL DEFAULT 0,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    ''');
    await _conn.execute(
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS rating INT NOT NULL DEFAULT 1500;',
    );
    await _conn.execute(
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS games_played INT NOT NULL DEFAULT 0;',
    );
    await _conn.execute('''
      CREATE TABLE IF NOT EXISTS games (
        id TEXT PRIMARY KEY,
        white_user_id UUID REFERENCES users(id),
        black_user_id UUID REFERENCES users(id),
        winner TEXT,
        reason TEXT,
        rated BOOLEAN NOT NULL DEFAULT FALSE,
        white_rating_before INT,
        black_rating_before INT,
        white_rating_after INT,
        black_rating_after INT,
        white_reported BOOLEAN NOT NULL DEFAULT FALSE,
        black_reported BOOLEAN NOT NULL DEFAULT FALSE,
        elo_applied BOOLEAN NOT NULL DEFAULT FALSE,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    ''');
    await _conn.execute('''
      CREATE TABLE IF NOT EXISTS user_ability_usage (
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        ability TEXT NOT NULL,
        PRIMARY KEY (user_id, ability)
      );
    ''');
    await _conn.execute('''
      CREATE TABLE IF NOT EXISTS user_achievements (
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        achievement_id TEXT NOT NULL,
        unlocked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        PRIMARY KEY (user_id, achievement_id)
      );
    ''');
  }

  UserRecord _userFromRow(ResultRow row) {
    return UserRecord(
      id: row[0]! as String,
      username: row[1]! as String,
      passwordHash: row[2]! as String,
      rating: row[3] as int? ?? 1500,
      gamesPlayed: row[4] as int? ?? 0,
    );
  }

  static const _userSelect =
      'SELECT id::text, username, password_hash, rating, games_played FROM users ';

  Future<UserRecord?> findByUsername(String username) async {
    final result = await _conn.execute(
      Sql.named('$_userSelect WHERE username_lower = @lower LIMIT 1'),
      parameters: {'lower': username.toLowerCase()},
    );
    if (result.isEmpty) return null;
    return _userFromRow(result.first);
  }

  Future<UserRecord?> findById(String id) async {
    final result = await _conn.execute(
      Sql.named('$_userSelect WHERE id = @id::uuid LIMIT 1'),
      parameters: {'id': id},
    );
    if (result.isEmpty) return null;
    return _userFromRow(result.first);
  }

  Future<UserRecord?> createUser({
    required String username,
    required String password,
  }) async {
    final hash = PasswordHasher.hash(password);
    try {
      final result = await _conn.execute(
        Sql.named(
          'INSERT INTO users (username, username_lower, password_hash) '
          'VALUES (@username, @lower, @hash) '
          'RETURNING id::text, username, password_hash, rating, games_played',
        ),
        parameters: {
          'username': username,
          'lower': username.toLowerCase(),
          'hash': hash,
        },
      );
      return _userFromRow(result.first);
    } on ServerException catch (e) {
      if (e.code == '23505') return null;
      rethrow;
    }
  }

  Future<int> countAbilities(String userId) async {
    final result = await _conn.execute(
      Sql.named(
        'SELECT COUNT(*)::int FROM user_ability_usage WHERE user_id = @id::uuid',
      ),
      parameters: {'id': userId},
    );
    return result.first[0] as int? ?? 0;
  }

  Future<List<AchievementRecord>> achievementsFor(String userId) async {
    final result = await _conn.execute(
      Sql.named(
        'SELECT achievement_id, unlocked_at '
        'FROM user_achievements WHERE user_id = @id::uuid '
        'ORDER BY unlocked_at',
      ),
      parameters: {'id': userId},
    );
    return [
      for (final row in result)
        AchievementRecord(
          id: row[0]! as String,
          unlockedAt: row[1]! as DateTime,
        ),
    ];
  }

  Future<Map<String, dynamic>> profileJson(UserRecord user) async {
    final unlocked = await countAbilities(user.id);
    final achievements = await achievementsFor(user.id);
    return {
      'id': user.id,
      'username': user.username,
      'rating': user.rating,
      'gamesPlayed': user.gamesPlayed,
      'abilitiesUnlocked': unlocked,
      'abilitiesTotal': kAbilitiesTotal,
      'achievements': [
        for (final a in achievements)
          {
            'id': a.id,
            'unlockedAt': a.unlockedAt.toUtc().toIso8601String(),
          },
      ],
    };
  }

  Future<void> recordAbilityUsage({
    required String userId,
    required Iterable<String> abilities,
  }) async {
    for (final raw in abilities) {
      final ability = raw.trim();
      if (ability.isEmpty || ability.length > 64) continue;
      if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$').hasMatch(ability)) continue;
      await _conn.execute(
        Sql.named(
          'INSERT INTO user_ability_usage (user_id, ability) '
          'VALUES (@id::uuid, @ability) ON CONFLICT DO NOTHING',
        ),
        parameters: {'id': userId, 'ability': ability},
      );
    }
    final unlocked = await countAbilities(userId);
    if (unlocked >= kAbilitiesTotal) {
      await _conn.execute(
        Sql.named(
          'INSERT INTO user_achievements (user_id, achievement_id) '
          'VALUES (@id::uuid, @aid) ON CONFLICT DO NOTHING',
        ),
        parameters: {'id': userId, 'aid': kAchievementAllAbilities},
      );
    }
  }

  /// Idempotent game result for one side. Returns updated profile snippet.
  Future<Map<String, dynamic>> submitGameResult({
    required String gameId,
    required String userId,
    required String color, // white | black
    required String? winner, // white | black | null
    required String? reason,
    required String? opponentUserId,
    required String opponentName,
    required List<String> abilities,
  }) async {
    final rated = opponentUserId != null;
    final isWhite = color == 'white';
    final whiteId = isWhite ? userId : opponentUserId;
    final blackId = isWhite ? opponentUserId : userId;

    await _conn.execute(
      Sql.named(
        'INSERT INTO games (id, white_user_id, black_user_id, winner, reason, rated) '
        'VALUES ('
        '@id, '
        'CAST(@white AS uuid), '
        'CAST(@black AS uuid), '
        '@winner, @reason, @rated'
        ') ON CONFLICT (id) DO NOTHING',
      ),
      parameters: {
        'id': gameId,
        'white': whiteId,
        'black': blackId,
        'winner': winner ?? 'draw',
        'reason': reason,
        'rated': rated,
      },
    );

    await _conn.execute(
      Sql.named(
        'UPDATE games SET '
        'white_user_id = COALESCE(white_user_id, CAST(@white AS uuid)), '
        'black_user_id = COALESCE(black_user_id, CAST(@black AS uuid)), '
        'winner = COALESCE(winner, @winner), '
        'reason = COALESCE(reason, @reason), '
        'rated = (rated OR @rated) '
        'WHERE id = @id',
      ),
      parameters: {
        'id': gameId,
        'white': whiteId,
        'black': blackId,
        'winner': winner ?? 'draw',
        'reason': reason,
        'rated': rated,
      },
    );

    // Mark this side reported.
    await _conn.execute(
      Sql.named(
        isWhite
            ? 'UPDATE games SET white_reported = TRUE WHERE id = @id'
            : 'UPDATE games SET black_reported = TRUE WHERE id = @id',
      ),
      parameters: {'id': gameId},
    );

    await recordAbilityUsage(userId: userId, abilities: abilities);

    // Elo once both sides are known accounts and not yet applied.
    await _maybeApplyElo(gameId);

    // Bump games_played once per user per game (using reported flag path).
    await _bumpGamesPlayedOnce(gameId: gameId, userId: userId, isWhite: isWhite);

    final user = await findById(userId);
    if (user == null) return {};
    return profileJson(user);
  }

  Future<void> _bumpGamesPlayedOnce({
    required String gameId,
    required String userId,
    required bool isWhite,
  }) async {
    // Use a side-table-less approach: only increment when this is first report
    // tracked via white_reported/black_reported already set — we increment
    // when transitioning. Safer: check a games_played_bump column… Keep simple:
    // increment if user's games_played hasn't been counted — store in games.
    // Simpler approach: always update games_played = (select count from games).
    final result = await _conn.execute(
      Sql.named(
        'SELECT COUNT(*)::int FROM games '
        'WHERE white_user_id = @id::uuid OR black_user_id = @id::uuid',
      ),
      parameters: {'id': userId},
    );
    final count = result.first[0] as int? ?? 0;
    await _conn.execute(
      Sql.named(
        'UPDATE users SET games_played = @c WHERE id = @id::uuid',
      ),
      parameters: {'id': userId, 'c': count},
    );
  }

  Future<void> _maybeApplyElo(String gameId) async {
    final result = await _conn.execute(
      Sql.named(
        'SELECT white_user_id::text, black_user_id::text, winner, '
        'rated, elo_applied, white_rating_before, black_rating_before '
        'FROM games WHERE id = @id LIMIT 1',
      ),
      parameters: {'id': gameId},
    );
    if (result.isEmpty) return;
    final row = result.first;
    final whiteId = row[0] as String?;
    final blackId = row[1] as String?;
    final winner = row[2] as String? ?? 'draw';
    final rated = row[3] as bool? ?? false;
    final eloApplied = row[4] as bool? ?? false;
    if (!rated || eloApplied || whiteId == null || blackId == null) return;

    final white = await findById(whiteId);
    final black = await findById(blackId);
    if (white == null || black == null) return;

    final whiteScore = winner == 'white'
        ? 1.0
        : winner == 'black'
            ? 0.0
            : 0.5;
    final blackScore = 1.0 - whiteScore;

    final whiteAfter = Elo.nextRating(
      rating: white.rating,
      opponentRating: black.rating,
      score: whiteScore,
      gamesPlayed: white.gamesPlayed,
    );
    final blackAfter = Elo.nextRating(
      rating: black.rating,
      opponentRating: white.rating,
      score: blackScore,
      gamesPlayed: black.gamesPlayed,
    );

    await _conn.execute(
      Sql.named(
        'UPDATE games SET '
        'white_rating_before = @wb, black_rating_before = @bb, '
        'white_rating_after = @wa, black_rating_after = @ba, '
        'elo_applied = TRUE WHERE id = @id AND elo_applied = FALSE',
      ),
      parameters: {
        'id': gameId,
        'wb': white.rating,
        'bb': black.rating,
        'wa': whiteAfter,
        'ba': blackAfter,
      },
    );

    await _conn.execute(
      Sql.named('UPDATE users SET rating = @r WHERE id = @id::uuid'),
      parameters: {'id': whiteId, 'r': whiteAfter},
    );
    await _conn.execute(
      Sql.named('UPDATE users SET rating = @r WHERE id = @id::uuid'),
      parameters: {'id': blackId, 'r': blackAfter},
    );
  }

  Future<List<HistoryEntry>> historyFor(String userId, {int limit = 30}) async {
    final result = await _conn.execute(
      Sql.named('''
        SELECT g.id,
          CASE WHEN g.white_user_id = @id::uuid THEN 'white' ELSE 'black' END AS color,
          CASE
            WHEN g.winner = 'draw' THEN 'draw'
            WHEN (g.white_user_id = @id::uuid AND g.winner = 'white')
              OR (g.black_user_id = @id::uuid AND g.winner = 'black') THEN 'win'
            ELSE 'loss'
          END AS result,
          g.rated,
          CASE WHEN g.white_user_id = @id::uuid THEN g.white_rating_before ELSE g.black_rating_before END,
          CASE WHEN g.white_user_id = @id::uuid THEN g.white_rating_after ELSE g.black_rating_after END,
          g.created_at,
          g.reason,
          CASE
            WHEN g.white_user_id = @id::uuid THEN COALESCE(bu.username, 'Anonymous')
            ELSE COALESCE(wu.username, 'Anonymous')
          END AS opponent
        FROM games g
        LEFT JOIN users wu ON wu.id = g.white_user_id
        LEFT JOIN users bu ON bu.id = g.black_user_id
        WHERE g.white_user_id = @id::uuid OR g.black_user_id = @id::uuid
        ORDER BY g.created_at DESC
        LIMIT @limit
      '''),
      parameters: {'id': userId, 'limit': limit},
    );

    return [
      for (final row in result)
        HistoryEntry(
          gameId: row[0]! as String,
          color: row[1]! as String,
          result: row[2]! as String,
          rated: row[3] as bool? ?? false,
          ratingBefore: row[4] as int?,
          ratingAfter: row[5] as int?,
          createdAt: row[6]! as DateTime,
          reason: row[7] as String?,
          opponentName: row[8]! as String,
        ),
    ];
  }
}
