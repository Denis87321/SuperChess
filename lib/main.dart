import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'auth/auth_service.dart';
import 'l10n/app_strings.dart';
import 'l10n/gen/app_localizations.dart';
import 'l10n/locale_controller.dart';
import 'l10n/supported_locales.dart';
import 'notifications/push_service.dart';
import 'screens/home_screen.dart';
import 'theme/balatro_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  final localeController = LocaleController();
  final auth = AuthService();
  await Future.wait([localeController.load(), auth.load()]);
  // Safe no-op when google-services.json / Firebase is not configured.
  await PushService.instance.init(auth);

  runApp(
    SuperChessApp(
      localeController: localeController,
      auth: auth,
    ),
  );
}

class SuperChessApp extends StatefulWidget {
  const SuperChessApp({
    super.key,
    required this.localeController,
    required this.auth,
  });

  final LocaleController localeController;
  final AuthService auth;

  @override
  State<SuperChessApp> createState() => _SuperChessAppState();
}

class _SuperChessAppState extends State<SuperChessApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.localeController.addListener(_onChanged);
    widget.auth.addListener(_onChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.localeController.removeListener(_onChanged);
    widget.auth.removeListener(_onChanged);
    super.dispose();
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    widget.localeController.onSystemLocalesChanged();
  }

  void _onChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final locale = widget.localeController.locale;
    return L10nScope(
      locale: locale,
      child: MaterialApp(
        title: 'SuperChess',
        debugShowCheckedModeBanner: false,
        locale: locale,
        supportedLocales: kSupportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: BalatroTheme.background,
          colorScheme: ColorScheme.dark(
            primary: BalatroTheme.accent,
            secondary: BalatroTheme.gold,
            surface: BalatroTheme.felt,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: BalatroTheme.appBar,
            foregroundColor: BalatroTheme.cream,
          ),
          useMaterial3: true,
        ),
        home: HomeScreen(
          auth: widget.auth,
          localeController: widget.localeController,
        ),
      ),
    );
  }
}
