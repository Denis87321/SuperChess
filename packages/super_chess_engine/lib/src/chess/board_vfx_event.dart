import '../models/piece.dart';
import '../models/square.dart';
import 'fx_skin.dart';

/// One-shot visual burst queued by the engine for the UI to play.
class BoardVfxEvent {
  const BoardVfxEvent({
    required this.skin,
    required this.square,
    this.piece,
    this.intensity = 1.0,
  });

  final FxSkin skin;
  final Square square;
  final Piece? piece;
  final double intensity;
}
