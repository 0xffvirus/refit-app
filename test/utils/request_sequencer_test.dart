import 'package:flutter_test/flutter_test.dart';
import 'package:habit_game/utils/request_sequencer.dart';

void main() {
  group('RequestSequencer', () {
    test('only the most recent token is current', () {
      final seq = RequestSequencer();
      final a = seq.next();
      expect(seq.isCurrent(a), isTrue);
      final b = seq.next();
      expect(seq.isCurrent(a), isFalse);
      expect(seq.isCurrent(b), isTrue);
    });

    test('invalidate makes every outstanding token stale', () {
      final seq = RequestSequencer();
      final a = seq.next();
      seq.invalidate();
      expect(seq.isCurrent(a), isFalse);
    });

    test(
      'a slow earlier request cannot overwrite a faster later one',
      () async {
        final seq = RequestSequencer();
        String? applied;

        Future<void> load(String value, Duration delay) async {
          final token = seq.next();
          await Future<void>.delayed(delay);
          if (seq.isCurrent(token)) applied = value;
        }

        await Future.wait([
          load('january', const Duration(milliseconds: 30)),
          load('february', const Duration(milliseconds: 1)),
        ]);

        expect(applied, 'february');
      },
    );
  });

  group('isSameDay', () {
    test('ignores time of day', () {
      expect(
        isSameDay(DateTime(2026, 10, 18, 0, 0), DateTime(2026, 10, 18, 23, 59)),
        isTrue,
      );
    });

    test('detects a midnight rollover', () {
      expect(
        isSameDay(DateTime(2026, 10, 18, 23, 59), DateTime(2026, 10, 19, 0, 1)),
        isFalse,
      );
    });

    test('distinguishes same day in different months and years', () {
      expect(isSameDay(DateTime(2026, 9, 18), DateTime(2026, 10, 18)), isFalse);
      expect(
        isSameDay(DateTime(2025, 10, 18), DateTime(2026, 10, 18)),
        isFalse,
      );
    });
  });
}
