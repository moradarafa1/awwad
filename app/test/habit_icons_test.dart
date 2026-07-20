import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:awwad/core/catalog/habit_catalog.dart';
import 'package:awwad/core/catalog/habit_icons.dart';

// The catalog's `icon` field is DATA: it is mirrored in supabase/seed.sql and
// in the live database, so it stays an emoji. The vector icon is a separate
// presentation map keyed by habit key. These tests keep the two in step: a new
// catalog habit must not silently fall back to an emoji while every habit
// around it draws a proper icon.
void main() {
  test('every catalog habit has a vector icon', () {
    final missing = kHabitCatalog
        .where((h) => habitIcon(h.key) == null)
        .map((h) => '${h.key} (${h.icon})')
        .toList();
    expect(missing, isEmpty,
        reason: 'these catalog habits would still render as emoji: $missing');
  });

  test('the icon map has no entry for a habit that no longer exists', () {
    final keys = kHabitCatalog.map((h) => h.key).toSet();
    final orphans = kHabitIcons.keys.where((k) => !keys.contains(k)).toList();
    expect(orphans, isEmpty,
        reason: 'icon entries pointing at removed habits: $orphans');
  });

  test('icons are distinct enough to tell habits apart', () {
    // Some reuse is fine, but a large collision count means the map was filled
    // in lazily with one generic icon and the catalog reads as a wall of
    // identical glyphs, which is the exact problem this replaced.
    final counts = <IconData, int>{};
    for (final icon in kHabitIcons.values) {
      counts[icon] = (counts[icon] ?? 0) + 1;
    }
    final reused = counts.entries.where((e) => e.value > 1).length;
    expect(reused, lessThanOrEqualTo(2),
        reason: 'too many habits share the same icon');
  });

  testWidgets('a custom habit with no key falls back to its emoji',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: HabitIcon(habitKey: null, emoji: '🎯'),
      ),
    ));
    expect(find.text('🎯'), findsOneWidget);
    expect(find.byType(Icon), findsNothing);
  });

  testWidgets('a known habit draws the vector icon, not the emoji',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: HabitIcon(habitKey: 'quit_smoking', emoji: '🚭'),
      ),
    ));
    expect(find.text('🚭'), findsNothing);
    expect(find.byIcon(Icons.smoke_free_rounded), findsOneWidget);
  });
}
