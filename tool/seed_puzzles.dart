// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

/// Seeds puzzles from assets into Postgres via server upsert HTTP — or prints SQL.
/// Usage: dart run tool/seed_puzzles.dart
void main() {
  final file = File('assets/puzzles/puzzles.json');
  final list = jsonDecode(file.readAsStringSync()) as List;
  final out = StringBuffer();
  for (final raw in list) {
    final p = Map<String, dynamic>.from(raw as Map);
    final id = p['id'];
    final setup = jsonEncode(p);
    final goal = p['goal'] ?? 'checkmate';
    final themes = <String>[
      if (p['hintAbility'] != null) '${p['hintAbility']}',
      '$goal',
    ];
    final themesSql = themes.map((t) => "'${t.replaceAll("'", "''")}'").join(',');
    out.writeln(
      "INSERT INTO puzzles (id, setup_json, goal, themes, title_ru, title_en) "
      "VALUES ('$id', '$setup'::jsonb, '$goal', ARRAY[$themesSql], "
      "'${(p['titleRu'] ?? id).toString().replaceAll("'", "''")}', "
      "'${(p['titleEn'] ?? id).toString().replaceAll("'", "''")}') "
      "ON CONFLICT (id) DO UPDATE SET setup_json = EXCLUDED.setup_json;",
    );
  }
  File('tool/seed_puzzles.sql').writeAsStringSync(out.toString());
  print('Wrote tool/seed_puzzles.sql (${list.length} puzzles)');
}
