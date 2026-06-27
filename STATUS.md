# حالة المشروع والتسليم — عوّاد

آخر تحديث: 2026-06-27

## ✅ المُنجَز والمُتحقَّق منه محلياً

### تطبيق Flutter (P1 كامل + جزء من P2/P4)
- **الأونبوردنج:** ترحيب + اختيار لغة (ar/en/fr) + إخلاء مسؤولية طبي → **استبيان اختياري** (موافقة/يُتخطّى) → **مسار إجباري** (اكسر/ابنِ) → **اختيار عادة إجباري** من كتالوج ٢٨ عادة (بحث + تصنيف، شائعة + إسلامية) + **عادة مخصّصة** → تجهيز.
- **التتبّع اليومي:** رغبة/مقاومة/تعثّر/مزاج/ملاحظة + **قوائم ديناميكية** (الاستجابة التنافسية + البيئة) + **بانر مرحلة HRT** لمسار الكسر.
- **الخصخصة:** شاشة «تخصيص الحقول» — إضافة/تعديل/إخفاء/حذف بنود لكل مجموعة.
- **الجيميفيكيشن:** دروع فضي٣٠/ذهبي٦٠/ماسي٩٠ + **احتفال confetti**.
- **الإحصائيات** (رسم بياني) · **السجل** · **الإعدادات** (تبديل لغة، محتوى ديني، تذكير، تصدير JSON، حذف حساب، مسح).
- **الفانل:** Pop-up احتفاظ داخلي (تذكير الستريك) + **تنبيهات محلية** يومية (موبايل، آمنة للويب).
- **P2 (مهيّأ، معطّل افتراضياً):** Supabase auth + OTP + **Sync (Push/Pull)** + شاشة حساب — تظهر فقط عند تمرير المفاتيح. راجع [`docs/p2-integration.md`](docs/p2-integration.md).
- **الهوية:** أيقونات (Android adaptive + iOS بلا ألفا + Web) + Splash مولّدة من شعار البذرة.
- **i18n** ٣ لغات (RTL/LTR) · ثيم داكن · **AnalyticsService** مركزية (Data Layer).
- **التحقق:** `flutter analyze` → **No issues** · `flutter test` → **5/5** · `flutter build web` → **نجح** (مع كل deps: supabase/notifications/auth) · يعمل في المتصفح بدون أخطاء console · إعداد Android للتنبيهات (desugaring + أذونات) جاهز.

### الباك إند Supabase (كود كامل — يحتاج مشروعك للنشر)
4 migrations + **RLS على كل جدول** + triggers + `is_admin()` + RPCs تجميعية (+ كشف فردي للاستبيان) · **seed** ٢٨ عادة/١٠ دروع ٣ لغات · **5 Edge Functions** (login-guard, register-trusted-device, award-badges, account-export-delete, send-engagement) · config.toml.

### الموقع التسويقي (Astro — مُتحقَّق منه)
**٣٠ صفحة** (٣ لغات): هوم + اكسر/ابنِ عادة + خصوصية/شروط/حذف الحساب + **مدوّنة** (فهرس + ٣ مقالات SEO بـ **Article + FAQPage JSON-LD**). hreflang/OG/canonical/sitemap/robots · الفوتر «© Morad Arafa → LinkedIn». **التحقق:** `npm run build` → 30 pages · يُعرض صح ٣ لغات.

### داش بورد الأدمن (`admin/` — مُتحقَّق منه)
صفحة مستقلة (noindex) تسجّل دخول أدمن وتقرأ الـ RPCs (overview/DAU/المسارين/أهم العادات/الدروع/الاستبيان). **التحقق:** تُعرض شاشة الدخول صح؛ تحتاج مفاتيح Supabase للبيانات الحية.

### الوثائق
content-values-guideline · tracking-plan · setup-accounts · store-submission · aso · **p2-integration** · ops/keep-alive · ops/icongen.

## ⏳ يحتاج طرفك (الخطوة الأخيرة)
| العنصر | المطلوب منك |
|---|---|
| تشغيل الباك إند | إنشاء مشروع Supabase + نشر migrations/functions + ربط Brevo SMTP |
| تفعيل المزامنة/الدخول | تمرير `--dart-define` بمفاتيح Supabase + اختبار حيّ (p2-integration.md) |
| Push السحابي | مشروع Firebase (FCM) — التنبيهات المحلية تعمل بدونه |
| النشر | دومين + Cloudflare Pages |
| المتاجر | حسابات App Store/Play + Mac لبناء iOS |

## ⚠️ ملاحظات أمانة
- **التخزين المحلي P1 = `shared_preferences`** (مصدر offline) — يُرقّى لـ Drift+sync في P2 خلف نفس الواجهة.
- **المزامنة الحالية** تغطّي العادة + التسجيلات + الاستبيان؛ اختيارات القوائم/الحقول المخصّصة + الجهاز الموثوق = خطوات P2/P3 التالية (موثّقة).
- **OTP إيميل + جهاز موثوق = تحقّق دخول، لا 2FA لا يُخترق** (موثّق بصدق).

## تشغيل المُنجَز الآن
```bash
cd app && flutter run -d chrome        # التطبيق (offline)
cd web && npm install && npm run dev   # الموقع
cd app && flutter analyze && flutter test
```
