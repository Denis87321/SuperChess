import 'package:flutter/services.dart';

import 'puzzle_models.dart';

const puzzlesAssetPath = 'assets/puzzles/puzzles.json';

Future<List<PuzzleDefinition>> loadPuzzlePack() async {
  final raw = await rootBundle.loadString(puzzlesAssetPath);
  return parsePuzzlePack(raw);
}
