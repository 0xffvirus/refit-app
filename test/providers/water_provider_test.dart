import 'package:flutter_test/flutter_test.dart';
import 'package:habit_game/models/water_entry.dart';
import 'package:habit_game/providers/water_provider.dart';
import 'package:habit_game/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DateTime now;
  late WaterProvider provider;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await DatabaseService.resetForTesting(path: inMemoryDatabasePath);
    now = DateTime(2026, 10, 18, 23, 50);
    provider = WaterProvider(clock: () => now);
  });

  tearDown(() async {
    provider.dispose();
    await DatabaseService.resetForTesting();
  });

  Future<void> seedEntry(DateTime date, int ml) =>
      DatabaseService().insertWaterEntry(
        WaterEntry(
          id: 'e-${date.day}-$ml',
          date: date,
          amountMl: ml,
          createdAt: date,
        ),
      );

  test(
    'refreshForToday rolls over to the new day and reloads entries',
    () async {
      await seedEntry(DateTime(2026, 10, 18, 9), 500);
      await seedEntry(DateTime(2026, 10, 19, 8), 250);

      await provider.initialize();
      expect(provider.totalMl, 500);

      var notified = 0;
      provider.addListener(() => notified++);

      now = DateTime(2026, 10, 19, 7, 30);
      await provider.refreshForToday();

      expect(provider.selectedDate.day, 19);
      expect(provider.totalMl, 250);
      expect(notified, 1);
    },
  );

  test('refreshForToday is a no-op on the same day', () async {
    await provider.initialize();
    var notified = 0;
    provider.addListener(() => notified++);

    now = DateTime(2026, 10, 18, 23, 59);
    await provider.refreshForToday();

    expect(provider.selectedDate.day, 18);
    expect(notified, 0);
  });

  test('addWater after midnight logs to the new day', () async {
    await provider.initialize();

    now = DateTime(2026, 10, 19, 0, 5);
    await provider.addWater(330);

    expect(provider.selectedDate.day, 19);
    final day19 = await DatabaseService().fetchWaterEntriesForDate(
      DateTime(2026, 10, 19),
    );
    expect(day19.map((e) => e.amountMl), [330]);
    final day18 = await DatabaseService().fetchWaterEntriesForDate(
      DateTime(2026, 10, 18),
    );
    expect(day18, isEmpty);
  });

  test('an explicitly chosen past date is not overridden on resume', () async {
    await provider.initialize();
    await provider.setDate(DateTime(2026, 10, 10));

    now = DateTime(2026, 10, 19, 8);
    await provider.refreshForToday();

    expect(provider.selectedDate, DateTime(2026, 10, 10));
  });
}
