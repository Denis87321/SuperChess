import 'game_ability.dart';

/// Mods that only confuse humans / give no real edge vs Stockfish.
/// Used when `vsComputer` / Stockfish mode builds [ChessGame].
const stockfishExcludedAbilities = <GameAbility>{
  GameAbility.boardColorblind,
  GameAbility.boardBlindSpot,
  GameAbility.boardShuffle,
  GameAbility.boardInvisibleRegiment,
  GameAbility.boardFogOfWar,
  GameAbility.boardNight,
  GameAbility.boardDay,
  GameAbility.boardVanityFair,
};
