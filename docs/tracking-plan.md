# خطة التتبّع — عوّاد (Tracking Plan / Data Layer)

> مرجع واحد لكل الأحداث. الهدف: تتبّع **بسيط** لفهم سلوك المستخدم وتحسين التجربة لاحقاً، **بدون أي PII**. كل حدث يمرّ عبر طبقة مركزية واحدة (`AnalyticsService` في التطبيق / `dataLayer` على الويب) فتُكتب في جدول `analytics_events` بـ Supabase. إضافة حدث جديد لاحقاً = إدخال هنا + سطر واحد في الكود.

---

## مبادئ

1. **نقطة واحدة:** `AnalyticsService.track(event, props)` — ممنوع استدعاء التتبّع من أماكن متفرّقة بطرق مختلفة.
2. **Allow-list صارم للخصائص:** فقط الخصائص المذكورة هنا تُرسَل. **لا أسماء عادات، لا ملاحظات، لا إيميلات، لا أي نص يكتبه المستخدم.**
3. **أسماء الأحداث:** `snake_case`، بالإنجليزية، فعل + كائن (`entry_saved`، `track_selected`).
4. **بدون PII:** `user_id` فقط (UUID مجهّل) للربط؛ الباقي قيم محصورة (enums/أرقام).
5. **التحقّق:** أي حدث جديد يُراجَع مقابل هذه الوثيقة قبل الدمج (نستعين بـ product-tracking skills).

## مخطّط الحدث (Event Schema)

```jsonc
{
  "event_name": "string",      // من القائمة أدناه
  "user_id": "uuid | null",    // مجهّل، يُختَم وقت الدفع (null قبل تسجيل الدخول)
  "props": { },                // مفاتيح من allow-list فقط + locale
  "platform": "web|ios|android",
  "app_version": "string",
  "occurred_at": "timestamptz"
}
```

### معايير قياسية تُضاف تلقائياً (منذ 2026-07-14)

كل حدث يمرّ عبر `AnalyticsService.track` يُثرى تلقائياً بـ:

- `platform`: من المنصة الفعلية (`web` / `android` / `ios`) وتُخزَّن في عمودها المخصّص.
- `app_version`: ثابت `1.0.0` (يُرفَع مع كل إصدار، متزامن مع سطر الإصدار في الإعدادات) وتُخزَّن في عمودها المخصّص.
- `locale`: لغة الواجهة الحالية (`ar|en|fr`) داخل `props`.
- أحداث العادات تمرّر إضافياً `habit_track` (break|build) و`catalog_key` حيث يكون ذلك ملائماً (مثل `entry_saved` و`habit_added`)، ولا تمرّر أبداً اسم العادة الحرّ الذي كتبه المستخدم.

### الدفع إلى السحابة (Flush)

الأحداث تُخزَّن مؤقتاً في الذاكرة ثم تُدفَع دفعة واحدة إلى جدول `analytics_events` (INSERT فقط عبر سياسة RLS «`user_id` فارغ أو يساوي `auth.uid()`»، والقراءة محجوبة تماماً عن العملاء):

1. **عند فتح التطبيق**: بعد تهيئة السحابة (بعد أول إطار، لا يحجب الإقلاع أبداً).
2. **بعد كل حفظ تسجيل يومي**: دفع خلفي بدون انتظار.

الفشل آمن دائماً (fail-open): أي خطأ شبكة يُبقي الأحداث في الذاكرة للمحاولة التالية، وسقف التخزين المؤقت 200 حدث (الأقدم يُسقَط). لا يوجد تخزين دائم للأحداث غير المدفوعة بين تشغيلات التطبيق، وهذا مقبول عمداً لهذا الحجم.

## قائمة الأحداث (Event Catalog)

| الحدث | متى يُطلَق | الخصائص المسموحة (allow-list) |
|---|---|---|
| `app_opened` | فتح التطبيق/الموقع | `is_first_open: bool` |
| `onboarding_started` | بدء الأونبوردنج | — |
| `language_selected` | اختيار اللغة | `locale: ar\|en\|fr` |
| `survey_shown` | ظهور الاستبيان الاختياري | — |
| `survey_completed` | إكمال الاستبيان | `consent: bool`, `fields_count: int` |
| `survey_skipped` | تخطّي الاستبيان | — |
| `track_selected` | اختيار المسار | `track: break\|build` |
| `habit_selected` | اختيار عادة من الكتالوج | `catalog_key: string`, `category: string`, `is_islamic: bool` |
| `habit_custom_created` | إنشاء عادة مخصّصة | `track: break\|build`, `category: string` |
| `onboarding_completed` | إنهاء الأونبوردنج | `track: break\|build`, `is_custom: bool` |
| `signup_succeeded` | إنشاء حساب | `method: email` |
| `login_succeeded` | تسجيل دخول ناجح | `otp_required: bool`, `trusted_device: bool` |
| `otp_sent` | إرسال كود OTP | — |
| `otp_verified` | تأكيد كود OTP | `success: bool` |
| `device_trusted` | توثيق جهاز | — |
| `sos_opened` | فتح شاشة «لحظة ضعف» | — |
| `sos_won` | إنهاء لحظة الضعف بنجاح (زر انتصرت) | — |
| `entry_saved` | حفظ تسجيل يومي | `did_slip: bool`, `urge: int`, `resistance: int`, `events_count: int` |
| `streak_milestone` | بلوغ حدّ ستريك | `days: int` |
| `badge_earned` | فتح درع | `badge_key: string`, `tier: string` |
| `badge_celebrated` | مشاهدة احتفال الدرع | `badge_key: string` |
| `custom_field_added` | إضافة حقل مخصّص | `group: string` |
| `reminder_set` | ضبط تذكير | `hour: int` |
| `notification_opened` | فتح إشعار | `type: daily\|streak_risk\|badge\|winback` |
| `popup_shown` | ظهور Pop-up | `type: string` |
| `popup_cta_clicked` | الضغط على CTA في Pop-up | `type: string` |
| `data_exported` | تصدير البيانات | `format: json\|text` |
| `account_deletion_requested` | طلب حذف الحساب | `source: in_app\|web` |
| `religious_content_toggled` | إظهار/إخفاء المحتوى الديني | `visible: bool` |
| `auth_choice` | شاشة الفتح الأولى (حساب أم ضيف) | `guest: bool` |
| `account_prompt_accepted` | قبول اقتراح إنشاء حساب بعد أول تسجيل | — |
| `account_prompt_declined` | رفض اقتراح إنشاء حساب | — |
| `habit_added` | إضافة عادة جديدة (تعدّد العادات) | `track`, `is_custom: bool`, `catalog_key`, `total_habits: int` |
| `habit_switched` | تبديل العادة النشطة | `habit_id` (معرّف محلي، ليس اسماً) |
| `habit_removed` | حذف عادة | `habit_id` |
| `add_habit_opened` | فتح شاشة إضافة عادة | — |
| `habit_reminders_set` | تعديل أوقات تذكير عادة | `count: int` |
| `notifications_toggled` | تفعيل/تعطيل الإشعارات | `enabled: bool` |
| `dhikr_toggled` | تفعيل/تعطيل ذكر اليوم | `enabled: bool` |
| `pomodoro_start` | بدء جلسة بومودورو | `phase: focus\|break` |
| `pomodoro_complete` | اكتمال مرحلة بومودورو | `phase: focus\|break` |

> ملاحظة: `entry_saved` تمرّر الآن أيضاً `habit_track` و`catalog_key` (انظر المعايير القياسية أعلاه).

## أحداث الموقع (Astro — dataLayer + GTM)

نفس النمط عبر `window.dataLayer.push({ event, ...props })`. المنفَّذ فعلياً في `Base.astro`:

| الحدث | متى | الخصائص |
|---|---|---|
| `page_view` | فتح أي صفحة | `path`, `locale` |
| `cta_click` | الضغط على أزرار التحويل الرئيسية | `cta: download\|webapp\|store`, `locale` |

تفاصيل `cta_click`: زر «حمّل التطبيق» يدفع `download`؛ زر «استخدم نسخة الويب» يدفع `webapp`؛ زرّا أندرويد/iOS داخل نافذة اختيار المنصة يدفعان `store` عندما يكون المتجر منشوراً فعلاً (`androidLive`/`iosLive`) و`webapp` قبل النشر لأن الرابط يذهب حينها إلى نسخة الويب.

### حاوية GTM (مُبوَّبة بمعرّف فارغ)

- الثابت `GTM_ID` في `web/src/content/site.js` يتحكّم في كل شيء: **قيمة فارغة = لا يُحقَن أي سكربت طرف ثالث إطلاقاً** ويبقى الموقع بلا كوكيز، مع بقاء دفعات dataLayer تعمل محلياً بلا أثر.
- عند وضع معرّف حقيقي (`GTM-XXXXXXX`) يُحقَن سكربت GTM في `<head>` + وسم `<noscript>` بعد فتح `<body>` في كل الصفحات تلقائياً.
- **تنبيه خصوصية للمالك:** بمجرد ضبط `GTM_ID` تسري كوكيز GTM/GA على الزوار، ويجب تحديث صفحة الخصوصية بما يعكس ذلك قبل التفعيل.

> الموقع لا يربط الأحداث بمستخدم؛ تُجمَّع مجهّلة فقط لتحسين الـ UX والـ SEO. أحداث مقترحة لاحقاً (غير منفَّذة): `lang_switched`، `blog_read`.

## جدول مطابقة الأسماء (GA4 / MMP mapping)

عند ربط GTM بـ GA4 أو ربط تطبيق بمنصّة قياس (MMP) لاحقاً، تُستخدم هذه المطابقة كي تبقى القمع (funnels) موحّدة عبر المنصات:

| حدثنا الداخلي | GA4 الموصى به | AppsFlyer/Adjust (MMP) | ملاحظات |
|---|---|---|---|
| `app_opened` | `session_start` (تلقائي) + `app_open` | `af_app_opened` / session | `is_first_open` يقابل First Open التلقائي |
| `onboarding_started` | `tutorial_begin` | `af_tutorial_begin` | قياسي في GA4 |
| `onboarding_completed` | `tutorial_complete` | `af_tutorial_completion` | قياسي في GA4 |
| `signup_succeeded` | `sign_up` (method) | `af_complete_registration` | قياسي |
| `login_succeeded` | `login` | `af_login` | قياسي |
| `entry_saved` | `log_entry` (مخصّص) | `af_level_achieved` أو مخصّص | الحدث الأهم للاحتفاظ (retention) |
| `badge_earned` | `unlock_achievement` (achievement_id = badge_key) | `af_achievement_unlocked` | قياسي |
| `habit_added` | `add_habit` (مخصّص) | مخصّص | مع `habit_track`/`catalog_key` |
| `sos_opened` / `sos_won` | مخصّصان بنفس الاسم | مخصّصان | مؤشّر القيمة الأساسية للمنتج |
| `cta_click` (الموقع) | `select_content` أو `cta_click` | لا ينطبق (ويب) | trigger جاهز في GTM على event=cta_click |
| `page_view` (الموقع) | `page_view` (تلقائي في GA4 عبر GTM) | لا ينطبق | الدفعة اليدوية تبقى للتوافق |

## منصّة قياس التثبيتات MMP (بند مؤجّل بانتظار المالك)

ربط AppsFlyer أو Adjust **مؤجّل عمداً ولا يُضاف أي SDK الآن**، لأنه يتطلب من المالك:

1. إنشاء حساب على المنصّة المختارة (الخطة المجانية كافية للبداية).
2. تزويدنا بمفتاح التطبيق (Dev Key) ومعرّفات المتاجر بعد النشر.
3. عندها فقط: نضيف حزمة الـ SDK للتطبيق، ونفعّل مطابقة الأسماء من الجدول أعلاه، ونوثّق نافذة الإسناد (attribution window) المختارة هنا.

إلى أن يحدث ذلك، حملات الويب تُقاس عبر GTM/GA4 بمجرد ضبط `GTM_ID`، وحملات التطبيق تُقاس بروابط Google Play referrer الافتراضية.

## الاحتفاظ (Retention)
- `analytics_events` Insert-only؛ تُقرأ بالأدمن عبر تجميعات SQL فقط.
- سياسة تنظيف: تجميع شهري (rollup) ثم تقليم الصفوف الخام الأقدم من 180 يوم للبقاء داخل حد 500MB.
