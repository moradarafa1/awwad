# عوّاد — Awwad

> **عوّاد.. دايماً بالخير.**
> تطبيق ويب + موبايل لتغيير العادات: تتخلّص من عادة سيّئة، أو تبني عادة جديدة — بمنهج علمي (Habit Reversal Training) وروح داعمة متوافقة مع القيم الإسلامية.

منصة غير ربحية حالياً، مبنية بالكامل على خطط مجانية (صفر تكلفة تشغيل ما عدا الدومين)، جاهزة للرفع على App Store و Google Play.

---

## 🧱 بنية المشروع (Monorepo)

```
awwad/
  app/        Flutter app  — Web + iOS + Android (المنتج الفعلي)
  web/        Astro site   — الموقع التسويقي + SEO + الصفحات القانونية (ar/en/fr)
  admin/      داش بورد الأدمن (تحليلات مجمّعة/فردية خلف صلاحية أدمن)
  supabase/   migrations (SQL + RLS) + functions/ (Edge) + seed/
  ops/        keep-alive crons + سكربتات النشر + دليل الإعداد
  assets/     أيقونات / سبلاش / لقطات المتاجر / Lottie
  docs/       الوثائق (القيم، خطة التتبّع، ربط الحسابات، رفع المتاجر، ASO)
```

## 🎯 المبادئ الحاكمة

1. **٣ لغات:** عربي (افتراضي، RTL) · إنجليزي · فرنسي (LTR). مفيش نص ثابت في الكود.
2. **توافق إسلامي:** المحتوى يحثّ على القيم والعبادات. مرجع الحلال/الحرام = [إسلام ويب](https://www.islamweb.net) مع تنويه ثابت. راجع [`docs/content-values-guideline.md`](docs/content-values-guideline.md).
3. **البساطة والسهولة والمرونة** قبل أي شيء.
4. **فانل احتفاظ محترمة:** Push + Pop-ups + إيميلات — تراعي أوقات الصلاة.
5. **بنية نظيفة + Data Layer مركزية موثّقة** — التتبّع والتعديل لاحقاً سهل. راجع [`docs/tracking-plan.md`](docs/tracking-plan.md).

## 💸 الستاك المجاني (صفر تكلفة تشغيل)

| الطبقة | الخدمة | الحد المجاني | ملاحظة |
|---|---|---|---|
| Backend / Auth / DB | **Supabase** | 500MB DB · 50k MAU | يوقف بعد 7 أيام خمول → keep-alive |
| إيميل OTP/الاحتفاظ | **Brevo SMTP** | 300/يوم | SMTP مخصّص إلزامي |
| استضافة الموقع/الأدمن/الويب | **Cloudflare Pages** | باندويدث غير محدود | الأفضل للزيرو-كوست |
| Push | **Firebase FCM** | غير محدود | يُفصح عنه للمتاجر |
| keep-alive + CI | **GitHub Actions** | مجاني (repo عام) | + cron-job.org كاحتياط |

**التكلفة:** الدومين فقط (~12$/سنة). + للنشر (تخص المالك): Apple Developer 99$/سنة، Google Play 25$ مرة واحدة.

## 🚀 التشغيل محلياً (Quick Start)

### المتطلبات
- Flutter SDK (stable) + Chrome — للتطبيق.
- Node.js 20+ — للموقع (Astro) والأدمن.
- Supabase CLI + Docker — للباك إند المحلي (اختياري للتطوير الكامل).

### 1) الموقع التسويقي
```bash
cd web
npm install
npm run dev      # معاينة محلية
npm run build    # بناء للإنتاج
```

### 2) تطبيق Flutter
```bash
cd app
flutter pub get
flutter run -d chrome        # ويب
# flutter run                # موبايل (مع محاكي/جهاز)
flutter analyze && flutter test
flutter build web            # بناء الويب
```

### 3) الباك إند (Supabase محلي)
```bash
cd supabase
supabase start               # يشغّل Postgres + Auth + Studio محلياً
supabase db reset            # يطبّق migrations + seed
```

> ربط الحسابات الحقيقية (Supabase/Brevo/Firebase/Cloudflare): راجع [`docs/setup-accounts.md`](docs/setup-accounts.md).
> رفع المتاجر: راجع [`docs/store-submission.md`](docs/store-submission.md).

## 📦 حالة المراحل

- [x] **P0 — الأساس:** هيكل + وثائق + i18n + keep-alive + بذر الكتالوج.
- [x] **P1 — الأونبوردنج + حلقة التتبّع (offline):** تطبيق Flutter كامل + **الخصخصة** + بانر مراحل HRT + الدروع/الاحتفال — ✅ يبني/يشتغل/يعدّي الاختبارات.
- [x] **الباك إند (كود):** migrations + RLS + seed + 5 Edge Functions — جاهزة للنشر (تحتاج مشروع Supabase).
- [x] **الموقع + المدوّنة:** Astro ٣٠ صفحة، ٣ لغات + SEO + Article/FAQ JSON-LD + الصفحات القانونية + الفوتر — ✅ يبني/يُعرض.
- [x] **داش بورد الأدمن:** صفحة `admin/` تقرأ الـ RPCs — ✅ تُعرض (تحتاج مفاتيح للبيانات الحية).
- [x] **الأيقونات + Splash:** مولّدة (Android adaptive + iOS + Web).
- [~] **P2 — Auth + مزامنة:** الكود **مهيّأ ومعطّل افتراضياً** (يعمل بمفاتيح Supabase) — يحتاج اختباراً حياً. راجع [`docs/p2-integration.md`](docs/p2-integration.md).
- [~] **P4 — الإشعارات + الفانل:** تنبيهات محلية + Pop-ups جاهزة؛ **FCM + سلسلة الإيميلات** تحتاج Firebase/Brevo.
- [ ] **P6 — رفع المتاجر:** لقطات + توقيع + بناء الإصدار (إعدادات Android جاهزة؛ iOS يحتاج Mac).

> راجع [`STATUS.md`](STATUS.md) لكل التفاصيل وما يحتاج طرفك.

---

© جميع الحقوق محفوظة — [Morad Arafa](https://www.linkedin.com/in/moradarafa/)
