/// Minimal PGN builder from headers + SAN moves.
String buildPgn({
  required Map<String, String> headers,
  required List<String> sans,
  String result = '*',
}) {
  final buf = StringBuffer();
  final merged = {
    'Event': 'SuperChess',
    'Site': 'SuperChess',
    'Date': _today(),
    'Round': '-',
    'White': '?',
    'Black': '?',
    'Result': result,
    ...headers,
  };
  for (final e in merged.entries) {
    buf.writeln('[${e.key} "${_escape(e.value)}"]');
  }
  buf.writeln();
  for (var i = 0; i < sans.length; i++) {
    if (i.isEven) {
      buf.write('${i ~/ 2 + 1}. ');
    }
    buf.write(sans[i]);
    if (i < sans.length - 1) buf.write(' ');
  }
  if (sans.isNotEmpty) buf.write(' ');
  buf.writeln(result);
  return buf.toString();
}

String _escape(String s) => s.replaceAll('\\', r'\\').replaceAll('"', r'\"');

String _today() {
  final n = DateTime.now().toUtc();
  final m = n.month.toString().padLeft(2, '0');
  final d = n.day.toString().padLeft(2, '0');
  return '${n.year}.$m.$d';
}
