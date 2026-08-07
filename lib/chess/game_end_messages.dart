import '../l10n/models/piece.dart';
import 'chess_game.dart';

/// Human-readable end-of-game copy (RU). Used in UI, history and docs.
class GameEndMessages {
  GameEndMessages._();

  /// Score string like `1-0`, `0-1`, `½-½`.
  static String score(PieceColor? winner) {
    if (winner == PieceColor.white) return '1-0';
    if (winner == PieceColor.black) return '0-1';
    return '½-½';
  }

  static String winnerPhrase(PieceColor? winner) {
    if (winner == PieceColor.white) return 'Победа белых';
    if (winner == PieceColor.black) return 'Победа чёрных';
    return 'Ничья';
  }

  /// Primary reason sentence (without winner suffix).
  static String reasonSentence({
    required GameEndReason? reason,
    String? detail,
    PieceColor? winner,
    PieceColor? localColor,
    bool online = false,
  }) {
    switch (reason) {
      case GameEndReason.checkmate:
        return winner == PieceColor.white
            ? 'Чёрные получили мат'
            : winner == PieceColor.black
                ? 'Белые получили мат'
                : 'Мат';
      case GameEndReason.stalemate:
        return 'Пат';
      case GameEndReason.draw:
        return 'Ничья';
      case GameEndReason.drawAgreed:
        return 'Ничья по соглашению';
      case GameEndReason.resign:
        if (online && localColor != null && winner != null) {
          return winner == localColor
              ? 'Соперник сдался'
              : 'Вы сдались';
        }
        if (winner == PieceColor.white) return 'Чёрные сдались';
        if (winner == PieceColor.black) return 'Белые сдались';
        return 'Сдача';
      case GameEndReason.timeout:
        if (winner == PieceColor.white) return 'Чёрные просрочили время';
        if (winner == PieceColor.black) return 'Белые просрочили время';
        return 'Время вышло';
      case GameEndReason.kingDestroyed:
        return _detailOr(
          detail,
          fallback: winner == null
              ? 'Оба короля уничтожены'
              : 'Король уничтожен',
        );
      case GameEndReason.baskerville:
        return 'Эффект Баскервилей: третий шах уничтожил короля';
      case GameEndReason.exterminatus:
        return 'Экстерминатус: шах во время действия мода уничтожил короля';
      case GameEndReason.alternativeVictory:
        return _alternative(detail);
      case null:
        return '';
    }
  }

  /// Full line for side panel: `Reason • Победа белых`.
  static String panelLine({
    required GameEndReason? reason,
    String? detail,
    PieceColor? winner,
    PieceColor? localColor,
    bool online = false,
  }) {
    final reasonText = reasonSentence(
      reason: reason,
      detail: detail,
      winner: winner,
      localColor: localColor,
      online: online,
    );
    if (reasonText.isEmpty) return winnerPhrase(winner);
    return '$reasonText • ${winnerPhrase(winner)}';
  }

  static String _detailOr(String? detail, {required String fallback}) {
    final mapped = _alternative(detail);
    if (detail == null || detail.isEmpty || mapped == 'Альтернативная победа') {
      return fallback;
    }
    return mapped;
  }

  static String _alternative(String? detail) {
    switch (detail) {
      case 'debtPit':
        return 'Долговая яма: долг достиг 6';
      case 'busArmy':
        return 'Автобус: при патовой позиции победила меньшая армия';
      case 'kingOfHill':
        return 'Царь горы: захвачено больше половины клеток';
      case 'secretRoute':
        return 'Тайный маршрут пройден до конца';
      case 'royalPilgrimage':
        return 'Королевское паломничество: король на последней горизонтали вне шаха';
      case 'passiveAggression':
        return 'Пассивная агрессия: 10 ходов без шаха';
      case 'letterH':
        return 'Буква «H»: фигуры сложились в нужную форму';
      case 'fullCircle':
        return 'Полный круг: ладья посетила все углы';
      case 'onlyEqualsKill':
        return 'Только равных: 5 взятий фигурами того же типа';
      case 'restlessKings':
        return 'Беспокойные короли: король остался на стартовой клетке';
      case 'cornerQuest':
        return 'Угловой квест: кони посетили 3 угла';
      case 'fatherDream':
        return 'Отцовский сон: у ферзя накопилось 5 модов';
      case 'ownHands':
        return 'Своими руками: короли оказались вплотную';
      case 'kingCenter':
        return 'Король центра: король встал на d4/d5/e4/e5';
      case 'prioritySetup':
        return 'Приоритетная расстановка: заняты все приоритетные клетки';
      default:
        return 'Альтернативная победа';
    }
  }

  /// All documented ending scenarios for docs / help.
  static const List<({String id, String title, String body})> catalog = [
    (
      id: 'checkmate',
      title: 'Мат',
      body:
          'У стороны нет легальных ходов, и её король под шахом. Победа соперника.',
    ),
    (
      id: 'stalemate',
      title: 'Пат',
      body:
          'У стороны нет легальных ходов, но король не под шахом. Ничья. Также пат при тумане войны без ходов; ничья, если «Аура короля» допускает шах только пешками.',
    ),
    (
      id: 'drawAgreed',
      title: 'Ничья по соглашению',
      body: 'Оба игрока согласились на ничью (онлайн).',
    ),
    (
      id: 'resign',
      title: 'Сдача',
      body: 'Игрок сдался. Победа соперника.',
    ),
    (
      id: 'timeout',
      title: 'Просрочка времени',
      body: 'У игрока закончилось время на часах. Победа соперника.',
    ),
    (
      id: 'kingDestroyed',
      title: 'Король уничтожен',
      body:
          'Король снят с доски (взятие, взрыв, мина, лава, чума и т.п.). В тумане войны мат не ставится — побеждает взятие короля. Если пали оба короля — ничья.',
    ),
    (
      id: 'baskerville',
      title: 'Эффект Баскервилей',
      body: 'Третий шах за партию при активном моде уничтожает короля соперника.',
    ),
    (
      id: 'exterminatus',
      title: 'Экстерминатус',
      body: 'Пока действует мод, любой шах уничтожает короля стороны под шахом.',
    ),
    (
      id: 'debtPit',
      title: 'Долговая яма',
      body:
          'Взятие увеличивает ваш долг на 1, потеря фигуры уменьшает на 1. При долге 6 — поражение.',
    ),
    (
      id: 'busArmy',
      title: 'Автобус',
      body:
          'При патовой позиции побеждает сторона с меньшим числом фигур; при равенстве — обычный пат.',
    ),
    (
      id: 'kingOfHill',
      title: 'Царь горы',
      body: 'Сторона владеет более чем 48 клетками территории.',
    ),
    (
      id: 'secretRoute',
      title: 'Тайный маршрут',
      body: 'Посещены все клетки тайного маршрута.',
    ),
    (
      id: 'royalPilgrimage',
      title: 'Королевское паломничество',
      body: 'Король достиг последней горизонтали соперника и не под шахом.',
    ),
    (
      id: 'passiveAggression',
      title: 'Пассивная агрессия',
      body: 'Сторона сделала 10 своих ходов подряд без шаха сопернику — поражение.',
    ),
    (
      id: 'letterH',
      title: 'Буква «H»',
      body: 'Семь фигур стороны образуют букву H на доске.',
    ),
    (
      id: 'fullCircle',
      title: 'Полный круг',
      body: 'Одна ладья посетила все четыре угла доски.',
    ),
    (
      id: 'onlyEqualsKill',
      title: 'Только равных',
      body: 'Сторона совершила 5 взятий фигурой того же типа, что и жертва.',
    ),
    (
      id: 'restlessKings',
      title: 'Беспокойные короли',
      body:
          'По истечении таймера король всё ещё на стартовой клетке — победа соперника.',
    ),
    (
      id: 'cornerQuest',
      title: 'Угловой квест',
      body: 'Кони стороны посетили любые 3 угла доски.',
    ),
    (
      id: 'fatherDream',
      title: 'Отцовский сон',
      body: 'У ферзя накопилось не меньше 5 способностей.',
    ),
    (
      id: 'ownHands',
      title: 'Своими руками',
      body: 'Ваш король оказался в пределах 2 клеток (по Чебышёву) от короля соперника.',
    ),
    (
      id: 'kingCenter',
      title: 'Король центра',
      body: 'Король встал на одну из клеток d4, d5, e4, e5.',
    ),
    (
      id: 'prioritySetup',
      title: 'Приоритетная расстановка',
      body: 'Все приоритетные клетки заняты фигурами одной стороны.',
    ),
  ];
}
