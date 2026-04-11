import 'package:flutter_test/flutter_test.dart';
import 'package:habit_game/services/tutorial_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await TutorialService.instance.reload();
  });

  group('TutorialService flags', () {
    test('shouldShowFor returns true for all tabs when nothing is stored',
        () async {
      for (final tab in TabId.values) {
        expect(TutorialService.instance.shouldShowFor(tab), isTrue);
      }
    });

    test('markSeen flips flag and persists across reload', () async {
      await TutorialService.instance.markSeen(TabId.habits);
      expect(TutorialService.instance.shouldShowFor(TabId.habits), isFalse);

      // Simulate app restart: reload from prefs.
      await TutorialService.instance.reload();
      expect(TutorialService.instance.shouldShowFor(TabId.habits), isFalse);

      // Other tabs remain unseen.
      expect(TutorialService.instance.shouldShowFor(TabId.fitness), isTrue);
      expect(TutorialService.instance.shouldShowFor(TabId.water), isTrue);
      expect(TutorialService.instance.shouldShowFor(TabId.tools), isTrue);
    });

    test('markSeen is idempotent', () async {
      await TutorialService.instance.markSeen(TabId.water);
      await TutorialService.instance.markSeen(TabId.water);
      expect(TutorialService.instance.shouldShowFor(TabId.water), isFalse);
    });

    test('resetAllFlags clears all four', () async {
      for (final tab in TabId.values) {
        await TutorialService.instance.markSeen(tab);
      }
      await TutorialService.instance.resetAllFlags();
      for (final tab in TabId.values) {
        expect(TutorialService.instance.shouldShowFor(tab), isTrue);
      }
    });

    test('TabId has exactly the four expected values', () {
      expect(TabId.values, hasLength(4));
      expect(TabId.values, contains(TabId.habits));
      expect(TabId.values, contains(TabId.fitness));
      expect(TabId.values, contains(TabId.water));
      expect(TabId.values, contains(TabId.tools));
    });
  });
}
