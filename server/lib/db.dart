import 'dart:convert';
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
    this.reasonDetail,
    this.hasReplay = false,
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
  final String? reasonDetail;
  final bool hasReplay;
}

class RivalryEntry {
  RivalryEntry({
    required this.opponentId,
    required this.opponentName,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.lastPlayed,
  });

  final String opponentId;
  final String opponentName;
  final int wins;
  final int losses;
  final int draws;
  final DateTime lastPlayed;
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
    await _conn.execute('''
      CREATE TABLE IF NOT EXISTS rivalries (
        user_low UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        user_high UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        low_wins INT NOT NULL DEFAULT 0,
        high_wins INT NOT NULL DEFAULT 0,
        draws INT NOT NULL DEFAULT 0,
        last_played TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        PRIMARY KEY (user_low, user_high),
        CHECK (user_low < user_high)
      );
    ''');
    await _conn.execute('''
      CREATE TABLE IF NOT EXISTS match_replays (
        game_id TEXT PRIMARY KEY,
        white_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
        black_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
        winner TEXT,
        reason TEXT,
        reason_detail TEXT,
        white_mods JSONB NOT NULL DEFAULT '[]'::jsonb,
        black_mods JSONB NOT NULL DEFAULT '[]'::jsonb,
        plies JSONB NOT NULL DEFAULT '[]'::jsonb,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    ''');
    await _conn.execute(
      'ALTER TABLE games ADD COLUMN IF NOT EXISTS reason_detail TEXT;',
    );
    await _conn.execute(
      'ALTER TABLE games ADD COLUMN IF NOT EXISTS rivalry_applied BOOLEAN NOT NULL DEFAULT FALSE;',
    );
    await _conn.execute('''
      CREATE TABLE IF NOT EXISTS friendships (
        user_low UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        user_high UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        requester_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        status TEXT NOT NULL CHECK (status IN ('pending','accepted')),
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        PRIMARY KEY (user_low, user_high),
        CHECK (user_low < user_high)
      );
    ''');

    await _conn.execute(
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS bio TEXT;',
    );
    await _conn.execute(
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS country TEXT;',
    );
    await _conn.execute(
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS avatar_url TEXT;',
    );
    await _conn.execute(
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS last_seen_at TIMESTAMPTZ;',
    );

    await _conn.execute('''
      CREATE TABLE IF NOT EXISTS user_ratings (
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        bucket TEXT NOT NULL,
        rating INT NOT NULL DEFAULT 1500,
        games INT NOT NULL DEFAULT 0,
        PRIMARY KEY (user_id, bucket)
      );
    ''');
    await _conn.execute('''
      INSERT INTO user_ratings (user_id, bucket, rating, games)
      SELECT id, 'blitz', rating, 0
      FROM users u
      WHERE NOT EXISTS (
        SELECT 1 FROM user_ratings ur
        WHERE ur.user_id = u.id AND ur.bucket = 'blitz'
      );
    ''');

    await _conn.execute('''
      CREATE TABLE IF NOT EXISTS follows (
        follower_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        followee_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        PRIMARY KEY (follower_id, followee_id),
        CHECK (follower_id <> followee_id)
      );
    ''');

    await _conn.execute('''
      CREATE TABLE IF NOT EXISTS friend_messages (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        from_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        to_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        body TEXT NOT NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        read_at TIMESTAMPTZ
      );
    ''');

    await _conn.execute(
      'ALTER TABLE games ADD COLUMN IF NOT EXISTS pgn TEXT;',
    );
    await _conn.execute(
      'ALTER TABLE games ADD COLUMN IF NOT EXISTS time_control TEXT;',
    );
    await _conn.execute(
      'ALTER TABLE games ADD COLUMN IF NOT EXISTS analysis_json JSONB;',
    );
    await _conn.execute(
      'ALTER TABLE games ADD COLUMN IF NOT EXISTS analysis_status TEXT;',
    );

    await _conn.execute(
      'ALTER TABLE match_replays ADD COLUMN IF NOT EXISTS pgn TEXT;',
    );

    await _conn.execute('''
      CREATE TABLE IF NOT EXISTS puzzles (
        id TEXT PRIMARY KEY,
        setup_json JSONB NOT NULL,
        goal TEXT,
        themes TEXT[] NOT NULL DEFAULT '{}',
        rating INT NOT NULL DEFAULT 1500,
        plays INT NOT NULL DEFAULT 0,
        successes INT NOT NULL DEFAULT 0,
        title_ru TEXT,
        title_en TEXT
      );
    ''');

    await _conn.execute('''
      CREATE TABLE IF NOT EXISTS puzzle_attempts (
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        puzzle_id TEXT NOT NULL REFERENCES puzzles(id) ON DELETE CASCADE,
        solved BOOLEAN NOT NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    ''');

    await _conn.execute('''
      CREATE TABLE IF NOT EXISTS user_puzzle_rating (
        user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
        rating INT NOT NULL DEFAULT 1500,
        streak INT NOT NULL DEFAULT 0,
        last_day DATE
      );
    ''');

    await _conn.execute('''
      CREATE TABLE IF NOT EXISTS analysis_jobs (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        game_id TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        finished_at TIMESTAMPTZ,
        error TEXT
      );
    ''');

    await _conn.execute('''
      CREATE TABLE IF NOT EXISTS clubs (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        name TEXT NOT NULL UNIQUE,
        description TEXT,
        owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    ''');

    await _conn.execute('''
      CREATE TABLE IF NOT EXISTS club_members (
        club_id UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        role TEXT NOT NULL DEFAULT 'member',
        PRIMARY KEY (club_id, user_id)
      );
    ''');

    await _conn.execute('''
      CREATE TABLE IF NOT EXISTS forum_categories (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        club_id UUID REFERENCES clubs(id) ON DELETE CASCADE,
        title TEXT NOT NULL,
        slug TEXT NOT NULL UNIQUE
      );
    ''');

    await _conn.execute('''
      CREATE TABLE IF NOT EXISTS forum_topics (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        category_id UUID NOT NULL REFERENCES forum_categories(id) ON DELETE CASCADE,
        author_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        title TEXT NOT NULL,
        pinned BOOLEAN NOT NULL DEFAULT FALSE,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    ''');

    await _conn.execute('''
      CREATE TABLE IF NOT EXISTS forum_posts (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        topic_id UUID NOT NULL REFERENCES forum_topics(id) ON DELETE CASCADE,
        author_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        body TEXT NOT NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    ''');

    await _conn.execute('''
      CREATE TABLE IF NOT EXISTS user_devices (
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        token TEXT NOT NULL,
        platform TEXT,
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        PRIMARY KEY (user_id, token)
      );
    ''');

    await _conn.execute('''
      CREATE TABLE IF NOT EXISTS fairplay_samples (
        id BIGSERIAL PRIMARY KEY,
        game_id TEXT NOT NULL,
        user_id UUID REFERENCES users(id) ON DELETE SET NULL,
        color TEXT NOT NULL,
        fen TEXT NOT NULL,
        played_uci TEXT NOT NULL,
        best_uci TEXT NOT NULL,
        matched BOOLEAN NOT NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    ''');
    await _conn.execute(
      'CREATE INDEX IF NOT EXISTS fairplay_samples_game_idx '
      'ON fairplay_samples (game_id);',
    );

    await _conn.execute('''
      CREATE TABLE IF NOT EXISTS fairplay_flags (
        game_id TEXT NOT NULL,
        color TEXT NOT NULL,
        user_id UUID REFERENCES users(id) ON DELETE SET NULL,
        match_rate DOUBLE PRECISION NOT NULL,
        samples INT NOT NULL,
        flagged BOOLEAN NOT NULL DEFAULT FALSE,
        detail TEXT,
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        PRIMARY KEY (game_id, color)
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
    String? reasonDetail,
    required String? opponentUserId,
    required String opponentName,
    required List<String> abilities,
    List<String>? opponentAbilities,
    List<Map<String, dynamic>>? plies,
  }) async {
    final rated = opponentUserId != null;
    final isWhite = color == 'white';
    final whiteId = isWhite ? userId : opponentUserId;
    final blackId = isWhite ? opponentUserId : userId;

    await _conn.execute(
      Sql.named(
        'INSERT INTO games (id, white_user_id, black_user_id, winner, reason, reason_detail, rated) '
        'VALUES ('
        '@id, '
        'CAST(@white AS uuid), '
        'CAST(@black AS uuid), '
        '@winner, @reason, @detail, @rated'
        ') ON CONFLICT (id) DO NOTHING',
      ),
      parameters: {
        'id': gameId,
        'white': whiteId,
        'black': blackId,
        'winner': winner ?? 'draw',
        'reason': reason,
        'detail': reasonDetail,
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
        'reason_detail = COALESCE(reason_detail, @detail), '
        'rated = (rated OR @rated) '
        'WHERE id = @id',
      ),
      parameters: {
        'id': gameId,
        'white': whiteId,
        'black': blackId,
        'winner': winner ?? 'draw',
        'reason': reason,
        'detail': reasonDetail,
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

    if (opponentUserId != null) {
      await _recordRivalry(
        gameId: gameId,
        userId: userId,
        opponentUserId: opponentUserId,
      );
    }

    await _saveMatchReplay(
      gameId: gameId,
      whiteUserId: whiteId,
      blackUserId: blackId,
      winner: winner ?? 'draw',
      reason: reason,
      reasonDetail: reasonDetail,
      whiteMods: isWhite ? abilities : (opponentAbilities ?? const []),
      blackMods: isWhite ? (opponentAbilities ?? const []) : abilities,
      plies: plies,
    );

    // Bump games_played once per user per game (using reported flag path).
    await _bumpGamesPlayedOnce(gameId: gameId, userId: userId, isWhite: isWhite);

    final user = await findById(userId);
    if (user == null) return {};
    return profileJson(user);
  }

  Future<void> _recordRivalry({
    required String gameId,
    required String userId,
    required String opponentUserId,
  }) async {
    final low = userId.compareTo(opponentUserId) < 0 ? userId : opponentUserId;
    final high = low == userId ? opponentUserId : userId;
    await _conn.execute(
      Sql.named(
        'INSERT INTO rivalries (user_low, user_high) '
        'VALUES (@low::uuid, @high::uuid) ON CONFLICT DO NOTHING',
      ),
      parameters: {'low': low, 'high': high},
    );

    final applied = await _conn.execute(
      Sql.named(
        'UPDATE games SET rivalry_applied = TRUE '
        'WHERE id = @id AND rivalry_applied = FALSE '
        'AND white_user_id IS NOT NULL AND black_user_id IS NOT NULL '
        'RETURNING white_user_id::text, black_user_id::text, winner',
      ),
      parameters: {'id': gameId},
    );
    if (applied.isEmpty) return;

    final row = applied.first;
    final wId = row[0] as String?;
    final bId = row[1] as String?;
    final w = row[2] as String? ?? 'draw';

    if (w == 'draw') {
      await _conn.execute(
        Sql.named(
          'UPDATE rivalries SET draws = draws + 1, last_played = NOW() '
          'WHERE user_low = @low::uuid AND user_high = @high::uuid',
        ),
        parameters: {'low': low, 'high': high},
      );
      return;
    }

    final winnerId = w == 'white' ? wId : bId;
    if (winnerId == low) {
      await _conn.execute(
        Sql.named(
          'UPDATE rivalries SET low_wins = low_wins + 1, last_played = NOW() '
          'WHERE user_low = @low::uuid AND user_high = @high::uuid',
        ),
        parameters: {'low': low, 'high': high},
      );
    } else if (winnerId == high) {
      await _conn.execute(
        Sql.named(
          'UPDATE rivalries SET high_wins = high_wins + 1, last_played = NOW() '
          'WHERE user_low = @low::uuid AND user_high = @high::uuid',
        ),
        parameters: {'low': low, 'high': high},
      );
    }
  }

  Future<void> _saveMatchReplay({
    required String gameId,
    required String? whiteUserId,
    required String? blackUserId,
    required String winner,
    required String? reason,
    required String? reasonDetail,
    required List<String> whiteMods,
    required List<String> blackMods,
    required List<Map<String, dynamic>>? plies,
  }) async {
    if (whiteUserId == null && blackUserId == null) return;
    if (plies == null) return;

    await _conn.execute(
      Sql.named(
        'INSERT INTO match_replays ('
        'game_id, white_user_id, black_user_id, winner, reason, reason_detail, '
        'white_mods, black_mods, plies'
        ') VALUES ('
        '@id, CAST(@white AS uuid), CAST(@black AS uuid), '
        '@winner, @reason, @detail, '
        '@wm::jsonb, @bm::jsonb, @plies::jsonb'
        ') ON CONFLICT (game_id) DO UPDATE SET '
        'plies = CASE WHEN jsonb_array_length(EXCLUDED.plies) > jsonb_array_length(match_replays.plies) '
        'THEN EXCLUDED.plies ELSE match_replays.plies END, '
        'white_mods = CASE WHEN jsonb_array_length(EXCLUDED.white_mods) > jsonb_array_length(match_replays.white_mods) '
        'THEN EXCLUDED.white_mods ELSE match_replays.white_mods END, '
        'black_mods = CASE WHEN jsonb_array_length(EXCLUDED.black_mods) > jsonb_array_length(match_replays.black_mods) '
        'THEN EXCLUDED.black_mods ELSE match_replays.black_mods END, '
        'reason_detail = COALESCE(match_replays.reason_detail, EXCLUDED.reason_detail)',
      ),
      parameters: {
        'id': gameId,
        'white': whiteUserId,
        'black': blackUserId,
        'winner': winner,
        'reason': reason,
        'detail': reasonDetail,
        'wm': jsonEncode(whiteMods),
        'bm': jsonEncode(blackMods),
        'plies': jsonEncode(plies),
      },
    );

    for (final uid in [whiteUserId, blackUserId]) {
      if (uid == null) continue;
      await _conn.execute(
        Sql.named('''
          DELETE FROM match_replays
          WHERE game_id IN (
            SELECT game_id FROM match_replays
            WHERE white_user_id = @id::uuid OR black_user_id = @id::uuid
            ORDER BY created_at DESC
            OFFSET 20
          )
        '''),
        parameters: {'id': uid},
      );
    }
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
          g.reason_detail,
          CASE
            WHEN g.white_user_id = @id::uuid THEN COALESCE(bu.username, 'Anonymous')
            ELSE COALESCE(wu.username, 'Anonymous')
          END AS opponent,
          EXISTS(SELECT 1 FROM match_replays mr WHERE mr.game_id = g.id) AS has_replay
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
          reasonDetail: row[8] as String?,
          opponentName: row[9]! as String,
          hasReplay: row[10] as bool? ?? false,
        ),
    ];
  }

  Future<List<RivalryEntry>> rivalriesFor(String userId, {int limit = 50}) async {
    final result = await _conn.execute(
      Sql.named('''
        SELECT
          CASE WHEN r.user_low = @id::uuid THEN r.user_high ELSE r.user_low END AS opp_id,
          u.username,
          CASE WHEN r.user_low = @id::uuid THEN r.low_wins ELSE r.high_wins END AS wins,
          CASE WHEN r.user_low = @id::uuid THEN r.high_wins ELSE r.low_wins END AS losses,
          r.draws,
          r.last_played
        FROM rivalries r
        JOIN users u ON u.id = CASE
          WHEN r.user_low = @id::uuid THEN r.user_high ELSE r.user_low END
        WHERE r.user_low = @id::uuid OR r.user_high = @id::uuid
        ORDER BY r.last_played DESC
        LIMIT @limit
      '''),
      parameters: {'id': userId, 'limit': limit},
    );
    return [
      for (final row in result)
        RivalryEntry(
          opponentId: row[0]! as String,
          opponentName: row[1]! as String,
          wins: row[2] as int? ?? 0,
          losses: row[3] as int? ?? 0,
          draws: row[4] as int? ?? 0,
          lastPlayed: row[5]! as DateTime,
        ),
    ];
  }

  Future<Map<String, dynamic>?> matchReplayFor({
    required String userId,
    required String gameId,
  }) async {
    final result = await _conn.execute(
      Sql.named('''
        SELECT mr.game_id, mr.winner, mr.reason, mr.reason_detail,
          mr.white_mods, mr.black_mods, mr.plies, mr.created_at,
          wu.username, bu.username,
          mr.white_user_id::text, mr.black_user_id::text
        FROM match_replays mr
        LEFT JOIN users wu ON wu.id = mr.white_user_id
        LEFT JOIN users bu ON bu.id = mr.black_user_id
        WHERE mr.game_id = @gid
          AND (mr.white_user_id = @id::uuid OR mr.black_user_id = @id::uuid)
        LIMIT 1
      '''),
      parameters: {'gid': gameId, 'id': userId},
    );
    if (result.isEmpty) return null;
    final row = result.first;
    return {
      'gameId': row[0],
      'winner': row[1],
      'reason': row[2],
      'reasonDetail': row[3],
      'whiteMods': row[4],
      'blackMods': row[5],
      'plies': row[6],
      'createdAt': (row[7] as DateTime).toUtc().toIso8601String(),
      'whiteName': row[8] ?? 'Anonymous',
      'blackName': row[9] ?? 'Anonymous',
      'whiteUserId': row[10],
      'blackUserId': row[11],
    };
  }

  Future<List<String>> listAbilitiesUsed(String userId) async {
    final result = await _conn.execute(
      Sql.named(
        'SELECT ability FROM user_ability_usage '
        'WHERE user_id = @id::uuid ORDER BY ability',
      ),
      parameters: {'id': userId},
    );
    return [for (final row in result) row[0]! as String];
  }

  Future<List<Map<String, dynamic>>> searchUsers(
    String query,
    String excludeUserId, {
    int limit = 20,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final result = await _conn.execute(
      Sql.named('''
        SELECT id::text, username, rating
        FROM users
        WHERE username_lower LIKE @q
          AND id <> @exclude::uuid
        ORDER BY username_lower
        LIMIT @limit
      '''),
      parameters: {
        'q': '${q.toLowerCase()}%',
        'exclude': excludeUserId,
        'limit': limit.clamp(1, 50),
      },
    );
    return [
      for (final row in result)
        {
          'id': row[0]! as String,
          'username': row[1]! as String,
          'rating': row[2] as int? ?? 1500,
        },
    ];
  }

  Future<List<Map<String, dynamic>>> listFriends(String userId) async {
    final result = await _conn.execute(
      Sql.named('''
        SELECT u.id::text, u.username, u.rating
        FROM friendships f
        JOIN users u ON u.id = CASE
          WHEN f.user_low = @id::uuid THEN f.user_high ELSE f.user_low END
        WHERE (f.user_low = @id::uuid OR f.user_high = @id::uuid)
          AND f.status = 'accepted'
        ORDER BY u.username_lower
      '''),
      parameters: {'id': userId},
    );
    return [
      for (final row in result)
        {
          'id': row[0]! as String,
          'username': row[1]! as String,
          'rating': row[2] as int? ?? 1500,
        },
    ];
  }

  Future<List<Map<String, dynamic>>> listPendingIncoming(String userId) async {
    final result = await _conn.execute(
      Sql.named('''
        SELECT u.id::text, u.username, u.rating
        FROM friendships f
        JOIN users u ON u.id = f.requester_id
        WHERE (f.user_low = @id::uuid OR f.user_high = @id::uuid)
          AND f.status = 'pending'
          AND f.requester_id <> @id::uuid
        ORDER BY f.created_at DESC
      '''),
      parameters: {'id': userId},
    );
    return [
      for (final row in result)
        {
          'id': row[0]! as String,
          'username': row[1]! as String,
          'rating': row[2] as int? ?? 1500,
        },
    ];
  }

  Future<List<Map<String, dynamic>>> listPendingOutgoing(String userId) async {
    final result = await _conn.execute(
      Sql.named('''
        SELECT u.id::text, u.username, u.rating
        FROM friendships f
        JOIN users u ON u.id = CASE
          WHEN f.user_low = @id::uuid THEN f.user_high ELSE f.user_low END
        WHERE (f.user_low = @id::uuid OR f.user_high = @id::uuid)
          AND f.status = 'pending'
          AND f.requester_id = @id::uuid
        ORDER BY f.created_at DESC
      '''),
      parameters: {'id': userId},
    );
    return [
      for (final row in result)
        {
          'id': row[0]! as String,
          'username': row[1]! as String,
          'rating': row[2] as int? ?? 1500,
        },
    ];
  }

  /// Returns `{ok: true}` or `{error: String, status: int}`.
  Future<Map<String, dynamic>> requestFriend(
    String fromId,
    String toUsername,
  ) async {
    final target = await findByUsername(toUsername.trim());
    if (target == null) {
      return {'error': 'User not found', 'status': 404};
    }
    if (target.id == fromId) {
      return {'error': 'Cannot friend yourself', 'status': 400};
    }

    final low = fromId.compareTo(target.id) < 0 ? fromId : target.id;
    final high = low == fromId ? target.id : fromId;

    final existing = await _conn.execute(
      Sql.named(
        'SELECT status, requester_id::text FROM friendships '
        'WHERE user_low = @low::uuid AND user_high = @high::uuid LIMIT 1',
      ),
      parameters: {'low': low, 'high': high},
    );
    if (existing.isNotEmpty) {
      final status = existing.first[0] as String? ?? '';
      final requesterId = existing.first[1] as String? ?? '';
      if (status == 'accepted') {
        return {'error': 'Already friends', 'status': 409};
      }
      if (status == 'pending') {
        if (requesterId == fromId) {
          return {'error': 'Request already sent', 'status': 409};
        }
        // Incoming pending request from the other user — auto-accept.
        await _conn.execute(
          Sql.named(
            'UPDATE friendships SET status = \'accepted\' '
            'WHERE user_low = @low::uuid AND user_high = @high::uuid '
            'AND status = \'pending\'',
          ),
          parameters: {'low': low, 'high': high},
        );
        return {'ok': true, 'accepted': true};
      }
    }

    try {
      await _conn.execute(
        Sql.named(
          'INSERT INTO friendships (user_low, user_high, requester_id, status) '
          'VALUES (@low::uuid, @high::uuid, @req::uuid, \'pending\')',
        ),
        parameters: {'low': low, 'high': high, 'req': fromId},
      );
      return {'ok': true};
    } on ServerException catch (e) {
      if (e.code == '23505') {
        return {'error': 'Request already sent', 'status': 409};
      }
      rethrow;
    }
  }

  /// Returns `{ok: true}` or `{error: String, status: int}`.
  Future<Map<String, dynamic>> respondFriend(
    String userId,
    String otherUserId, {
    required bool accept,
  }) async {
    if (userId == otherUserId) {
      return {'error': 'Invalid user', 'status': 400};
    }

    final low = userId.compareTo(otherUserId) < 0 ? userId : otherUserId;
    final high = low == userId ? otherUserId : userId;

    final existing = await _conn.execute(
      Sql.named(
        'SELECT status, requester_id::text FROM friendships '
        'WHERE user_low = @low::uuid AND user_high = @high::uuid LIMIT 1',
      ),
      parameters: {'low': low, 'high': high},
    );
    if (existing.isEmpty) {
      return {'error': 'Request not found', 'status': 404};
    }
    final status = existing.first[0] as String? ?? '';
    final requesterId = existing.first[1] as String? ?? '';
    if (status != 'pending') {
      return {'error': 'No pending request', 'status': 409};
    }
    if (requesterId == userId) {
      return {'error': 'Cannot respond to your own request', 'status': 400};
    }

    if (accept) {
      await _conn.execute(
        Sql.named(
          'UPDATE friendships SET status = \'accepted\' '
          'WHERE user_low = @low::uuid AND user_high = @high::uuid '
          'AND status = \'pending\'',
        ),
        parameters: {'low': low, 'high': high},
      );
    } else {
      await _conn.execute(
        Sql.named(
          'DELETE FROM friendships '
          'WHERE user_low = @low::uuid AND user_high = @high::uuid '
          'AND status = \'pending\'',
        ),
        parameters: {'low': low, 'high': high},
      );
    }
    return {'ok': true};
  }

  static const _ratingBuckets = ['bullet', 'blitz', 'rapid'];

  Future<void> ensureUserRatings(String userId) async {
    final user = await findById(userId);
    final base = user?.rating ?? 1500;
    for (final bucket in _ratingBuckets) {
      await _conn.execute(
        Sql.named(
          'INSERT INTO user_ratings (user_id, bucket, rating, games) '
          'VALUES (@id::uuid, @bucket, @rating, 0) '
          'ON CONFLICT (user_id, bucket) DO NOTHING',
        ),
        parameters: {'id': userId, 'bucket': bucket, 'rating': base},
      );
    }
  }

  Future<Map<String, int>> getRatings(String userId) async {
    await ensureUserRatings(userId);
    final result = await _conn.execute(
      Sql.named(
        'SELECT bucket, rating FROM user_ratings WHERE user_id = @id::uuid',
      ),
      parameters: {'id': userId},
    );
    final out = <String, int>{};
    for (final row in result) {
      out[row[0]! as String] = row[1] as int? ?? 1500;
    }
    return out;
  }

  Future<int> ratingForBucket(String userId, String bucket) async {
    await ensureUserRatings(userId);
    final result = await _conn.execute(
      Sql.named(
        'SELECT rating FROM user_ratings '
        'WHERE user_id = @id::uuid AND bucket = @bucket LIMIT 1',
      ),
      parameters: {'id': userId, 'bucket': bucket},
    );
    if (result.isEmpty) return 1500;
    return result.first[0] as int? ?? 1500;
  }

  Future<void> touchPresence(String userId) async {
    await _conn.execute(
      Sql.named(
        'UPDATE users SET last_seen_at = NOW() WHERE id = @id::uuid',
      ),
      parameters: {'id': userId},
    );
  }

  Future<void> updateProfile({
    required String userId,
    String? bio,
    String? country,
    String? avatarUrl,
  }) async {
    await _conn.execute(
      Sql.named('''
        UPDATE users SET
          bio = COALESCE(@bio, bio),
          country = COALESCE(@country, country),
          avatar_url = COALESCE(@avatar, avatar_url)
        WHERE id = @id::uuid
      '''),
      parameters: {
        'id': userId,
        'bio': bio,
        'country': country,
        'avatar': avatarUrl,
      },
    );
  }

  Future<Map<String, dynamic>?> publicProfile(String username) async {
    final result = await _conn.execute(
      Sql.named('''
        SELECT id::text, username, bio, country, avatar_url,
               games_played, last_seen_at
        FROM users
        WHERE username_lower = @lower
        LIMIT 1
      '''),
      parameters: {'lower': username.toLowerCase()},
    );
    if (result.isEmpty) return null;
    final row = result.first;
    final id = row[0]! as String;
    final ratings = await getRatings(id);
    final followers = await _conn.execute(
      Sql.named(
        'SELECT COUNT(*)::int FROM follows WHERE followee_id = @id::uuid',
      ),
      parameters: {'id': id},
    );
    final following = await _conn.execute(
      Sql.named(
        'SELECT COUNT(*)::int FROM follows WHERE follower_id = @id::uuid',
      ),
      parameters: {'id': id},
    );
    final lastSeen = row[6] as DateTime?;
    return {
      'id': id,
      'username': row[1]! as String,
      'bio': row[2] as String?,
      'country': row[3] as String?,
      'avatarUrl': row[4] as String?,
      'ratings': ratings,
      'gamesPlayed': row[5] as int? ?? 0,
      'followers': followers.first[0] as int? ?? 0,
      'following': following.first[0] as int? ?? 0,
      'lastSeenAt': lastSeen?.toUtc().toIso8601String(),
    };
  }

  Future<void> follow(String followerId, String followeeId) async {
    if (followerId == followeeId) return;
    await _conn.execute(
      Sql.named(
        'INSERT INTO follows (follower_id, followee_id) '
        'VALUES (@follower::uuid, @followee::uuid) '
        'ON CONFLICT DO NOTHING',
      ),
      parameters: {'follower': followerId, 'followee': followeeId},
    );
  }

  Future<void> unfollow(String followerId, String followeeId) async {
    await _conn.execute(
      Sql.named(
        'DELETE FROM follows '
        'WHERE follower_id = @follower::uuid AND followee_id = @followee::uuid',
      ),
      parameters: {'follower': followerId, 'followee': followeeId},
    );
  }

  Future<List<Map<String, dynamic>>> listFollowers(String userId) async {
    final result = await _conn.execute(
      Sql.named('''
        SELECT u.id::text, u.username, u.rating
        FROM follows f
        JOIN users u ON u.id = f.follower_id
        WHERE f.followee_id = @id::uuid
        ORDER BY f.created_at DESC
      '''),
      parameters: {'id': userId},
    );
    return [
      for (final row in result)
        {
          'id': row[0]! as String,
          'username': row[1]! as String,
          'rating': row[2] as int? ?? 1500,
        },
    ];
  }

  Future<List<Map<String, dynamic>>> listFollowing(String userId) async {
    final result = await _conn.execute(
      Sql.named('''
        SELECT u.id::text, u.username, u.rating
        FROM follows f
        JOIN users u ON u.id = f.followee_id
        WHERE f.follower_id = @id::uuid
        ORDER BY f.created_at DESC
      '''),
      parameters: {'id': userId},
    );
    return [
      for (final row in result)
        {
          'id': row[0]! as String,
          'username': row[1]! as String,
          'rating': row[2] as int? ?? 1500,
        },
    ];
  }

  Future<Map<String, dynamic>> sendFriendMessage({
    required String fromId,
    required String toId,
    required String body,
  }) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      return {'error': 'Empty message', 'status': 400};
    }
    final result = await _conn.execute(
      Sql.named('''
        INSERT INTO friend_messages (from_id, to_id, body)
        VALUES (@from::uuid, @to::uuid, @body)
        RETURNING id::text, from_id::text, to_id::text, body, created_at, read_at
      '''),
      parameters: {'from': fromId, 'to': toId, 'body': trimmed},
    );
    final row = result.first;
    return {
      'id': row[0]! as String,
      'fromId': row[1]! as String,
      'toId': row[2]! as String,
      'body': row[3]! as String,
      'createdAt': (row[4]! as DateTime).toUtc().toIso8601String(),
      'readAt': (row[5] as DateTime?)?.toUtc().toIso8601String(),
    };
  }

  Future<List<Map<String, dynamic>>> listFriendMessages(
    String userId,
    String otherId, {
    int limit = 50,
  }) async {
    final result = await _conn.execute(
      Sql.named('''
        SELECT id::text, from_id::text, to_id::text, body, created_at, read_at
        FROM friend_messages
        WHERE (from_id = @a::uuid AND to_id = @b::uuid)
           OR (from_id = @b::uuid AND to_id = @a::uuid)
        ORDER BY created_at DESC
        LIMIT @limit
      '''),
      parameters: {
        'a': userId,
        'b': otherId,
        'limit': limit.clamp(1, 200),
      },
    );
    return [
      for (final row in result)
        {
          'id': row[0]! as String,
          'fromId': row[1]! as String,
          'toId': row[2]! as String,
          'body': row[3]! as String,
          'createdAt': (row[4]! as DateTime).toUtc().toIso8601String(),
          'readAt': (row[5] as DateTime?)?.toUtc().toIso8601String(),
        },
    ];
  }

  Future<void> saveGamePgn(String gameId, String pgn) async {
    await _conn.execute(
      Sql.named(
        'UPDATE games SET pgn = @pgn WHERE id = @id',
      ),
      parameters: {'id': gameId, 'pgn': pgn},
    );
    await _conn.execute(
      Sql.named(
        'UPDATE match_replays SET pgn = @pgn WHERE game_id = @id',
      ),
      parameters: {'id': gameId, 'pgn': pgn},
    );
  }

  Future<String?> getGamePgn(String gameId) async {
    final fromGame = await _conn.execute(
      Sql.named('SELECT pgn FROM games WHERE id = @id LIMIT 1'),
      parameters: {'id': gameId},
    );
    if (fromGame.isNotEmpty) {
      final pgn = fromGame.first[0] as String?;
      if (pgn != null && pgn.isNotEmpty) return pgn;
    }
    final fromReplay = await _conn.execute(
      Sql.named('SELECT pgn FROM match_replays WHERE game_id = @id LIMIT 1'),
      parameters: {'id': gameId},
    );
    if (fromReplay.isEmpty) return null;
    return fromReplay.first[0] as String?;
  }

  Future<void> upsertPuzzle({
    required String id,
    required Map<String, dynamic> setupJson,
    String? goal,
    List<String> themes = const [],
    int rating = 1500,
    String? titleRu,
    String? titleEn,
  }) async {
    await _conn.execute(
      Sql.named('''
        INSERT INTO puzzles (
          id, setup_json, goal, themes, rating, title_ru, title_en
        ) VALUES (
          @id, @setup::jsonb, @goal,
          ARRAY(SELECT jsonb_array_elements_text(@themes::jsonb)),
          @rating, @titleRu, @titleEn
        )
        ON CONFLICT (id) DO UPDATE SET
          setup_json = EXCLUDED.setup_json,
          goal = EXCLUDED.goal,
          themes = EXCLUDED.themes,
          rating = EXCLUDED.rating,
          title_ru = EXCLUDED.title_ru,
          title_en = EXCLUDED.title_en
      '''),
      parameters: {
        'id': id,
        'setup': jsonEncode(setupJson),
        'goal': goal,
        'themes': jsonEncode(themes),
        'rating': rating,
        'titleRu': titleRu,
        'titleEn': titleEn,
      },
    );
  }

  Future<Map<String, dynamic>?> nextPuzzle({
    String? userId,
    List<String>? themes,
  }) async {
    final userRating = userId == null
        ? 1500
        : ((await getUserPuzzleRating(userId))['rating'] as int? ?? 1500);
    final themeFilter = themes != null && themes.isNotEmpty;

    final result = await _conn.execute(
      Sql.named('''
        SELECT p.id, p.setup_json, p.goal, p.themes, p.rating,
               p.plays, p.successes, p.title_ru, p.title_en
        FROM puzzles p
        WHERE (
          NOT @hasThemes OR
          p.themes && ARRAY(SELECT jsonb_array_elements_text(@themes::jsonb))
        )
        AND (
          @uid::text IS NULL OR NOT EXISTS (
            SELECT 1 FROM puzzle_attempts a
            WHERE a.user_id = CAST(@uid AS uuid)
              AND a.puzzle_id = p.id
              AND a.solved = TRUE
              AND a.created_at > NOW() - INTERVAL '7 days'
          )
        )
        ORDER BY ABS(p.rating - @rating), p.plays ASC, random()
        LIMIT 1
      '''),
      parameters: {
        'hasThemes': themeFilter,
        'themes': jsonEncode(themes ?? const <String>[]),
        'uid': userId,
        'rating': userRating,
      },
    );
    if (result.isEmpty) return null;
    return _puzzleFromRow(result.first);
  }

  Map<String, dynamic> _puzzleFromRow(ResultRow row) {
    return {
      'id': row[0]! as String,
      'setup': row[1],
      'goal': row[2] as String?,
      'themes': row[3] ?? const <String>[],
      'rating': row[4] as int? ?? 1500,
      'plays': row[5] as int? ?? 0,
      'successes': row[6] as int? ?? 0,
      'titleRu': row[7] as String?,
      'titleEn': row[8] as String?,
    };
  }

  Future<Map<String, dynamic>> recordPuzzleResult({
    required String userId,
    required String puzzleId,
    required bool solved,
  }) async {
    final puzzleRow = await _conn.execute(
      Sql.named(
        'SELECT rating FROM puzzles WHERE id = @id LIMIT 1',
      ),
      parameters: {'id': puzzleId},
    );
    if (puzzleRow.isEmpty) {
      return {'error': 'Puzzle not found', 'status': 404};
    }
    final puzzleRating = puzzleRow.first[0] as int? ?? 1500;

    await _conn.execute(
      Sql.named(
        'INSERT INTO puzzle_attempts (user_id, puzzle_id, solved) '
        'VALUES (@uid::uuid, @pid, @solved)',
      ),
      parameters: {
        'uid': userId,
        'pid': puzzleId,
        'solved': solved,
      },
    );

    await _conn.execute(
      Sql.named(
        'UPDATE puzzles SET '
        'plays = plays + 1, '
        'successes = successes + CASE WHEN @solved THEN 1 ELSE 0 END '
        'WHERE id = @pid',
      ),
      parameters: {'pid': puzzleId, 'solved': solved},
    );

    final current = await getUserPuzzleRating(userId);
    final rating = current['rating'] as int? ?? 1500;
    final streak = current['streak'] as int? ?? 0;
    final next = Elo.nextRating(
      rating: rating,
      opponentRating: puzzleRating,
      score: solved ? 1.0 : 0.0,
      gamesPlayed: (current['playsApprox'] as int?) ?? 0,
    );
    final today = DateTime.now().toUtc();
    final lastDay = current['lastDay'] as String?;
    final todayStr =
        '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';
    final newStreak = !solved
        ? 0
        : (lastDay == todayStr
            ? streak
            : (lastDay == _yesterdayUtc(today) ? streak + 1 : 1));

    await _conn.execute(
      Sql.named('''
        INSERT INTO user_puzzle_rating (user_id, rating, streak, last_day)
        VALUES (@id::uuid, @rating, @streak, @day::date)
        ON CONFLICT (user_id) DO UPDATE SET
          rating = EXCLUDED.rating,
          streak = EXCLUDED.streak,
          last_day = EXCLUDED.last_day
      '''),
      parameters: {
        'id': userId,
        'rating': next,
        'streak': newStreak,
        'day': todayStr,
      },
    );

    return {
      'rating': next,
      'streak': newStreak,
      'solved': solved,
      'puzzleId': puzzleId,
    };
  }

  String _yesterdayUtc(DateTime today) {
    final y = today.subtract(const Duration(days: 1));
    return '${y.year.toString().padLeft(4, '0')}-'
        '${y.month.toString().padLeft(2, '0')}-'
        '${y.day.toString().padLeft(2, '0')}';
  }

  Future<Map<String, dynamic>> getUserPuzzleRating(String userId) async {
    final result = await _conn.execute(
      Sql.named(
        'SELECT rating, streak, last_day '
        'FROM user_puzzle_rating WHERE user_id = @id::uuid LIMIT 1',
      ),
      parameters: {'id': userId},
    );
    if (result.isEmpty) {
      await _conn.execute(
        Sql.named(
          'INSERT INTO user_puzzle_rating (user_id) '
          'VALUES (@id::uuid) ON CONFLICT DO NOTHING',
        ),
        parameters: {'id': userId},
      );
      return {'rating': 1500, 'streak': 0, 'lastDay': null, 'playsApprox': 0};
    }
    final row = result.first;
    final lastDay = row[2];
    String? lastDayStr;
    if (lastDay is DateTime) {
      final d = lastDay.toUtc();
      lastDayStr =
          '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';
    } else if (lastDay != null) {
      lastDayStr = lastDay.toString().split(' ').first;
    }
    final attempts = await _conn.execute(
      Sql.named(
        'SELECT COUNT(*)::int FROM puzzle_attempts WHERE user_id = @id::uuid',
      ),
      parameters: {'id': userId},
    );
    return {
      'rating': row[0] as int? ?? 1500,
      'streak': row[1] as int? ?? 0,
      'lastDay': lastDayStr,
      'playsApprox': attempts.first[0] as int? ?? 0,
    };
  }

  Future<String> enqueueAnalysis(String gameId) async {
    await _conn.execute(
      Sql.named(
        'UPDATE games SET analysis_status = \'pending\' WHERE id = @id',
      ),
      parameters: {'id': gameId},
    );
    final result = await _conn.execute(
      Sql.named('''
        INSERT INTO analysis_jobs (game_id, status)
        VALUES (@gid, 'pending')
        RETURNING id::text
      '''),
      parameters: {'gid': gameId},
    );
    return result.first[0]! as String;
  }

  Future<Map<String, dynamic>?> getAnalysis(String gameId) async {
    final result = await _conn.execute(
      Sql.named('''
        SELECT analysis_json, analysis_status
        FROM games WHERE id = @id LIMIT 1
      '''),
      parameters: {'id': gameId},
    );
    if (result.isEmpty) return null;
    final job = await _conn.execute(
      Sql.named('''
        SELECT id::text, status, created_at, finished_at, error
        FROM analysis_jobs
        WHERE game_id = @id
        ORDER BY created_at DESC
        LIMIT 1
      '''),
      parameters: {'id': gameId},
    );
    return {
      'gameId': gameId,
      'analysis': result.first[0],
      'status': result.first[1] as String? ??
          (job.isEmpty ? null : job.first[1] as String?),
      if (job.isNotEmpty) ...{
        'jobId': job.first[0]! as String,
        'jobStatus': job.first[1] as String?,
        'createdAt': (job.first[2] as DateTime?)?.toUtc().toIso8601String(),
        'finishedAt': (job.first[3] as DateTime?)?.toUtc().toIso8601String(),
        'error': job.first[4] as String?,
      },
    };
  }

  Future<void> setAnalysisResult({
    required String jobId,
    required String gameId,
    Map<String, dynamic>? analysis,
    String status = 'ready',
    String? error,
  }) async {
    await _conn.execute(
      Sql.named('''
        UPDATE analysis_jobs SET
          status = @status,
          finished_at = NOW(),
          error = @error
        WHERE id = @job::uuid
      '''),
      parameters: {
        'job': jobId,
        'status': status,
        'error': error,
      },
    );
    await _conn.execute(
      Sql.named('''
        UPDATE games SET
          analysis_status = @status,
          analysis_json = CASE
            WHEN @hasAnalysis THEN @analysis::jsonb
            ELSE analysis_json
          END
        WHERE id = @gid
      '''),
      parameters: {
        'gid': gameId,
        'status': status,
        'hasAnalysis': analysis != null,
        'analysis': jsonEncode(analysis ?? const <String, dynamic>{}),
      },
    );
  }

  Future<Map<String, dynamic>> createClub({
    required String name,
    required String ownerId,
    String? description,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return {'error': 'Name required', 'status': 400};
    }
    try {
      final result = await _conn.execute(
        Sql.named('''
          INSERT INTO clubs (name, description, owner_id)
          VALUES (@name, @desc, @owner::uuid)
          RETURNING id::text, name, description, owner_id::text, created_at
        '''),
        parameters: {
          'name': trimmed,
          'desc': description,
          'owner': ownerId,
        },
      );
      final row = result.first;
      final clubId = row[0]! as String;
      await _conn.execute(
        Sql.named(
          'INSERT INTO club_members (club_id, user_id, role) '
          'VALUES (@club::uuid, @user::uuid, \'owner\') '
          'ON CONFLICT DO NOTHING',
        ),
        parameters: {'club': clubId, 'user': ownerId},
      );
      return {
        'id': clubId,
        'name': row[1]! as String,
        'description': row[2] as String?,
        'ownerId': row[3]! as String,
        'createdAt': (row[4]! as DateTime).toUtc().toIso8601String(),
      };
    } on ServerException catch (e) {
      if (e.code == '23505') {
        return {'error': 'Club name taken', 'status': 409};
      }
      rethrow;
    }
  }

  Future<void> joinClub(String clubId, String userId, {String role = 'member'}) async {
    await _conn.execute(
      Sql.named(
        'INSERT INTO club_members (club_id, user_id, role) '
        'VALUES (@club::uuid, @user::uuid, @role) '
        'ON CONFLICT DO NOTHING',
      ),
      parameters: {'club': clubId, 'user': userId, 'role': role},
    );
  }

  Future<List<Map<String, dynamic>>> listClubs({int limit = 50}) async {
    final result = await _conn.execute(
      Sql.named('''
        SELECT c.id::text, c.name, c.description, c.owner_id::text, c.created_at,
               COUNT(m.user_id)::int AS members
        FROM clubs c
        LEFT JOIN club_members m ON m.club_id = c.id
        GROUP BY c.id
        ORDER BY c.created_at DESC
        LIMIT @limit
      '''),
      parameters: {'limit': limit.clamp(1, 200)},
    );
    return [
      for (final row in result)
        {
          'id': row[0]! as String,
          'name': row[1]! as String,
          'description': row[2] as String?,
          'ownerId': row[3]! as String,
          'createdAt': (row[4]! as DateTime).toUtc().toIso8601String(),
          'members': row[5] as int? ?? 0,
        },
    ];
  }

  Future<Map<String, dynamic>?> getClub(String clubId) async {
    final result = await _conn.execute(
      Sql.named('''
        SELECT c.id::text, c.name, c.description, c.owner_id::text, c.created_at,
               u.username
        FROM clubs c
        JOIN users u ON u.id = c.owner_id
        WHERE c.id = @id::uuid
        LIMIT 1
      '''),
      parameters: {'id': clubId},
    );
    if (result.isEmpty) return null;
    final row = result.first;
    final members = await _conn.execute(
      Sql.named('''
        SELECT u.id::text, u.username, m.role
        FROM club_members m
        JOIN users u ON u.id = m.user_id
        WHERE m.club_id = @id::uuid
        ORDER BY m.role, u.username_lower
      '''),
      parameters: {'id': clubId},
    );
    return {
      'id': row[0]! as String,
      'name': row[1]! as String,
      'description': row[2] as String?,
      'ownerId': row[3]! as String,
      'createdAt': (row[4]! as DateTime).toUtc().toIso8601String(),
      'ownerName': row[5]! as String,
      'members': [
        for (final m in members)
          {
            'id': m[0]! as String,
            'username': m[1]! as String,
            'role': m[2]! as String,
          },
      ],
    };
  }

  Future<List<Map<String, dynamic>>> listCategories({String? clubId}) async {
    final result = await _conn.execute(
      Sql.named('''
        SELECT id::text, club_id::text, title, slug
        FROM forum_categories
        WHERE (@club::text IS NULL AND club_id IS NULL)
           OR (@club::text IS NOT NULL AND club_id = CAST(@club AS uuid))
        ORDER BY title
      '''),
      parameters: {'club': clubId},
    );
    return [
      for (final row in result)
        {
          'id': row[0]! as String,
          'clubId': row[1] as String?,
          'title': row[2]! as String,
          'slug': row[3]! as String,
        },
    ];
  }

  Future<Map<String, dynamic>> createTopic({
    required String categoryId,
    required String authorId,
    required String title,
    bool pinned = false,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      return {'error': 'Title required', 'status': 400};
    }
    final result = await _conn.execute(
      Sql.named('''
        INSERT INTO forum_topics (category_id, author_id, title, pinned)
        VALUES (@cat::uuid, @author::uuid, @title, @pinned)
        RETURNING id::text, category_id::text, author_id::text, title, pinned, created_at
      '''),
      parameters: {
        'cat': categoryId,
        'author': authorId,
        'title': trimmed,
        'pinned': pinned,
      },
    );
    final row = result.first;
    return {
      'id': row[0]! as String,
      'categoryId': row[1]! as String,
      'authorId': row[2]! as String,
      'title': row[3]! as String,
      'pinned': row[4] as bool? ?? false,
      'createdAt': (row[5]! as DateTime).toUtc().toIso8601String(),
    };
  }

  Future<List<Map<String, dynamic>>> listTopics(String categoryId, {int limit = 50}) async {
    final result = await _conn.execute(
      Sql.named('''
        SELECT t.id::text, t.category_id::text, t.author_id::text,
               t.title, t.pinned, t.created_at, u.username
        FROM forum_topics t
        JOIN users u ON u.id = t.author_id
        WHERE t.category_id = @cat::uuid
        ORDER BY t.pinned DESC, t.created_at DESC
        LIMIT @limit
      '''),
      parameters: {
        'cat': categoryId,
        'limit': limit.clamp(1, 200),
      },
    );
    return [
      for (final row in result)
        {
          'id': row[0]! as String,
          'categoryId': row[1]! as String,
          'authorId': row[2]! as String,
          'title': row[3]! as String,
          'pinned': row[4] as bool? ?? false,
          'createdAt': (row[5]! as DateTime).toUtc().toIso8601String(),
          'authorName': row[6]! as String,
        },
    ];
  }

  Future<Map<String, dynamic>> createPost({
    required String topicId,
    required String authorId,
    required String body,
  }) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      return {'error': 'Body required', 'status': 400};
    }
    final result = await _conn.execute(
      Sql.named('''
        INSERT INTO forum_posts (topic_id, author_id, body)
        VALUES (@topic::uuid, @author::uuid, @body)
        RETURNING id::text, topic_id::text, author_id::text, body, created_at
      '''),
      parameters: {
        'topic': topicId,
        'author': authorId,
        'body': trimmed,
      },
    );
    final row = result.first;
    return {
      'id': row[0]! as String,
      'topicId': row[1]! as String,
      'authorId': row[2]! as String,
      'body': row[3]! as String,
      'createdAt': (row[4]! as DateTime).toUtc().toIso8601String(),
    };
  }

  Future<List<Map<String, dynamic>>> listPosts(String topicId, {int limit = 100}) async {
    final result = await _conn.execute(
      Sql.named('''
        SELECT p.id::text, p.topic_id::text, p.author_id::text,
               p.body, p.created_at, u.username
        FROM forum_posts p
        JOIN users u ON u.id = p.author_id
        WHERE p.topic_id = @topic::uuid
        ORDER BY p.created_at ASC
        LIMIT @limit
      '''),
      parameters: {
        'topic': topicId,
        'limit': limit.clamp(1, 500),
      },
    );
    return [
      for (final row in result)
        {
          'id': row[0]! as String,
          'topicId': row[1]! as String,
          'authorId': row[2]! as String,
          'body': row[3]! as String,
          'createdAt': (row[4]! as DateTime).toUtc().toIso8601String(),
          'authorName': row[5]! as String,
        },
    ];
  }

  Future<void> registerDevice({
    required String userId,
    required String token,
    String? platform,
  }) async {
    final t = token.trim();
    if (t.isEmpty) return;
    await _conn.execute(
      Sql.named('''
        INSERT INTO user_devices (user_id, token, platform, updated_at)
        VALUES (@id::uuid, @token, @platform, NOW())
        ON CONFLICT (user_id, token) DO UPDATE SET
          platform = COALESCE(EXCLUDED.platform, user_devices.platform),
          updated_at = NOW()
      '''),
      parameters: {
        'id': userId,
        'token': t,
        'platform': platform,
      },
    );
  }

  Future<List<Map<String, dynamic>>> devicesForUser(String userId) async {
    final result = await _conn.execute(
      Sql.named('''
        SELECT token, platform, updated_at
        FROM user_devices
        WHERE user_id = @id::uuid
        ORDER BY updated_at DESC
      '''),
      parameters: {'id': userId},
    );
    return [
      for (final row in result)
        {
          'token': row[0]! as String,
          'platform': row[1] as String?,
          'updatedAt': (row[2]! as DateTime).toUtc().toIso8601String(),
        },
    ];
  }

  Future<void> insertFairPlaySample({
    required String gameId,
    String? userId,
    required String color,
    required String fen,
    required String playedUci,
    required String bestUci,
    required bool matched,
  }) async {
    await _conn.execute(
      Sql.named('''
        INSERT INTO fairplay_samples (
          game_id, user_id, color, fen, played_uci, best_uci, matched
        ) VALUES (
          @gameId, @userId::uuid, @color, @fen, @played, @best, @matched
        )
      '''),
      parameters: {
        'gameId': gameId,
        'userId': userId,
        'color': color,
        'fen': fen,
        'played': playedUci,
        'best': bestUci,
        'matched': matched,
      },
    );
  }

  Future<void> upsertFairPlayFlag({
    required String gameId,
    String? userId,
    required String color,
    required double matchRate,
    required int samples,
    String? detail,
    bool flagged = true,
  }) async {
    await _conn.execute(
      Sql.named('''
        INSERT INTO fairplay_flags (
          game_id, color, user_id, match_rate, samples, flagged, detail, updated_at
        ) VALUES (
          @gameId, @color, @userId::uuid, @rate, @samples, @flagged, @detail, NOW()
        )
        ON CONFLICT (game_id, color) DO UPDATE SET
          user_id = COALESCE(EXCLUDED.user_id, fairplay_flags.user_id),
          match_rate = EXCLUDED.match_rate,
          samples = EXCLUDED.samples,
          flagged = EXCLUDED.flagged OR fairplay_flags.flagged,
          detail = COALESCE(EXCLUDED.detail, fairplay_flags.detail),
          updated_at = NOW()
      '''),
      parameters: {
        'gameId': gameId,
        'color': color,
        'userId': userId,
        'rate': matchRate,
        'samples': samples,
        'flagged': flagged,
        'detail': detail,
      },
    );
  }

  Future<List<Map<String, dynamic>>> listFairPlayFlags({int limit = 50}) async {
    final result = await _conn.execute(
      Sql.named('''
        SELECT game_id, color, user_id::text, match_rate, samples, flagged, detail, updated_at
        FROM fairplay_flags
        WHERE flagged = TRUE
        ORDER BY updated_at DESC
        LIMIT @limit
      '''),
      parameters: {'limit': limit},
    );
    return [
      for (final row in result)
        {
          'gameId': row[0]! as String,
          'color': row[1]! as String,
          'userId': row[2] as String?,
          'matchRate': (row[3]! as num).toDouble(),
          'samples': row[4]! as int,
          'flagged': row[5]! as bool,
          'detail': row[6] as String?,
          'updatedAt': (row[7]! as DateTime).toUtc().toIso8601String(),
        },
    ];
  }

  Future<Map<String, dynamic>?> getFairPlayReport(String gameId) async {
    final flags = await _conn.execute(
      Sql.named('''
        SELECT color, user_id::text, match_rate, samples, flagged, detail, updated_at
        FROM fairplay_flags
        WHERE game_id = @gameId
        ORDER BY color
      '''),
      parameters: {'gameId': gameId},
    );
    final samples = await _conn.execute(
      Sql.named('''
        SELECT color, played_uci, best_uci, matched, created_at
        FROM fairplay_samples
        WHERE game_id = @gameId
        ORDER BY id ASC
        LIMIT 200
      '''),
      parameters: {'gameId': gameId},
    );
    if (flags.isEmpty && samples.isEmpty) return null;
    return {
      'gameId': gameId,
      'sides': [
        for (final row in flags)
          {
            'color': row[0]! as String,
            'userId': row[1] as String?,
            'matchRate': (row[2]! as num).toDouble(),
            'samples': row[3]! as int,
            'flagged': row[4]! as bool,
            'detail': row[5] as String?,
            'updatedAt': (row[6]! as DateTime).toUtc().toIso8601String(),
          },
      ],
      'recentSamples': [
        for (final row in samples)
          {
            'color': row[0]! as String,
            'playedUci': row[1]! as String,
            'bestUci': row[2]! as String,
            'matched': row[3]! as bool,
            'at': (row[4]! as DateTime).toUtc().toIso8601String(),
          },
      ],
    };
  }
}
