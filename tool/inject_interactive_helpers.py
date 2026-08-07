#!/usr/bin/env python3
"""Inject interactive batch-mod helpers into chess_game.dart before GameSnapshot class."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
path = ROOT / "lib/chess/chess_game.dart"
text = path.read_text(encoding="utf-8")

MARKER = "class GameSnapshot {"
if MARKER not in text:
    raise SystemExit("GameSnapshot marker missing")
if "void _beginMultiCellTarget(" in text:
    print("already injected")
    raise SystemExit(0)

HELPERS = r'''
  // ---------------------------------------------------------------------------
  // Interactive batch mods (RPS, multi-cell, tangled, customs, passives)
  // ---------------------------------------------------------------------------

  bool get isAwaitingRps =>
      _rules.rpsSessionActive && !_rules.rpsResolved && _rules.rpsPairIndex != null;

  bool get isAwaitingCustomsPath => _rules.awaitingCustomsPath;

  bool get isAwaitingTangledKeep => _rules.tangledAwaitingKeep;

  bool get isAwaitingSpotlightPromo => _rules.spotlightPromoId != null;

  bool get isAwaitingMultiCell =>
      _rules.multiCellNeeded > 0 &&
      _rules.multiCellAbility != null &&
      _rules.multiCellPicks.length < _rules.multiCellNeeded;

  List<(Square, Square)> get rpsPairs => List<(Square, Square)>.from(_rules.rpsPairs);

  int? get rpsPairIndex => _rules.rpsPairIndex;

  String? get rpsLastA => _rules.rpsLastA;

  String? get rpsLastB => _rules.rpsLastB;

  int get rpsRound => _rules.rpsRound;

  List<List<Square>> get customsPathOptions =>
      _rules.customsPaths.map((p) => List<Square>.from(p)).toList();

  List<Square> get multiCellPicks => List<Square>.from(_rules.multiCellPicks);

  int get multiCellNeeded => _rules.multiCellNeeded;

  GameAbility? get multiCellAbility => _rules.multiCellAbility;

  String? get spotlightPromoPieceId => _rules.spotlightPromoId;

  List<Square> get tangledKeepSquares {
    if (!_rules.tangledAwaitingKeep) return const [];
    final out = <Square>[];
    final a = _pieceById(_rules.tangledKnightBaseId ?? '');
    final b = _pieceById(_rules.tangledCloneId ?? '');
    if (a != null) out.add(a.square);
    if (b != null) out.add(b.square);
    return out;
  }

  void _beginMultiCellTarget({
    required GameAbility ability,
    required String sourceId,
    required PieceColor color,
    required int needed,
  }) {
    _rules.multiCellPicks.clear();
    _rules.multiCellNeeded = needed;
    _rules.multiCellAbility = ability;
    _rules.multiCellSourceId = sourceId;
    _rules.multiCellColor = color;
    _beginAbilityTarget(
      ability: ability,
      sourceId: sourceId,
      color: color,
      selection: AbilityTargetSelection.cell,
      passesTurn: true,
    );
  }

  void _clearMultiCell() {
    _rules.multiCellPicks.clear();
    _rules.multiCellNeeded = 0;
    _rules.multiCellAbility = null;
    _rules.multiCellSourceId = null;
    _rules.multiCellColor = null;
  }

  List<Square> _legalMultiCellSquares() {
    final ability = _rules.multiCellAbility;
    final sourceId = _rules.multiCellSourceId;
    final color = _rules.multiCellColor;
    if (ability == null || color == null) return const [];
    final picked = _rules.multiCellPicks.toSet();
    final out = <Square>[];
    if (ability == GameAbility.knightGallopContract) {
      for (var r = 0; r < _rankCount; r++) {
        for (var f = 0; f < _fileCount; f++) {
          final s = Square(f, r);
          if (!picked.contains(s)) out.add(s);
        }
      }
      return out;
    }
    if (ability == GameAbility.bishopHeretic) {
      final halfMax = color == PieceColor.white ? (_rankCount ~/ 2) - 1 : _rankCount - 1;
      final halfMin = color == PieceColor.white ? 0 : _rankCount ~/ 2;
      for (var r = halfMin; r <= halfMax; r++) {
        for (var f = 0; f < _fileCount; f++) {
          final s = Square(f, r);
          if (picked.contains(s)) continue;
          if (piecesAt(s).isNotEmpty || isBlocked(s)) continue;
          out.add(s);
        }
      }
      return out;
    }
    if (ability == GameAbility.bishopCartographer) {
      final source = _pieceById(sourceId ?? '');
      if (source == null) return const [];
      for (final (df, dr) in const [(-1, -1), (-1, 1), (1, -1), (1, 1)]) {
        var f = source.square.file + df;
        var r = source.square.rank + dr;
        while (f >= 0 && f < _fileCount && r >= 0 && r < _rankCount) {
          final s = Square(f, r);
          if (!picked.contains(s)) out.add(s);
          f += df;
          r += dr;
        }
      }
      return out;
    }
    if (ability == GameAbility.pawnArchivist) {
      final visited = _rules.archivistVisited[sourceId] ?? {};
      for (final s in visited) {
        if (picked.contains(s)) continue;
        if (piecesAt(s).isNotEmpty || isBlocked(s)) continue;
        out.add(s);
      }
      return out;
    }
    return out;
  }

  bool _acceptMultiCellPick(Square square) {
    final ability = _rules.multiCellAbility;
    final sourceId = _rules.multiCellSourceId;
    if (ability == null || sourceId == null) return false;
    if (!_legalMultiCellSquares().contains(square)) return false;
    _rules.multiCellPicks.add(square);
    if (_rules.multiCellPicks.length < _rules.multiCellNeeded) {
      _updateStatus();
      return true;
    }
    final picks = List<Square>.from(_rules.multiCellPicks);
    final color = _rules.multiCellColor ?? PieceColor.white;
    _clearPendingTarget();
    switch (ability) {
      case GameAbility.knightGallopContract:
        _rules.gallopContractRoute[sourceId] = picks;
        _rules.gallopContractProgress[sourceId] = 0;
      case GameAbility.bishopHeretic:
        _applyHereticSplit(sourceId, picks);
      case GameAbility.bishopCartographer:
        _rules.permanentFogReveals.putIfAbsent(color, () => {}).add(picks.first);
      case GameAbility.pawnArchivist:
        _applyArchivistRecall(sourceId, picks.first);
      default:
        break;
    }
    _clearMultiCell();
    _completeSkillChoiceResolution(color, offer: AbilityOffer(
      ability: ability,
      applyMode: AbilityApplyMode.selectFriendlyPiece,
      forColor: color,
    ));
    return true;
  }

  void _applyHereticSplit(String bishopId, List<Square> cells) {
    final ref = _pieceById(bishopId);
    if (ref == null) return;
    final color = ref.piece.color;
    final removed = _takePieceAt(ref.square, ref.index);
    if (removed != null) {
      // Consume bishop without graveyard inheritance noise during sim.
    }
    for (var i = 0; i < cells.length && i < 4; i++) {
      final s = cells[i];
      if (piecesAt(s).isNotEmpty) continue;
      _setPrimary(
        s,
        Piece(
          pieceId: 'heretic-$bishopId-$i',
          type: PieceType.pawn,
          color: color,
          hasMoved: true,
        ),
      );
    }
  }

  void _applyArchivistRecall(String pawnId, Square to) {
    final ref = _pieceById(pawnId);
    if (ref == null) return;
    if (_rules.archivistRecallUsed.contains(pawnId)) return;
    if (piecesAt(to).isNotEmpty) return;
    final piece = ref.piece;
    _takePieceAt(ref.square, ref.index);
    _setPrimary(to, piece);
    _rules.archivistRecallUsed.add(pawnId);
    _rules.archivistRecallArmed.remove(pawnId);
  }

  void _startRpsSession(PieceColor chooser) {
    _rules.rpsPairs
      ..clear()
      ..addAll(_findBlockingPawnPairs());
    if (_rules.rpsPairs.isEmpty) return;
    _rules.rpsSessionActive = true;
    _rules.rpsResolved = false;
    _rules.rpsChooser = chooser;
    _rules.rpsPairIndex = _rules.rpsPairs.length == 1 ? 0 : null;
    _rules.rpsLastA = null;
    _rules.rpsLastB = null;
    _rules.rpsRound = 0;
    if (_rules.rpsPairIndex != null) {
      _runRpsUntilWinner();
    }
  }

  List<(Square, Square)> _findBlockingPawnPairs() {
    final pairs = <(Square, Square)>[];
    for (var file = 0; file < _fileCount; file++) {
      for (var rank = 0; rank < _rankCount - 1; rank++) {
        final a = Square(file, rank);
        final b = Square(file, rank + 1);
        final pa = pieceAt(a);
        final pb = pieceAt(b);
        if (pa == null || pb == null) continue;
        if (pa.type != PieceType.pawn || pb.type != PieceType.pawn) continue;
        if (pa.color == pb.color) continue;
        pairs.add((a, b));
      }
    }
    return pairs;
  }

  bool chooseRpsPair(int index) {
    if (!_rules.rpsSessionActive || _rules.rpsPairIndex != null) return false;
    if (index < 0 || index >= _rules.rpsPairs.length) return false;
    _rules.rpsPairIndex = index;
    _runRpsUntilWinner();
    _updateStatus();
    return true;
  }

  void _runRpsUntilWinner() {
    final idx = _rules.rpsPairIndex;
    if (idx == null || idx < 0 || idx >= _rules.rpsPairs.length) return;
    final (aSq, bSq) = _rules.rpsPairs[idx];
    const gestures = ['rock', 'paper', 'scissors'];
    for (var round = 0; round < 32; round++) {
      final ga = gestures[_random.nextInt(3)];
      final gb = gestures[_random.nextInt(3)];
      _rules.rpsLastA = ga;
      _rules.rpsLastB = gb;
      _rules.rpsRound = round + 1;
      final winner = _rpsWinner(ga, gb);
      if (winner == 0) continue;
      final loserSq = winner > 0 ? bSq : aSq;
      final loser = pieceAt(loserSq);
      if (loser != null) {
        final removed = _takePieceAt(loserSq, 0);
        if (removed != null) _onFinalDeath(removed, loserSq);
      }
      break;
    }
    _rules.rpsResolved = true;
    _rules.rpsSessionActive = false;
    final chooser = _rules.rpsChooser;
    if (chooser != null) {
      _completeSkillChoiceResolution(
        chooser,
        offer: const AbilityOffer(
          ability: GameAbility.pawnRockPaperScissors,
          applyMode: AbilityApplyMode.boardWide,
        ),
      );
    }
  }

  /// Returns 1 if A wins, -1 if B wins, 0 draw.
  int _rpsWinner(String a, String b) {
    if (a == b) return 0;
    if ((a == 'rock' && b == 'scissors') ||
        (a == 'scissors' && b == 'paper') ||
        (a == 'paper' && b == 'rock')) {
      return 1;
    }
    return -1;
  }

  List<(Square from, Square via1, Square via2, Square to)> _knightPathOptions(
    Square from,
    Square to,
  ) {
    final df = to.file - from.file;
    final dr = to.rank - from.rank;
    final adf = df.abs();
    final adr = dr.abs();
    if (!((adf == 1 && adr == 2) || (adf == 2 && adr == 1))) {
      return const [];
    }
    // Two Manhattan 3-step routes (2+1).
    final paths = <(Square, Square, Square, Square)>[];
    if (adf == 2 && adr == 1) {
      final mid1 = Square(from.file + df.sign, from.rank);
      final mid2 = Square(from.file + 2 * df.sign, from.rank);
      final midAlt1 = Square(from.file, from.rank + dr.sign);
      final midAlt2 = Square(from.file + df.sign, from.rank + dr.sign);
      if (isOnBoard(mid1) && isOnBoard(mid2)) {
        paths.add((from, mid1, mid2, to));
      }
      if (isOnBoard(midAlt1) && isOnBoard(midAlt2)) {
        paths.add((from, midAlt1, midAlt2, to));
      }
    } else {
      final mid1 = Square(from.file, from.rank + dr.sign);
      final mid2 = Square(from.file, from.rank + 2 * dr.sign);
      final midAlt1 = Square(from.file + df.sign, from.rank);
      final midAlt2 = Square(from.file + df.sign, from.rank + dr.sign);
      if (isOnBoard(mid1) && isOnBoard(mid2)) {
        paths.add((from, mid1, mid2, to));
      }
      if (isOnBoard(midAlt1) && isOnBoard(midAlt2)) {
        paths.add((from, midAlt1, midAlt2, to));
      }
    }
    return paths;
  }

  bool chooseCustomsPath(int index) {
    if (!_rules.awaitingCustomsPath) return false;
    if (index < 0 || index >= _rules.customsPaths.length) return false;
    final path = _rules.customsPaths[index];
    // Strip one random mod from enemy pieces standing on intermediate cells.
    for (var i = 1; i < path.length - 1; i++) {
      final s = path[i];
      for (final p in List<Piece>.from(piecesAt(s))) {
        if (p.color == (_pieceById(_rules.customsKnightId ?? '')?.piece.color)) {
          continue;
        }
        if (p.abilities.isEmpty) continue;
        final mods = p.abilities.toList()..shuffle(_random);
        final ref = _pieceById(p.pieceId);
        if (ref == null) continue;
        _replacePieceAt(
          ref.square,
          ref.index,
          ref.piece.withoutAbility(mods.first),
        );
        _refreshDoppelgangerFlags();
        break;
      }
    }
    final from = _rules.customsFrom;
    final to = _rules.customsTo;
    final knightId = _rules.customsKnightId;
    _rules.awaitingCustomsPath = false;
    _rules.customsPaths.clear();
    _rules.customsFrom = null;
    _rules.customsTo = null;
    _rules.customsKnightId = null;
    if (from == null || to == null || knightId == null) return false;
    final ref = _pieceById(knightId);
    if (ref == null) return false;
    final move = Move(from: from, to: to, pieceIndex: ref.index);
    // Path already chosen — execute without re-entering customs wait.
    final legal = getLegalMoves(from: from);
    if (!legal.any((m) => m.to == to)) {
      // Force apply if still on from.
    }
    _applyMove(move);
    _afterVoluntaryMove(move, ref.piece, captured: piecesAt(to).isNotEmpty);
    _passTurnUnlessDuckPending();
    _updateStatus();
    return true;
  }

  bool chooseTangledKeep(Square square) {
    if (!_rules.tangledAwaitingKeep) return false;
    final base = _pieceById(_rules.tangledKnightBaseId ?? '');
    final clone = _pieceById(_rules.tangledCloneId ?? '');
    if (base == null && clone == null) {
      _rules.tangledAwaitingKeep = false;
      return false;
    }
    final keepBase = base != null && base.square == square;
    final keepClone = clone != null && clone.square == square;
    if (!keepBase && !keepClone) return false;
    if (keepBase && clone != null) {
      final removed = _takePieceAt(clone.square, clone.index);
      if (removed != null) {
        // Vanish without graveyard reward — temporary clone.
      }
    } else if (keepClone && base != null) {
      final removed = _takePieceAt(base.square, base.index);
      if (removed != null) {}
      // Promote clone identity? keep clone as-is.
    }
    _rules.tangledAwaitingKeep = false;
    _rules.tangledCloneId = null;
    _rules.tangledKnightBaseId = null;
    _rules.tangledFrom = null;
    _rules.tangledFirstDest = null;
    _updateStatus();
    return true;
  }

  bool activateDoubleLife(String pieceId) {
    final ref = _pieceById(pieceId);
    if (ref == null) return false;
    if (!_hasEffect(ref.piece, AbilityEffect.pawnDoubleLife)) return false;
    if (_rules.doubleLifeUsed.contains(pieceId)) return false;
    final hidden = _rules.doubleLifeHidden[pieceId];
    if (hidden == null) return false;
    _rules.doubleLifeArmed.add(pieceId);
    _replacePieceAt(
      ref.square,
      ref.index,
      ref.piece.copyWith(moveAsType: hidden),
    );
    _updateStatus();
    return true;
  }

  bool activateArchivistRecall(String pieceId) {
    final ref = _pieceById(pieceId);
    if (ref == null) return false;
    if (!_hasEffect(ref.piece, AbilityEffect.pawnArchivist)) return false;
    if (_rules.archivistRecallUsed.contains(pieceId)) return false;
    _rules.archivistRecallArmed.add(pieceId);
    _beginMultiCellTarget(
      ability: GameAbility.pawnArchivist,
      sourceId: pieceId,
      color: ref.piece.color,
      needed: 1,
    );
    _updateStatus();
    return true;
  }

  bool completeSpotlightPromo(PieceType type) {
    final id = _rules.spotlightPromoId;
    if (id == null) return false;
    if (type != PieceType.knight && type != PieceType.bishop) return false;
    final ref = _pieceById(id);
    if (ref == null) {
      _rules.spotlightPromoId = null;
      return false;
    }
    _replacePieceAt(
      ref.square,
      ref.index,
      ref.piece.copyWith(type: type),
    );
    _rules.spotlightPromoId = null;
    _rules.spotlightUnderFire.remove(id);
    _updateStatus();
    return true;
  }

  void _applySchismSplit(String bishopId) {
    final ref = _pieceById(bishopId);
    if (ref == null) return;
    final color = ref.piece.color;
    final origin = ref.square;
    // Two half-bishops: diag signs +1 and -1 (file-rank parity of direction).
    _rules.schismDiagSign[bishopId] = 1;
    final cloneId = '$bishopId-schism';
    // Place clone on adjacent free diagonal cell if possible, else same file+1.
    Square? dest;
    for (final (df, dr) in const [(1, 1), (1, -1), (-1, 1), (-1, -1), (1, 0), (-1, 0)]) {
      final s = Square(origin.file + df, origin.rank + dr);
      if (!isOnBoard(s)) continue;
      if (piecesAt(s).isNotEmpty || isBlocked(s)) continue;
      dest = s;
      break;
    }
    if (dest == null) return;
    _setPrimary(
      dest,
      Piece(
        pieceId: cloneId,
        type: PieceType.bishop,
        color: color,
        hasMoved: true,
        abilities: {GameAbility.bishopSchism},
      ),
    );
    _rules.schismDiagSign[cloneId] = -1;
  }

  void _tickRelicAndSpotlight(PieceColor finished) {
    // Relic: countdown; revive if square vacated after ally visited.
    final relicKeys = _rules.relicPliesLeft.keys.toList();
    for (final id in relicKeys) {
      final ownerColor = // infer from death — stored piece gone; use death square visit
          PieceColor.white; // refined below
      final left = (_rules.relicPliesLeft[id] ?? 0) - 1;
      final death = _rules.relicDeathSquare[id];
      if (death == null) {
        _rules.relicPliesLeft.remove(id);
        continue;
      }
      // If death square empty now and was occupied last by finished color...
      // Simpler rule: if square empty at tick end, revive for the color that
      // had the bishop — encoded in id prefix? We stored only pieceId.
      // Revive for whoever can: check if any ally of either color just left.
      if (piecesAt(death).isEmpty && left >= 0) {
        // Determine color from graveyard
        PieceColor? color;
        for (final g in _graveyard.reversed) {
          if (g.piece.pieceId == id) {
            color = g.originalOwner;
            break;
          }
        }
        if (color != null && color == finished) {
          // Only revive after the owner finished a ply with square empty
          // (they stood and left earlier this turn sequence).
          _setPrimary(
            death,
            Piece(
              pieceId: '$id-revived',
              type: PieceType.bishop,
              color: color,
              hasMoved: true,
            ),
          );
          _rules.relicPliesLeft.remove(id);
          _rules.relicDeathSquare.remove(id);
          continue;
        }
      }
      if (left <= 0) {
        _rules.relicPliesLeft.remove(id);
        _rules.relicDeathSquare.remove(id);
      } else {
        _rules.relicPliesLeft[id] = left;
      }
    }

    // Spotlight: pawn under enemy pawn attack for 6 owner plies
    for (var r = 0; r < _rankCount; r++) {
      for (var f = 0; f < _fileCount; f++) {
        final sq = Square(f, r);
        for (final p in piecesAt(sq)) {
          if (!_hasEffect(p, AbilityEffect.pawnSpotlight)) continue;
          if (p.color != finished) continue;
          final under = _isAttackedByEnemyPawns(sq, p.color);
          if (under) {
            final n = (_rules.spotlightUnderFire[p.pieceId] ?? 0) + 1;
            _rules.spotlightUnderFire[p.pieceId] = n;
            if (n >= 6) {
              _rules.spotlightPromoId = p.pieceId;
            }
          } else {
            _rules.spotlightUnderFire[p.pieceId] = 0;
          }
        }
      }
    }
  }

  bool _isAttackedByEnemyPawns(Square square, PieceColor defender) {
    final dir = defender == PieceColor.white ? 1 : -1;
    // Enemy pawns attack from behind relative to defender forward.
    for (final df in [-1, 1]) {
      final from = Square(square.file + df, square.rank - dir);
      if (!isOnBoard(from)) continue;
      final p = pieceAt(from);
      if (p != null &&
          p.color == defender.opponent &&
          p.type == PieceType.pawn) {
        return true;
      }
    }
    return false;
  }

  void _tryKingGuardAuto(PieceColor checkedColor) {
    if (!isInCheck(checkedColor)) return;
    final guards = <({Square square, int index, Piece piece})>[];
    for (var r = 0; r < _rankCount; r++) {
      for (var f = 0; f < _fileCount; f++) {
        final sq = Square(f, r);
        for (var i = 0; i < piecesAt(sq).length; i++) {
          final p = piecesAt(sq)[i];
          if (p.color != checkedColor) continue;
          if (!_hasEffect(p, AbilityEffect.kingGuardAuto) &&
              !_rules.kingGuardPieceIds.contains(p.pieceId)) {
            continue;
          }
          guards.add((square: sq, index: i, piece: p));
        }
      }
    }
    if (guards.isEmpty) return;
    final kingSq = findKing(checkedColor);
    if (kingSq == null) return;
    // Find checkers
    final checkers = <({Square square, Piece piece})>[];
    for (var r = 0; r < _rankCount; r++) {
      for (var f = 0; f < _fileCount; f++) {
        final from = Square(f, r);
        for (final p in piecesAt(from)) {
          if (p.color != checkedColor.opponent) continue;
          if (_canAttack(from, kingSq, p)) {
            checkers.add((square: from, piece: p));
          }
        }
      }
    }
    if (checkers.isEmpty) return;
    for (final guard in guards) {
      // Prefer capture of checker
      for (final c in checkers) {
        if (_canAttack(guard.square, c.square, guard.piece) &&
            _captureAllowed(guard.piece, c.piece)) {
          final snapshot = createSnapshot();
          _isSimulatingLegality = true;
          try {
            _applyMove(
              Move(
                from: guard.square,
                to: c.square,
                pieceIndex: guard.index,
              ),
            );
            if (!isInCheck(checkedColor)) {
              _isSimulatingLegality = false;
              // Apply for real
              restoreSnapshot(snapshot);
              _applyMove(
                Move(
                  from: guard.square,
                  to: c.square,
                  pieceIndex: guard.index,
                ),
              );
              return;
            }
          } finally {
            _isSimulatingLegality = false;
            restoreSnapshot(snapshot);
          }
        }
      }
      // Interpose on sliding check
      if (checkers.length == 1) {
        final c = checkers.first;
        final blockSquares = _squaresBetween(c.square, kingSq);
        for (final block in blockSquares) {
          if (piecesAt(block).isNotEmpty) continue;
          if (!_canAttack(guard.square, block, guard.piece) &&
              !_pseudoCanMoveTo(guard.square, block, guard.piece, guard.index)) {
            // Use legal move list
          }
          final moves = _getPseudoLegalMoves(
            guard.square,
            guard.piece,
            pieceIndex: guard.index,
          );
          if (!moves.any((m) => m.to == block)) continue;
          final snapshot = createSnapshot();
          try {
            _isSimulatingLegality = true;
            _applyMove(
              Move(from: guard.square, to: block, pieceIndex: guard.index),
            );
            if (!isInCheck(checkedColor)) {
              _isSimulatingLegality = false;
              restoreSnapshot(snapshot);
              _applyMove(
                Move(from: guard.square, to: block, pieceIndex: guard.index),
              );
              return;
            }
          } finally {
            _isSimulatingLegality = false;
            restoreSnapshot(snapshot);
          }
        }
      }
    }
  }

  List<Square> _squaresBetween(Square a, Square b) {
    final df = (b.file - a.file).sign;
    final dr = (b.rank - a.rank).sign;
    final adf = (b.file - a.file).abs();
    final adr = (b.rank - a.rank).abs();
    if (df != 0 && dr != 0 && adf != adr) return const [];
    if (df == 0 && dr == 0) return const [];
    final out = <Square>[];
    var f = a.file + df;
    var r = a.rank + dr;
    while (f != b.file || r != b.rank) {
      out.add(Square(f, r));
      f += df;
      r += dr;
    }
    return out;
  }

  bool _pseudoCanMoveTo(
    Square from,
    Square to,
    Piece piece,
    int pieceIndex,
  ) {
    return _getPseudoLegalMoves(
      from,
      piece,
      pieceIndex: pieceIndex,
    ).any((m) => m.to == to);
  }

'''

text = text.replace(MARKER, HELPERS + "\n" + MARKER, 1)
path.write_text(text, encoding="utf-8")
print("injected helpers")
