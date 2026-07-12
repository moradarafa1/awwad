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
  "user_id": "uuid | null",    // مجهّل
  "props": { },                // مفاتيح من allow-list فقط
  "platform": "web|ios|android",
  "app_version": "string",
  "occurred_at": "timestamptz"
}
```

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

## أحداث الموقع (Astro — dataLayer)

نفس النمط عبر `window.dataLayer.push({ event, ...props })`:

| الحدث | متى |
|---|---|
| `page_view` | فتح صفحة (`path`, `locale`) |
| `cta_download_clicked` | الضغط على زر التحميل (`store: ios\|android\|web`) |
| `lang_switched` | تبديل لغة الموقع (`from`, `to`) |
| `blog_read` | قراءة مقال (`slug`, `locale`) |

> الموقع لا يربط الأحداث بمستخدم؛ تُجمَّع مجهّلة فقط لتحسين الـ UX والـ SEO.

## الاحتفاظ (Retention)
- `analytics_events` Insert-only؛ تُقرأ بالأدمن عبر تجميعات SQL فقط.
- سياسة تنظيف: تجميع شهري (rollup) ثم تقليم الصفوف الخام الأقدم من 180 يوم للبقاء داخل حد 500MB.
