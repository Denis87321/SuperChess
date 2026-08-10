import 'package:flutter/widgets.dart';

import 'gen/app_localizations.dart';

/// Shell strings: full RU/EN table; other locales use ARB subset via
/// [AppLocalizations] when available, else English.
class AppStrings {
  AppStrings._(this.locale, [this._l10n]);

  final Locale locale;
  final AppLocalizations? _l10n;

  static AppStrings of(BuildContext context) {
    final inherited = context.dependOnInheritedWidgetOfExactType<_L10nScope>();
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    return AppStrings._(
      inherited?.strings.locale ?? Localizations.localeOf(context),
      l10n,
    );
  }

  bool get isRu => locale.languageCode.toLowerCase().startsWith('ru');
  bool get _useArb => _l10n != null && !isRu && locale.languageCode != 'en';

  String get appTitle => _l10n?.appTitle ?? 'SuperChess';
  String get tagline =>
      isRu ? 'Шахматы с модами' : 'Chess with mods';
  String get playOnline => _useArb
      ? _l10n!.playOnline.toUpperCase()
      : (isRu ? 'ИГРАТЬ ОНЛАЙН' : 'PLAY ONLINE');
  String get playLocal => _useArb
      ? _l10n!.playLocal.toUpperCase()
      : (isRu ? 'ЛОКАЛЬНАЯ ИГРА' : 'LOCAL GAME');
  String get playComputer => _useArb
      ? _l10n!.playComputer.toUpperCase()
      : (isRu ? 'ПРОТИВ STOCKFISH' : 'VS STOCKFISH');
  String get computer => 'Stockfish';
  String get computerThinking =>
      isRu ? 'Stockfish думает…' : 'Stockfish is thinking…';
  String get computerLoading =>
      isRu ? 'Подключение к Stockfish…' : 'Connecting to Stockfish…';
  String get computerLoadingHint => isRu
      ? 'Движок на сервере (первый раз после сна API может занять до ~1 мин)'
      : 'Engine on the server (cold start may take up to ~1 min)';
  String get computerUnavailable => isRu
      ? 'Stockfish на сервере недоступен — ход не будет сделан'
      : 'Server Stockfish unavailable — it will not move';
  String get computerUnsupportedPosition => isRu
      ? 'Stockfish не видит эту позицию (нестандартная доска) — ход не будет сделан'
      : 'Stockfish cannot read this position — it will not move';
  String get computerNoMove => isRu
      ? 'Stockfish не смог сходить — ход не будет сделан'
      : 'Stockfish could not find a move — it will not move';
  String get computerHint => isRu
      ? 'Вы с модами, Stockfish играет без модов'
      : 'You get mods; Stockfish plays without mods';
  String get online => isRu ? 'ОНЛАЙН' : 'ONLINE';
  String get anonymous => isRu ? 'Аноним' : 'Anonymous';
  String get you => isRu ? 'Вы' : 'You';
  String get login => _useArb ? _l10n!.login : (isRu ? 'Войти' : 'Log in');
  String get register =>
      _useArb ? _l10n!.register : (isRu ? 'Регистрация' : 'Sign up');
  String get logout =>
      _useArb ? _l10n!.logout : (isRu ? 'Выйти' : 'Log out');
  String get username => isRu ? 'Ник' : 'Username';
  String get password => isRu ? 'Пароль' : 'Password';
  String get passwordConfirm =>
      isRu ? 'Повтор пароля' : 'Confirm password';
  String get createAccount =>
      isRu ? 'Создать аккаунт' : 'Create account';
  String get alreadyHaveAccount =>
      isRu ? 'Уже есть аккаунт? Войти' : 'Have an account? Log in';
  String get needAccount =>
      isRu ? 'Нет аккаунта? Регистрация' : 'No account? Sign up';
  String get searching =>
      isRu ? 'Поиск соперника...' : 'Looking for opponent...';
  String get connecting => isRu ? 'Подключение...' : 'Connecting...';
  String get connectFailed => isRu
      ? 'Не удалось подключиться к серверу'
      : 'Could not connect to the server';
  String searchingCount(int count, {required bool onlyYou}) {
    if (isRu) {
      final base = 'Поиск соперника...\nСейчас ищут: $count';
      return onlyYou ? '$base (Это Вы)' : base;
    }
    final base = 'Looking for opponent...\nPlayers searching: $count';
    return onlyYou ? '$base (That\'s you)' : base;
  }

  String get serverLabel => isRu ? 'Сервер' : 'Server';
  String get settings =>
      _useArb ? _l10n!.settings : (isRu ? 'Настройки' : 'Settings');
  String get language => isRu ? 'Язык' : 'Language';
  String get languageRu => 'Русский';
  String get languageEn => 'English';
  String get languageSystem => isRu ? 'Как в системе' : 'System default';
  String get loggedInAs => isRu ? 'Вы вошли как' : 'Signed in as';
  String get guest => isRu ? 'Гость' : 'Guest';
  String get chat => isRu ? 'Чат' : 'Chat';
  String get chatEmpty => isRu ? 'Пока тихо' : 'No messages yet';
  String get messageHint => isRu ? 'Сообщение…' : 'Message…';
  String get menu => isRu ? 'Меню' : 'Menu';
  String get offerDraw => isRu ? 'Предложить ничью' : 'Offer draw';
  String get askTakeback =>
      isRu ? 'Попросить соперника вернуть ход' : 'Propose a takeback';
  String get resign => isRu ? 'Сдаться' : 'Resign';
  String get resignConfirm => isRu ? 'Сдаться?' : 'Resign?';
  String get cancel => isRu ? 'Отменить' : 'Cancel';
  String get youResigned => isRu ? 'Вы сдались' : 'You resigned';
  String get opponentResigned =>
      isRu ? 'Ваш соперник сдался' : 'Your opponent resigned';
  String get victory => isRu ? 'ПОБЕДА' : 'VICTORY';
  String get defeat => isRu ? 'ПОРАЖЕНИЕ' : 'DEFEAT';
  String get draw => isRu ? 'НИЧЬЯ' : 'DRAW';
  String get back => isRu ? 'НАЗАД' : 'BACK';
  String get usernameRules => isRu
      ? 'Ник: 3–20 символов, латиница, цифры, _'
      : 'Username: 3–20 chars, letters, digits, _';
  String get passwordRules =>
      isRu ? 'Пароль не короче 6 символов' : 'Password at least 6 characters';
  String get passwordsMismatch =>
      isRu ? 'Пароли не совпадают' : 'Passwords do not match';
  String get authUnavailable => isRu
      ? 'Регистрация временно недоступна'
      : 'Registration temporarily unavailable';
  String get invalidCredentials =>
      isRu ? 'Неверный ник или пароль' : 'Invalid username or password';
  String get usernameTaken =>
      isRu ? 'Этот ник уже занят' : 'Username already taken';
  String get opponentLeft =>
      isRu ? 'Соперник отключился' : 'Opponent disconnected';
  String onlineTitle(String control) =>
      isRu ? '$control · Онлайн' : '$control · Online';

  String get profile =>
      _useArb ? _l10n!.profile : (isRu ? 'Профиль' : 'Profile');
  String get history => isRu ? 'История партий' : 'Game history';
  String get rating =>
      _useArb ? _l10n!.rating : (isRu ? 'Рейтинг' : 'Rating');
  String get gamesPlayed => isRu ? 'Партий' : 'Games';
  String get collector => isRu ? 'Коллекционер' : 'Collector';
  String get collectorDesc => isRu
      ? 'Используй все моды в залогиненных партиях'
      : 'Use every mod in logged-in games';
  String abilitiesProgress(int unlocked, int total) =>
      isRu ? 'Моды: $unlocked / $total' : 'Mods: $unlocked / $total';
  String get achievementUnlocked =>
      isRu ? 'Получено' : 'Unlocked';
  String get achievementLocked => isRu ? 'Ещё нет' : 'Locked';
  String get noHistory =>
      isRu ? 'Пока нет сыгранных партий' : 'No games yet';
  String get resultWin => isRu ? 'Победа' : 'Win';
  String get resultLoss => isRu ? 'Поражение' : 'Loss';
  String get resultDraw => isRu ? 'Ничья' : 'Draw';
  String get ratedGame => isRu ? 'Рейтинговая' : 'Rated';
  String get casualGame => isRu ? 'Товарищеская' : 'Casual';
  String get white => isRu ? 'Белые' : 'White';
  String get black => isRu ? 'Чёрные' : 'Black';

  String get tutorial =>
      _useArb ? _l10n!.tutorial : (isRu ? 'Обучение' : 'Tutorial');
  String get mods => _useArb ? _l10n!.mods : (isRu ? 'Моды' : 'Mods');
  String get puzzles =>
      _useArb ? _l10n!.puzzles : (isRu ? 'Задачи' : 'Puzzles');
  String get friends =>
      _useArb ? _l10n!.friends : (isRu ? 'Друзья' : 'Friends');
  String get rivalries => isRu ? 'Счёт с соперниками' : 'Rivalries';
  String get privateRoom => isRu ? 'Приватная комната' : 'Private room';
  String get joinByCode => isRu ? 'Войти по коду' : 'Join by code';
  String get spectate => isRu ? 'Смотреть' : 'Spectate';
  String get createRoom => isRu ? 'Создать комнату' : 'Create room';
  String get roomCode => isRu ? 'Код комнаты' : 'Room code';
  String get waitingForOpponent =>
      isRu ? 'Ожидание соперника…' : 'Waiting for opponent…';
  String get copyCode => isRu ? 'Скопировать код' : 'Copy code';
  String get codeCopied => isRu ? 'Код скопирован' : 'Code copied';
  String get searchPlayers => isRu ? 'Поиск игроков' : 'Search players';
  String get addFriend => isRu ? 'Добавить' : 'Add';
  String get accept => isRu ? 'Принять' : 'Accept';
  String get decline => isRu ? 'Отклонить' : 'Decline';
  String get challenge => isRu ? 'Вызвать' : 'Challenge';
  String get incomingRequests => isRu ? 'Входящие' : 'Incoming';
  String get outgoingRequests => isRu ? 'Исходящие' : 'Outgoing';
  String get noFriends => isRu ? 'Пока нет друзей' : 'No friends yet';
  String get seenMod => isRu ? 'Встречался' : 'Encountered';
  String get newMod => isRu ? 'Новый' : 'New';
  String get startTutorialGame =>
      isRu ? 'Учебная партия' : 'Practice game';
  String get tutorialDone => isRu ? 'Понятно' : 'Got it';
  String get next => isRu ? 'Далее' : 'Next';
  String get skip => isRu ? 'Пропустить' : 'Skip';
  String get tryTutorialCta => isRu
      ? 'Впервые здесь? Пройдите короткое обучение'
      : 'New here? Take a short tutorial';
  String get puzzleSolved => isRu ? 'Решено!' : 'Solved!';
  String get puzzleFailed => isRu ? 'Не то решение' : 'Not quite';
  String get puzzleHint => isRu ? 'Подсказка' : 'Hint';
  String get observeMode => isRu ? 'Просмотр' : 'Spectating';
  String get leaveRoom => isRu ? 'Покинуть' : 'Leave';
  String get loginRequired =>
      isRu ? 'Нужно войти в аккаунт' : 'Please log in';
  String get endReasonsHelp =>
      isRu ? 'Как заканчивается партия' : 'How games end';
  String get hasMoveRecord =>
      isRu ? 'Есть запись ходов' : 'Has move record';
  String get noRivalriesYet => isRu
      ? 'Пока нет матчей между залогиненными игроками'
      : 'No matches between logged-in players yet';
  String get takebackQuestion => isRu ? 'Вернуть ход?' : 'Take back a move?';
  String get takebackIncoming => isRu
      ? 'Соперник просит вернуть последний ход'
      : 'Opponent asks to take back the last move';
  String get takebackSent =>
      isRu ? 'Запрос возврата хода отправлен' : 'Takeback request sent';
  String get takebackWaiting =>
      isRu ? 'Ожидаем ответ на возврат хода' : 'Waiting for takeback reply';
  String get takebackNothing =>
      isRu ? 'Нечего возвращать' : 'Nothing to take back';
  String get drawOfferSent => isRu
      ? 'Предложение ничьи отправлено'
      : 'Draw offer sent';
  String get takebackDeclined => isRu
      ? 'Соперник отклонил возврат хода'
      : 'Opponent declined the takeback';
  String get drawDeclined =>
      isRu ? 'Соперник отклонил ничью' : 'Opponent declined the draw';
  String get drawWaiting =>
      isRu ? 'Ожидаем ответ на ничью' : 'Waiting for draw reply';
  String get gameOverWatchMoves => isRu
      ? 'Игра окончена · смотрите ходы справа'
      : 'Game over · review moves on the right';
  String get rotateForBlackHint => isRu
      ? 'При ходе чёрных фигуры и текст переворачиваются на 180°, доска остаётся на месте'
      : 'On Black\'s turn pieces and text flip 180°; the board stays put';
  String get pickLightPiecePromote => isRu
      ? 'Выберите лёгкую фигуру для превращения'
      : 'Pick a minor piece to promote into';
  String get pickKnightJumpRoute =>
      isRu ? 'Выберите маршрут прыжка коня' : 'Pick the knight jump route';
  String get pickBlockingPawnPair => isRu
      ? 'Выберите пару блокирующих пешек'
      : 'Pick a pair of blocking pawns';
  String modWavePick(String side, int count) => isRu
      ? 'Волна модов — ход $side: выбери 1 из $count'
      : 'Mod wave — $side to move: pick 1 of $count';
  String crazyhouseDropPick(String type) => isRu
      ? 'Выберите клетку для дропа ($type)'
      : 'Pick a square to drop ($type)';
  String get tutorialBanner => isRu
      ? 'Учебная партия — моды как в обычной игре'
      : 'Practice game — mods work as usual';
  String get timeControl => isRu ? 'Контроль времени' : 'Time control';
  String get openSeeks => isRu ? 'Открытые поиски' : 'Open seeks';
  String get noSeeks => isRu ? 'Пока никто не ищет' : 'No open seeks yet';
  String get newOpponentSameTc =>
      isRu ? 'Новый соперник (тот же контроль)' : 'New opponent (same TC)';
  String get exportPgn => isRu ? 'Скачать PGN' : 'Export PGN';
  String get analysis =>
      _useArb ? _l10n!.analysis : (isRu ? 'Анализ' : 'Analysis');
  String get clubs => _useArb ? _l10n!.clubs : (isRu ? 'Клубы' : 'Clubs');
  String get forum => _useArb ? _l10n!.forum : (isRu ? 'Форум' : 'Forum');
  String get follow =>
      _useArb ? _l10n!.follow : (isRu ? 'Подписаться' : 'Follow');
  String get unfollow =>
      _useArb ? _l10n!.unfollow : (isRu ? 'Отписаться' : 'Unfollow');
  String get messages =>
      _useArb ? _l10n!.messages : (isRu ? 'Сообщения' : 'Messages');
  String get bio => _useArb ? _l10n!.bio : (isRu ? 'О себе' : 'Bio');
  String get onlineNow =>
      _useArb ? _l10n!.onlineNow : (isRu ? 'В сети' : 'Online');
  String get offline =>
      _useArb ? _l10n!.offline : (isRu ? 'Не в сети' : 'Offline');
}

class _L10nScope extends InheritedWidget {
  const _L10nScope({
    required this.strings,
    required super.child,
  });

  final AppStrings strings;

  @override
  bool updateShouldNotify(_L10nScope oldWidget) =>
      strings.locale != oldWidget.strings.locale;
}

class L10nScope extends StatelessWidget {
  const L10nScope({
    super.key,
    required this.locale,
    required this.child,
  });

  final Locale locale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _L10nScope(
      strings: AppStrings._(locale),
      child: child,
    );
  }
}
