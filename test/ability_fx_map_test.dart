import 'package:flutter_test/flutter_test.dart';
import 'package:super_chess/chess/ability_fx_map.dart';
import 'package:super_chess/l10n/models/game_ability.dart';

void main() {
  test('every GameAbility has an FX profile', () {
    for (final ability in GameAbility.values) {
      expect(
        kAbilityFx.containsKey(ability),
        isTrue,
        reason: 'missing FX profile for $ability',
      );
    }
    expect(kAbilityFx.length, GameAbility.values.length);
  });

  test('almost all abilities have a real visual skin', () {
    final none = GameAbility.values
        .where((a) => fxProfileFor(a).layer == FxLayer.none)
        .toList();
    expect(none.length, lessThanOrEqualTo(20));
    expect(none.length / GameAbility.values.length, lessThan(0.1));
  });
}
