import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_game/main.dart';

void main() {
  testWidgets('App renders main shell', (WidgetTester tester) async {
    await tester.pumpWidget(HabitGameApp(initialLocale: Locale('ar')));
    await tester.pumpAndSettle();
    expect(find.text('العادات'), findsOneWidget);
    expect(find.text('اللياقة'), findsOneWidget);
  });
}
