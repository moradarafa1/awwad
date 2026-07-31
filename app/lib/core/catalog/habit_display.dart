// Habit-title display resolution (owner order 2026-07-31, language audit).
//
// Habit.title is STORED in the language the habit was created in, so after
// switching the app language every catalog habit kept its old-language name:
// the exact "half Arabic, half English" mixing the owner reported. The fix:
// a title the user never customized follows the APP language at render time,
// while a user-typed name stays exactly as typed, in whatever language.
//
// Storage is untouched (sync, edit sheet and dedup keep reading h.title);
// ONLY rendering goes through this helper.

import '../models.dart';
import 'habit_catalog.dart';

/// Titles that older catalog versions shipped as defaults, so habits created
/// before a rename still count as "not customized" and keep following the
/// app language. Maps old default -> catalog key.
const Map<String, String> kLegacyDefaultTitles = {
  'المحافظة على الصلاة في وقتها': 'pray_on_time',
};

/// The title to RENDER for [h] in [locale]: the catalog title for the current
/// app language when the stored title is a catalog default (any language),
/// the stored title untouched otherwise.
String habitDisplayTitle(Habit h, String locale) {
  final key = h.catalogKey;
  if (key == null) return h.title;
  CatalogHabit? cat;
  for (final c in kHabitCatalog) {
    if (c.key == key) {
      cat = c;
      break;
    }
  }
  if (cat == null) return h.title;
  final isDefault = cat.t('ar') == h.title ||
      cat.t('en') == h.title ||
      cat.t('fr') == h.title ||
      kLegacyDefaultTitles[h.title] == key;
  return isDefault ? cat.t(locale) : h.title;
}
