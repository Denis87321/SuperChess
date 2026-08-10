import 'package:flutter/material.dart';

import '../chess/chess_game.dart';
import '../chess/move.dart';
import '../l10n/app_strings.dart';
import '../l10n/models/ability_l10n.dart';
import '../l10n/models/square.dart';
import '../puzzles/puzzle_engine.dart';
import '../puzzles/puzzle_models.dart';
import '../theme/balatro_theme.dart';
import '../widgets/chess_piece_widget.dart';

class PuzzleGameScreen extends StatefulWidget {
  const PuzzleGameScreen({super.key, required this.puzzle});

  final PuzzleDefinition puzzle;

  @override
  State<PuzzleGameScreen> createState() => _PuzzleGameScreenState();
}

class _PuzzleGameScreenState extends State<PuzzleGameScreen> {
  late ChessGame _game;
  Square? _selected;
  List<Move> _moves = const [];
  var _plyCount = 0;
  String? _status;
  var _solved = false;

  @override
  void initState() {
    super.initState();
    _game = gameFromPuzzle(widget.puzzle);
  }

  void _reset() {
    setState(() {
      _game = gameFromPuzzle(widget.puzzle);
      _selected = null;
      _moves = const [];
      _plyCount = 0;
      _status = null;
      _solved = false;
    });
  }

  void _onTapSquare(Square square) {
    if (_solved) return;
    final s = AppStrings.of(context);
    final piece = _game.pieceAt(square);

    if (_selected != null) {
      final move = _moves.cast<Move?>().firstWhere(
        (m) => m!.to == square,
        orElse: () => null,
      );
      if (move != null) {
        final applied = _game.makeMove(move);
        if (applied == null) {
          setState(() {
            _selected = null;
            _moves = const [];
          });
          return;
        }
        setState(() {
          _plyCount += 1;
          _selected = null;
          _moves = const [];
          if (puzzleGoalMet(
            widget.puzzle,
            _game,
            plyCount: _plyCount,
          )) {
            _solved = true;
            _status = s.puzzleSolved;
          } else if (_game.isGameOver) {
            _status = s.puzzleFailed;
          } else if (widget.puzzle.goal != PuzzleGoal.surviveNMoves &&
              _plyCount >= 1) {
            // Single-move puzzles: any non-solving move fails.
            if (widget.puzzle.solution.length <= 1) {
              _status = s.puzzleFailed;
            }
          }
        });
        return;
      }
    }

    if (piece != null && piece.color == _game.turn) {
      setState(() {
        _selected = square;
        _moves = _game.getLegalMoves(from: square);
        _status = null;
      });
    } else {
      setState(() {
        _selected = null;
        _moves = const [];
      });
    }
  }

  void _showHint() {
    final ability = widget.puzzle.hintAbility;
    final s = AppStrings.of(context);
    final locale = Localizations.localeOf(context);
    final text = ability == null
        ? s.puzzleHint
        : '${s.puzzleHint}: ${ability.titleFor(locale)}';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final files = _game.fileCount;
    final ranks = _game.rankCount;
    final targets = {for (final m in _moves) m.to};

    return Scaffold(
      backgroundColor: BalatroTheme.background,
      appBar: AppBar(
        title: Text(
          widget.puzzle.titleFor(s.isRu),
          style: BalatroTheme.titleStyle.copyWith(fontSize: 16),
        ),
        backgroundColor: BalatroTheme.appBar,
        foregroundColor: BalatroTheme.cream,
        actions: [
          IconButton(
            tooltip: s.puzzleHint,
            onPressed: _showHint,
            icon: const Icon(Icons.lightbulb_outline),
          ),
          IconButton(
            onPressed: _reset,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_status != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _status!,
                style: BalatroTheme.titleStyle.copyWith(
                  fontSize: 18,
                  color: _solved ? BalatroTheme.gold : Colors.redAccent,
                ),
              ),
            ),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: files / ranks,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: files,
                  ),
                  itemCount: files * ranks,
                  itemBuilder: (context, index) {
                    final file = index % files;
                    final rank = ranks - 1 - index ~/ files;
                    final square = Square(file, rank);
                    final light = (file + rank).isEven;
                    final piece = _game.pieceAt(square);
                    final selected = _selected == square;
                    final target = targets.contains(square);
                    return GestureDetector(
                      onTap: () => _onTapSquare(square),
                      child: ColoredBox(
                        color: selected
                            ? const Color(0xFFD4A017)
                            : target
                                ? const Color(0xFF8FBC8F)
                                : light
                                    ? const Color(0xFFC8B896)
                                    : const Color(0xFF6B8F71),
                        child: piece == null
                            ? null
                            : ChessPieceWidget(piece: piece, size: 36),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
