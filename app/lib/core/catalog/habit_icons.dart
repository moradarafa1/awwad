import 'package:flutter/material.dart';

/// Vector icons for the catalog, resolved by habit key.
///
/// WHY A SEPARATE MAP INSTEAD OF CHANGING THE CATALOG
/// The `icon` field on CatalogHabit holds an emoji, and that field is DATA: it
/// is mirrored in supabase/seed.sql and in the live database. Changing it would
/// mean a three-way migration for what is purely a presentation choice. So the
/// emoji stays as the stored value and the fallback, and the app draws a vector
/// icon whenever it knows one for the key.
///
/// WHY MATERIAL SYMBOLS ROUNDED
/// They ship inside Flutter (Apache 2.0), need no package, work offline, and
/// the icon font is tree-shaken to ~16 KB at build time, so the 40 icons below
/// cost almost nothing. The `_rounded` variants match the app's rounded,
/// glassy surfaces; the default filled variants read as dated next to them.
///
/// A custom habit has no key and correctly falls through to its emoji.
const Map<String, IconData> kHabitIcons = {
  // ---- break: health ----
  'quit_smoking': Icons.smoke_free_rounded,
  'quit_vaping': Icons.air_rounded,
  'junk_food': Icons.no_food_rounded,
  'oversleeping': Icons.bedtime_off_rounded,
  'caffeine_excess': Icons.coffee_rounded,
  'late_nights': Icons.nights_stay_rounded,

  // ---- break: mind ----
  'nail_biting': Icons.back_hand_rounded,
  'hair_pulling': Icons.content_cut_rounded,
  'skin_picking': Icons.pan_tool_rounded,
  'secret_habit': Icons.lock_rounded,
  'anger': Icons.mood_bad_rounded,
  'break_porn': Icons.shield_rounded,

  // ---- break: productivity ----
  'phone_addiction': Icons.smartphone_rounded,
  'excessive_gaming': Icons.videogame_asset_rounded,
  'procrastination': Icons.hourglass_empty_rounded,
  'binge_watching': Icons.tv_rounded,
  'impulse_buying': Icons.shopping_bag_rounded,

  // ---- break: social ----
  'gossip': Icons.record_voice_over_rounded,
  'bad_language': Icons.volume_off_rounded,

  // ---- build: worship ----
  'pray_on_time': Icons.mosque_rounded,
  'daily_quran': Icons.menu_book_rounded,
  'adhkar': Icons.spa_rounded,
  'voluntary_fasting': Icons.brightness_3_rounded,
  'qiyam': Icons.mode_night_rounded,
  'istighfar': Icons.front_hand_rounded,
  'salawat': Icons.local_florist_rounded,
  'surah_kahf': Icons.auto_stories_rounded,
  'wake_fajr': Icons.wb_twilight_rounded,
  'listening_wird': Icons.headphones_rounded,
  'hadith_wird': Icons.radio_rounded,
  'dua': Icons.volunteer_activism_rounded,

  // ---- build: character ----
  'keeping_ties': Icons.handshake_rounded,
  'daily_charity': Icons.favorite_rounded,
  'honor_parents': Icons.elderly_rounded,
  'gratitude': Icons.waving_hand_rounded,

  // ---- build: self ----
  'exercise': Icons.directions_run_rounded,
  'drink_water': Icons.water_drop_rounded,
  'read_books': Icons.local_library_rounded,
  'sleep_early': Icons.bedtime_rounded,
  'learn_skill': Icons.psychology_rounded,
};

/// Badge icons, same rules as [kHabitIcons]: `BadgeDef.icon` stays an emoji
/// because it is synced data, and the vector icon is resolved by key here.
///
/// The tier reads through the icon itself, so a badge is recognisable before
/// its label: a medal for silver, a laurel for gold, a gem for diamond.
const Map<String, IconData> kBadgeIcons = {
  'first_log': Icons.eco_rounded,
  'streak_3': Icons.fitness_center_rounded,
  'streak_7': Icons.star_rounded,
  'streak_14': Icons.local_fire_department_rounded,
  'streak_30_silver': Icons.military_tech_rounded,
  'streak_60_gold': Icons.workspace_premium_rounded,
  'streak_90_diamond': Icons.diamond_rounded,
  'streak_180_diamond': Icons.auto_awesome_rounded,
  'logged_30': Icons.trending_up_rounded,
};

/// User-pickable icons for CUSTOM habits (and overrides), keyed by a stable
/// string stored on Habit.iconName. 24 concepts spanning worship, sport,
/// study, food, sleep, money, family, work, art and nature; every name was
/// verified to exist in Flutter's bundled Material Symbols before listing.
const Map<String, IconData> kCustomHabitIcons = {
  'self_improvement': Icons.self_improvement_rounded,
  'mosque': Icons.mosque_rounded,
  'menu_book': Icons.menu_book_rounded,
  'volunteer': Icons.volunteer_activism_rounded,
  'fitness': Icons.fitness_center_rounded,
  'run': Icons.directions_run_rounded,
  'spa': Icons.spa_rounded,
  'school': Icons.school_rounded,
  'translate': Icons.translate_rounded,
  'edit_note': Icons.edit_note_rounded,
  'psychology': Icons.psychology_rounded,
  'restaurant': Icons.restaurant_rounded,
  'water': Icons.water_drop_rounded,
  'coffee': Icons.coffee_rounded,
  'no_food': Icons.no_food_rounded,
  'bedtime': Icons.bedtime_rounded,
  'savings': Icons.savings_rounded,
  'family': Icons.family_restroom_rounded,
  'favorite': Icons.favorite_rounded,
  'work': Icons.work_rounded,
  'brush': Icons.brush_rounded,
  'park': Icons.park_rounded,
  'smoke_free': Icons.smoke_free_rounded,
  'smartphone': Icons.smartphone_rounded,
};

/// User-pickable accent colors. Chosen to read on the dark surface and to
/// stay distinct from the status colors (danger red, success green are still
/// present but as deliberate choices).
const List<String> kHabitAccentChoices = [
  '#60a5fa', '#a78bfa', '#e879f9', '#f472b6',
  '#f87171', '#fb923c', '#facc15', '#4ade80',
];

/// Parses '#rrggbb' into a Color; null on anything malformed, so a corrupted
/// stored value degrades to the track default instead of throwing.
Color? habitAccentColor(String? hex) {
  if (hex == null) return null;
  final ok = RegExp('^#[0-9a-fA-F]{6}' r'$').hasMatch(hex);
  if (!ok) return null;
  return Color(0xFF000000 | int.parse(hex.substring(1), radix: 16));
}

/// The icon for a habit key, or null when there is none (custom habits, and
/// any catalog key added later without a matching entry above).
IconData? habitIcon(String? key) => key == null ? null : kHabitIcons[key];
/// The icon for a badge key, or null when there is none.
IconData? badgeIcon(String? key) => key == null ? null : kBadgeIcons[key];

/// Renders a badge's icon: the vector one when known, otherwise the stored
/// emoji. [color] usually carries the tier colour.
class BadgeIcon extends StatelessWidget {
  final String? badgeKey;
  final String emoji;
  final double size;
  final Color? color;

  const BadgeIcon({
    super.key,
    required this.badgeKey,
    required this.emoji,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final icon = badgeIcon(badgeKey);
    if (icon == null) {
      return Text(emoji, style: TextStyle(fontSize: size * 0.86));
    }
    return Icon(icon, size: size, color: color ?? IconTheme.of(context).color);
  }
}

/// Renders a habit's icon: the vector one when known, otherwise the stored
/// emoji. One place, so every screen shows the same thing for the same habit.
///
/// [size] is the icon's optical size; the emoji fallback is drawn slightly
/// smaller because emoji glyphs carry their own padding and otherwise look
/// oversized next to a vector icon.
class HabitIcon extends StatelessWidget {
  final String? habitKey;
  /// A user-chosen icon key (Habit.iconName); wins over the catalog icon.
  final String? iconName;
  final String emoji;
  final double size;
  final Color? color;

  const HabitIcon({
    super.key,
    required this.habitKey,
    this.iconName,
    required this.emoji,
    this.size = 22,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final icon = kCustomHabitIcons[iconName] ?? habitIcon(habitKey);
    if (icon == null) {
      return Text(emoji, style: TextStyle(fontSize: size * 0.86));
    }
    return Icon(icon, size: size, color: color ?? IconTheme.of(context).color);
  }
}
