import 'package:flutter/widgets.dart';

/// Simple RU/EN string table for shell UI (mods stay Russian in v1).
class AppStrings {
  AppStrings._(this.locale);

  final Locale locale;

  static AppStrings of(BuildContext context) {
    final inherited = context.dependOnInheritedWidgetOfExactType<_L10nScope>();
    return inherited?.strings ?? AppStrings._(const Locale('en'));
  }

  bool get isRu => locale.languageCode.toLowerCase().startsWith('ru');

  String get appTitle => 'SuperChess';
  String get tagline =>
      isRu ? 'Шахматы с модами' : 'Chess with mods';
  String get playOnline => isRu ? 'ИГРАТЬ ОНЛАЙН' : 'PLAY ONLINE';
  String get playLocal => isRu ? 'ЛОКАЛЬНАЯ ИГРА' : 'LOCAL GAME';
  String get playComputer => isRu ? 'ПРОТИВ STOCKFISH' : 'VS STOCKFISH';
  String get computer => 'Stockfish';
  String get computerThinking =>
      isRu ? 'Stockfish думает…' : 'Stockfish is thinking…';
  String get computerHint => isRu
      ? 'Вы с модами, Stockfish играет без модов'
      : 'You get mods; Stockfish plays without mods';
  String get online => isRu ? 'ОНЛАЙН' : 'ONLINE';
  String get anonymous => isRu ? 'Аноним' : 'Anonymous';
  String get you => isRu ? 'Вы' : 'You';
  String get login => isRu ? 'Войти' : 'Log in';
  String get register => isRu ? 'Регистрация' : 'Sign up';
  String get logout => isRu ? 'Выйти' : 'Log out';
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
  String get settings => isRu ? 'Настройки' : 'Settings';
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

  String get profile => isRu ? 'Профиль' : 'Profile';
  String get history => isRu ? 'История партий' : 'Game history';
  String get rating => isRu ? 'Рейтинг' : 'Rating';
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
