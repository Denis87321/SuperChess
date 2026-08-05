import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home_screen.dart';
import 'theme/balatro_theme.dart';

void main() {
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
  runApp(const SuperChessApp());
}

class SuperChessApp extends StatelessWidget {
  const SuperChessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SuperChess',
      debugShowCheckedModeBanner: false,
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
      home: const HomeScreen(),
    );
  }
}
