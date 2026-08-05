import 'package:flutter_test/flutter_test.dart';
import 'package:super_chess/main.dart';

void main() {
  testWidgets('Home screen loads', (tester) async {
    await tester.pumpWidget(const SuperChessApp());
    await tester.pumpAndSettle();

    expect(find.text('SUPERCHESS'), findsOneWidget);
    expect(find.text('ИГРАТЬ ОНЛАЙН'), findsOneWidget);
    expect(find.text('ЛОКАЛЬНАЯ ИГРА'), findsOneWidget);
  });
}
