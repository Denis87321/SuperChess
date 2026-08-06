import 'game_ability.dart';

/// Mods excluded in Stockfish / vs-computer mode.
///
/// - Sensory / UI confusion: no real edge vs an engine.
/// - Geometry that leaves 8×8 classical FEN (Stockfish cannot see the board).
/// - Turn / clock flow breakers.
const stockfishExcludedAbilities = <GameAbility>{
  // Confusion / UI-only vs engine.
  GameAbility.boardColorblind,
  GameAbility.boardBlindSpot,
  GameAbility.boardShuffle,
  GameAbility.boardInvisibleRegiment,
  GameAbility.boardFogOfWar,
  GameAbility.boardNight,
  GameAbility.boardDay,
  GameAbility.boardVanityFair,
  GameAbility.boardCollectiveMyopia,

  // Flow breakers.
  GameAbility.boardSprint,
  GameAbility.boardSkipTurn,

  // Non-classical board size → [tryBuildFen] returns null.
  GameAbility.boardExtraRank,
  GameAbility.boardExtraFile,
  GameAbility.boardTerritoryExpand,

  // Double-move / chaos that desyncs UCI turn model.
  GameAbility.boardMarseillesChess,
  GameAbility.boardFisherMadness,
};
