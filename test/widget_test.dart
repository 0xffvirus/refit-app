import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habit_game/l10n/app_localizations.dart';
import 'package:habit_game/main.dart';
import 'package:habit_game/providers/fitness_provider.dart';
import 'package:habit_game/providers/habit_provider.dart';
import 'package:habit_game/providers/locale_provider.dart';
import 'package:habit_game/providers/water_provider.dart';
import 'package:habit_game/services/database_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await DatabaseService.resetForTesting(path: inMemoryDatabasePath);
  });

  tearDown(() async {
    await DatabaseService.resetForTesting();
  });

  testWidgets('Main shell renders the navigation tabs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => HabitProvider()),
          ChangeNotifierProvider(create: (_) => FitnessProvider()),
          ChangeNotifierProvider(create: (_) => WaterProvider()),
          ChangeNotifierProvider(
            create: (_) => LocaleProvider(const Locale('ar')),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const MainShell(),
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('العادات'), findsOneWidget);
    expect(find.text('اللياقة'), findsOneWidget);
  });
}
