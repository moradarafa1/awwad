import 'package:uuid/uuid.dart';
import '../custom_field.dart';

const _uuid = Uuid();

// Default tracking fields seeded when a habit is created, in the user's locale.
// Generalized from the original HRT prototype's checklists + moods.

const _competingResponse = {
  'ar': [
    'أمسكت يدي بقبضة لدقيقة',
    'وضعت يدي تحت فخذي',
    'أمسكت شيئاً في يدي',
    'تنفّست بعمق (٤ شهيق، ٦ زفير)',
    'استعنت بالله وقلت ذكراً',
  ],
  'en': [
    'Clenched my fist for a minute',
    'Put my hands under my thighs',
    'Held an object in my hand',
    'Breathed deeply (4 in, 6 out)',
    'Said a dhikr / took a breath',
  ],
  'fr': [
    "J'ai serré le poing une minute",
    'Mains sous les cuisses',
    'Tenu un objet en main',
    'Respiré profondément (4/6)',
    'Dit un dhikr / fait une pause',
  ],
};

const _environment = {
  'ar': [
    'أبعدت المحفّز عن متناول يدي',
    'أبقيت شيئاً في يدي (قلم/مسبحة)',
    'غيّرت مكاني عند الرغبة',
    'قلّلت وقت الشاشة قبل النوم',
  ],
  'en': [
    'Kept the trigger out of reach',
    'Kept something in my hand',
    'Changed my spot at urge time',
    'Reduced screen time before bed',
  ],
  'fr': [
    'Éloigné le déclencheur',
    'Gardé un objet en main',
    "Changé de place lors de l'envie",
    "Réduit l'écran avant le coucher",
  ],
};

List<CustomField> seedFields(String locale, String track) {
  final loc = ['ar', 'en', 'fr'].contains(locale) ? locale : 'ar';
  final fields = <CustomField>[];

  // Competing-response + environment are most relevant to the "break" track,
  // but available for both (build track can hide them).
  var i = 0;
  for (final label in _competingResponse[loc]!) {
    fields.add(CustomField(
        id: _uuid.v4(),
        group: 'competing_response',
        label: label,
        isSystem: true,
        sortOrder: i++));
  }
  i = 0;
  for (final label in _environment[loc]!) {
    fields.add(CustomField(
        id: _uuid.v4(),
        group: 'environment_action',
        label: label,
        isSystem: true,
        sortOrder: i++));
  }
  return fields;
}

String groupTitle(String group, String locale) {
  const titles = {
    'competing_response': {
      'ar': '✋ ماذا فعلت بدل العادة؟',
      'en': '✋ What did you do instead?',
      'fr': "✋ Qu'avez-vous fait à la place ?"
    },
    'environment_action': {
      'ar': '🛡️ تجهيزات البيئة',
      'en': '🛡️ Environment setup',
      'fr': "🛡️ Préparation de l'environnement"
    },
    'mood': {'ar': 'المزاج', 'en': 'Mood', 'fr': 'Humeur'},
  };
  return titles[group]?[locale] ?? titles[group]?['ar'] ?? group;
}
