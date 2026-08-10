import 'package:flutter/widgets.dart';

import 'ability_en.dart';
import 'ability_group.dart';
import 'game_ability.dart';

extension AbilityGroupL10n on AbilityGroup {
  String titleFor(Locale locale) {
    final en = !locale.languageCode.toLowerCase().startsWith('ru');
    if (!en) return title;
    return switch (this) {
      AbilityGroup.mode => 'Mode',
      AbilityGroup.board => 'Board',
      AbilityGroup.pawn => 'Pawn',
      AbilityGroup.knight => 'Knight',
      AbilityGroup.bishop => 'Bishop',
      AbilityGroup.rook => 'Rook',
      AbilityGroup.queen => 'Queen',
      AbilityGroup.king => 'King',
      AbilityGroup.random => 'Cataclysms',
    };
  }
}

extension GameAbilityL10n on GameAbility {
  /// Localized title.
  String titleFor(Locale locale) {
    if (locale.languageCode.toLowerCase().startsWith('ru')) return title;
    return kAbilityTitlesEn[this] ?? _humanizeAbilityId(name);
  }

  /// Localized description.
  String descriptionForLocale(Locale locale) {
    if (locale.languageCode.toLowerCase().startsWith('ru')) return description;
    return kAbilityDescriptionsEn[this] ?? description;
  }
}

String _humanizeAbilityId(String id) {
  var s = id;
  const prefixes = [
    'board',
    'mode',
    'pawn',
    'knight',
    'bishop',
    'rook',
    'queen',
    'king',
    'random',
  ];
  for (final p in prefixes) {
    if (s.startsWith(p) &&
        s.length > p.length &&
        s.codeUnitAt(p.length) >= 65 &&
        s.codeUnitAt(p.length) <= 90) {
      s = s.substring(p.length);
      break;
    }
  }
  final spaced = s.replaceAllMapped(
    RegExp(r'([a-z])([A-Z])'),
    (m) => '${m[1]} ${m[2]}',
  );
  if (spaced.isEmpty) return id;
  return spaced[0].toUpperCase() + spaced.substring(1);
}
