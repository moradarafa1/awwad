import 'package:flutter_test/flutter_test.dart';

import 'package:awwad/core/catalog/habit_stages.dart';

void main() {
  group('habit stages', () {
    test('break stages follow the HRT arc at the shield thresholds', () {
      expect(stageForStreak('break', 0).n('ar'), 'الوعي');
      expect(stageForStreak('break', 6).n('ar'), 'الوعي');
      expect(stageForStreak('break', 7).n('ar'), 'الاستجابة البديلة');
      expect(stageForStreak('break', 29).n('ar'), 'الاستجابة البديلة');
      expect(stageForStreak('break', 30).n('ar'), 'ضبط البيئة');
      expect(stageForStreak('break', 60).n('ar'), 'التثبيت والوقاية');
      expect(stageForStreak('break', 365).n('ar'), 'التثبيت والوقاية');
    });

    test('build stages follow the habit-formation arc', () {
      expect(stageIndexForStreak('build', 0), 1);
      expect(stageIndexForStreak('build', 7), 2);
      expect(stageIndexForStreak('build', 30), 3);
      expect(stageIndexForStreak('build', 90), 4);
    });

    test('next stage thresholds', () {
      expect(nextStageAt('break', 0), 7);
      expect(nextStageAt('break', 7), 30);
      expect(nextStageAt('break', 45), 60);
      expect(nextStageAt('break', 60), isNull);
      expect(nextStageAt('build', 10), 30);
    });

    test('every stage is fully trilingual with 3 tips and no em-dash', () {
      for (final stages in [kBreakStages, kBuildStages]) {
        for (final s in stages) {
          for (final l in ['ar', 'en', 'fr']) {
            expect(s.n(l), isNotEmpty);
            expect(s.f(l), isNotEmpty);
            expect(s.t(l).length, 3);
            for (final str in [s.n(l), s.f(l), ...s.t(l)]) {
              expect(str.contains('—'), isFalse,
                  reason: 'em-dash found in "$str"');
            }
          }
        }
      }
    });
  });
}
