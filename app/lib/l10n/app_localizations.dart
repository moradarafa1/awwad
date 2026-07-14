import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appName.
  ///
  /// In ar, this message translates to:
  /// **'عوّاد'**
  String get appName;

  /// No description provided for @slogan.
  ///
  /// In ar, this message translates to:
  /// **'رفيقُ مَن زانَ عُمرَهُ، وحَسُنَ عملُهُ'**
  String get slogan;

  /// No description provided for @onboardWelcomeTitle.
  ///
  /// In ar, this message translates to:
  /// **'أهلاً بك في عوّاد'**
  String get onboardWelcomeTitle;

  /// No description provided for @onboardWelcomeBody.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ رحلتك لتغيير عادة أو بناء عادة جديدة، خطوةً واحدة كلّ يوم.'**
  String get onboardWelcomeBody;

  /// No description provided for @chooseLanguage.
  ///
  /// In ar, this message translates to:
  /// **'اختر لغتك'**
  String get chooseLanguage;

  /// No description provided for @getStarted.
  ///
  /// In ar, this message translates to:
  /// **'لنبدأ'**
  String get getStarted;

  /// No description provided for @next.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get next;

  /// No description provided for @back.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get back;

  /// No description provided for @skip.
  ///
  /// In ar, this message translates to:
  /// **'تخطٍّ'**
  String get skip;

  /// No description provided for @done.
  ///
  /// In ar, this message translates to:
  /// **'تمّ'**
  String get done;

  /// No description provided for @save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get confirm;

  /// No description provided for @delete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In ar, this message translates to:
  /// **'إضافة'**
  String get add;

  /// No description provided for @search.
  ///
  /// In ar, this message translates to:
  /// **'بحث'**
  String get search;

  /// No description provided for @medicalDisclaimer.
  ///
  /// In ar, this message translates to:
  /// **'عوّاد أداة دعمٍ سلوكيٍّ ومتابعةٍ ذاتية، وليس بديلاً عن الاستشارة الطبية أو النفسية المتخصّصة.'**
  String get medicalDisclaimer;

  /// No description provided for @privacyNote.
  ///
  /// In ar, this message translates to:
  /// **'بياناتك خاصّة بك، ولا يراها أيّ مستخدمٍ آخر.'**
  String get privacyNote;

  /// No description provided for @surveyTitle.
  ///
  /// In ar, this message translates to:
  /// **'ساعدنا على فهمك أكثر'**
  String get surveyTitle;

  /// No description provided for @surveyBody.
  ///
  /// In ar, this message translates to:
  /// **'إجاباتٌ اختيارية تساعدنا على تطوير التجربة وإجراء دراساتٍ مجمّعة، ويمكنك تخطّيها.'**
  String get surveyBody;

  /// No description provided for @surveyConsent.
  ///
  /// In ar, this message translates to:
  /// **'أوافق على استخدام هذه البيانات لأغراض البحث وتحسين التطبيق.'**
  String get surveyConsent;

  /// No description provided for @ageRange.
  ///
  /// In ar, this message translates to:
  /// **'الفئة العمرية'**
  String get ageRange;

  /// No description provided for @gender.
  ///
  /// In ar, this message translates to:
  /// **'النوع'**
  String get gender;

  /// No description provided for @genderMale.
  ///
  /// In ar, this message translates to:
  /// **'ذكر'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In ar, this message translates to:
  /// **'أنثى'**
  String get genderFemale;

  /// No description provided for @genderPreferNot.
  ///
  /// In ar, this message translates to:
  /// **'أفضّل عدم الإفصاح'**
  String get genderPreferNot;

  /// No description provided for @country.
  ///
  /// In ar, this message translates to:
  /// **'الدولة'**
  String get country;

  /// No description provided for @referralSource.
  ///
  /// In ar, this message translates to:
  /// **'كيف عرفت عنّا؟'**
  String get referralSource;

  /// No description provided for @saveAndContinue.
  ///
  /// In ar, this message translates to:
  /// **'حفظ ومتابعة'**
  String get saveAndContinue;

  /// No description provided for @skipSurvey.
  ///
  /// In ar, this message translates to:
  /// **'تخطّي الاستبيان'**
  String get skipSurvey;

  /// No description provided for @chooseTrackTitle.
  ///
  /// In ar, this message translates to:
  /// **'ماذا تريد أن تفعل؟'**
  String get chooseTrackTitle;

  /// No description provided for @trackBreak.
  ///
  /// In ar, this message translates to:
  /// **'أتخلّص من عادة'**
  String get trackBreak;

  /// No description provided for @trackBreakDesc.
  ///
  /// In ar, this message translates to:
  /// **'عادة سيّئة تريد التخلّص منها أو التقليل منها.'**
  String get trackBreakDesc;

  /// No description provided for @trackBuild.
  ///
  /// In ar, this message translates to:
  /// **'أبني عادة جديدة'**
  String get trackBuild;

  /// No description provided for @trackBuildDesc.
  ///
  /// In ar, this message translates to:
  /// **'عادة حسنة تريد ترسيخها في حياتك.'**
  String get trackBuildDesc;

  /// No description provided for @chooseHabitTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر عادتك'**
  String get chooseHabitTitle;

  /// No description provided for @searchHabits.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن عادة...'**
  String get searchHabits;

  /// No description provided for @customHabitTitle.
  ///
  /// In ar, this message translates to:
  /// **'عادتي غير موجودة'**
  String get customHabitTitle;

  /// No description provided for @customHabitDesc.
  ///
  /// In ar, this message translates to:
  /// **'اكتب عادتك بنفسك'**
  String get customHabitDesc;

  /// No description provided for @customHabitNameHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب اسم العادة'**
  String get customHabitNameHint;

  /// No description provided for @habitSetupTitle.
  ///
  /// In ar, this message translates to:
  /// **'جهّز عادتك'**
  String get habitSetupTitle;

  /// No description provided for @habitNameLabel.
  ///
  /// In ar, this message translates to:
  /// **'اسم العادة'**
  String get habitNameLabel;

  /// No description provided for @habitWhyLabel.
  ///
  /// In ar, this message translates to:
  /// **'لماذا تريد القيام بها؟ (دافعك)'**
  String get habitWhyLabel;

  /// No description provided for @habitWhyHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب سببك، فهو يُذكّرك في أوقات الضعف'**
  String get habitWhyHint;

  /// No description provided for @reminderTime.
  ///
  /// In ar, this message translates to:
  /// **'وقت التذكير بتسجيل تقدمك اليومي'**
  String get reminderTime;

  /// No description provided for @startJourney.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ الرحلة'**
  String get startJourney;

  /// No description provided for @navToday.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get navToday;

  /// No description provided for @navStats.
  ///
  /// In ar, this message translates to:
  /// **'الإحصائيات'**
  String get navStats;

  /// No description provided for @navBadges.
  ///
  /// In ar, this message translates to:
  /// **'الدروع'**
  String get navBadges;

  /// No description provided for @navHistory.
  ///
  /// In ar, this message translates to:
  /// **'السجل'**
  String get navHistory;

  /// No description provided for @navSettings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get navSettings;

  /// No description provided for @todayTitle.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل اليوم'**
  String get todayTitle;

  /// No description provided for @urgeLevel.
  ///
  /// In ar, this message translates to:
  /// **'شدة الرغبة'**
  String get urgeLevel;

  /// No description provided for @resistanceLevel.
  ///
  /// In ar, this message translates to:
  /// **'قوة المقاومة'**
  String get resistanceLevel;

  /// No description provided for @urgeLow.
  ///
  /// In ar, this message translates to:
  /// **'لا رغبة'**
  String get urgeLow;

  /// No description provided for @urgeHigh.
  ///
  /// In ar, this message translates to:
  /// **'شديدة جداً'**
  String get urgeHigh;

  /// No description provided for @resistWeak.
  ///
  /// In ar, this message translates to:
  /// **'ضعيفة'**
  String get resistWeak;

  /// No description provided for @resistStrong.
  ///
  /// In ar, this message translates to:
  /// **'قوية جداً'**
  String get resistStrong;

  /// No description provided for @didSlipQuestion.
  ///
  /// In ar, this message translates to:
  /// **'هل تعثّرت اليوم؟'**
  String get didSlipQuestion;

  /// No description provided for @yes.
  ///
  /// In ar, this message translates to:
  /// **'نعم'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In ar, this message translates to:
  /// **'لا'**
  String get no;

  /// No description provided for @moodLabel.
  ///
  /// In ar, this message translates to:
  /// **'مزاجك العام'**
  String get moodLabel;

  /// No description provided for @noteLabel.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة اليوم (اختياري)'**
  String get noteLabel;

  /// No description provided for @noteHint.
  ///
  /// In ar, this message translates to:
  /// **'كيف كان يومك؟ وما التحسّن الذي لاحظته؟'**
  String get noteHint;

  /// No description provided for @saveEntry.
  ///
  /// In ar, this message translates to:
  /// **'حفظ تسجيل اليوم'**
  String get saveEntry;

  /// No description provided for @entrySaved.
  ///
  /// In ar, this message translates to:
  /// **'تمّ الحفظ بنجاح ✅'**
  String get entrySaved;

  /// No description provided for @alreadyLoggedToday.
  ///
  /// In ar, this message translates to:
  /// **'سجّلت اليوم بالفعل، ويمكنك التعديل.'**
  String get alreadyLoggedToday;

  /// No description provided for @statsDaysLogged.
  ///
  /// In ar, this message translates to:
  /// **'يوم مسجّل'**
  String get statsDaysLogged;

  /// No description provided for @statsCleanDays.
  ///
  /// In ar, this message translates to:
  /// **'يوم نظيف'**
  String get statsCleanDays;

  /// No description provided for @statsCurrentStreak.
  ///
  /// In ar, this message translates to:
  /// **'أيام متتالية'**
  String get statsCurrentStreak;

  /// No description provided for @statsLongestStreak.
  ///
  /// In ar, this message translates to:
  /// **'أطول سلسلة'**
  String get statsLongestStreak;

  /// No description provided for @statsWeek.
  ///
  /// In ar, this message translates to:
  /// **'الأسبوع'**
  String get statsWeek;

  /// No description provided for @weeklyUrgeTrend.
  ///
  /// In ar, this message translates to:
  /// **'اتجاه الرغبة في آخر الأيام'**
  String get weeklyUrgeTrend;

  /// No description provided for @avgUrge.
  ///
  /// In ar, this message translates to:
  /// **'متوسط الرغبة'**
  String get avgUrge;

  /// No description provided for @avgResistance.
  ///
  /// In ar, this message translates to:
  /// **'متوسط المقاومة'**
  String get avgResistance;

  /// No description provided for @badgesTitle.
  ///
  /// In ar, this message translates to:
  /// **'دروعك وإنجازاتك'**
  String get badgesTitle;

  /// No description provided for @badgeLocked.
  ///
  /// In ar, this message translates to:
  /// **'مُغلق'**
  String get badgeLocked;

  /// No description provided for @badgeEarnedOn.
  ///
  /// In ar, this message translates to:
  /// **'حصلت عليه'**
  String get badgeEarnedOn;

  /// No description provided for @badgeCongrats.
  ///
  /// In ar, this message translates to:
  /// **'تهانينا! درعٌ جديد'**
  String get badgeCongrats;

  /// No description provided for @badgeKeepGoing.
  ///
  /// In ar, this message translates to:
  /// **'واصِل لتفتح الدرع التالي'**
  String get badgeKeepGoing;

  /// No description provided for @historyTitle.
  ///
  /// In ar, this message translates to:
  /// **'سجل الأيام السابقة'**
  String get historyTitle;

  /// No description provided for @noHistory.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد سجلّات بعد'**
  String get noHistory;

  /// No description provided for @badgeClean.
  ///
  /// In ar, this message translates to:
  /// **'نظيف'**
  String get badgeClean;

  /// No description provided for @badgeSlip.
  ///
  /// In ar, this message translates to:
  /// **'تعثّر'**
  String get badgeSlip;

  /// No description provided for @settingsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settingsTitle;

  /// No description provided for @language.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get language;

  /// No description provided for @appearance.
  ///
  /// In ar, this message translates to:
  /// **'المظهر'**
  String get appearance;

  /// No description provided for @themeDark.
  ///
  /// In ar, this message translates to:
  /// **'داكن'**
  String get themeDark;

  /// No description provided for @showReligiousContent.
  ///
  /// In ar, this message translates to:
  /// **'إظهار المحتوى الديني التحفيزي'**
  String get showReligiousContent;

  /// No description provided for @remindersSettings.
  ///
  /// In ar, this message translates to:
  /// **'التذكيرات والإشعارات'**
  String get remindersSettings;

  /// No description provided for @exportData.
  ///
  /// In ar, this message translates to:
  /// **'تصدير البيانات'**
  String get exportData;

  /// No description provided for @deleteAccount.
  ///
  /// In ar, this message translates to:
  /// **'حذف الحساب'**
  String get deleteAccount;

  /// No description provided for @account.
  ///
  /// In ar, this message translates to:
  /// **'الحساب'**
  String get account;

  /// No description provided for @signIn.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب'**
  String get signUp;

  /// No description provided for @signOut.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get signOut;

  /// No description provided for @syncTitle.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب'**
  String get syncTitle;

  /// No description provided for @syncDesc.
  ///
  /// In ar, this message translates to:
  /// **'سجّل الدخول كي تتزامن بياناتك على جميع أجهزتك.'**
  String get syncDesc;

  /// No description provided for @emailLabel.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get passwordLabel;

  /// No description provided for @nameLabel.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get nameLabel;

  /// No description provided for @otpHint.
  ///
  /// In ar, this message translates to:
  /// **'رمز التحقق (OTP)'**
  String get otpHint;

  /// No description provided for @sendCode.
  ///
  /// In ar, this message translates to:
  /// **'أرسل الرمز'**
  String get sendCode;

  /// No description provided for @syncNow.
  ///
  /// In ar, this message translates to:
  /// **'زامن الآن'**
  String get syncNow;

  /// No description provided for @about.
  ///
  /// In ar, this message translates to:
  /// **'عن التطبيق'**
  String get about;

  /// No description provided for @customizeFields.
  ///
  /// In ar, this message translates to:
  /// **'تخصيص الحقول'**
  String get customizeFields;

  /// No description provided for @addFieldHint.
  ///
  /// In ar, this message translates to:
  /// **'أضف بنداً جديداً...'**
  String get addFieldHint;

  /// No description provided for @hide.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء'**
  String get hide;

  /// No description provided for @show.
  ///
  /// In ar, this message translates to:
  /// **'إظهار'**
  String get show;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف الحساب'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountBody.
  ///
  /// In ar, this message translates to:
  /// **'حذف الحساب يمحو كلّ بياناتك نهائياً ولا يمكن التراجع. (المزامنة السحابية ستُفعَّل في تحديثٍ قادم؛ وحالياً بياناتك على جهازك.)'**
  String get deleteAccountBody;

  /// No description provided for @resetData.
  ///
  /// In ar, this message translates to:
  /// **'مسح كل البيانات'**
  String get resetData;

  /// No description provided for @resetConfirm.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكّد من حذف كل البيانات؟ لا يمكن التراجع.'**
  String get resetConfirm;

  /// No description provided for @streakStartTitle.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ رحلتك اليوم'**
  String get streakStartTitle;

  /// No description provided for @streakStartBody.
  ///
  /// In ar, this message translates to:
  /// **'سجّل أوّل يوم وابنِ عادتك الجديدة'**
  String get streakStartBody;

  /// No description provided for @motivationIntention.
  ///
  /// In ar, this message translates to:
  /// **'جدّد نيّتك، والنيّة الصادقة نصف الطريق. 🤍'**
  String get motivationIntention;

  /// No description provided for @motivationPatience.
  ///
  /// In ar, this message translates to:
  /// **'الصبر مفتاح الفرج، ويومٌ نظيفٌ جديد يُسجَّل لك.'**
  String get motivationPatience;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
