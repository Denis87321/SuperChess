import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_chess/auth/auth_service.dart';
import 'package:super_chess/l10n/locale_controller.dart';
import 'package:super_chess/main.dart';

void main() {
  testWidgets('Home screen loads', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final localeController = LocaleController();
    final auth = AuthService();
    await Future.wait([localeController.load(), auth.load()]);
    await localeController.setPreference('ru');

    await tester.pumpWidget(
      SuperChessApp(localeController: localeController, auth: auth),
    );
    await tester.pumpAndSettle();

    expect(find.text('SUPERCHESS'), findsOneWidget);
    expect(find.text('ИГРАТЬ ОНЛАЙН'), findsOneWidget);
    expect(find.text('ЛОКАЛЬНАЯ ИГРА'), findsOneWidget);
  });
}
