# دليل ربط الحسابات والإطلاق (صفر تكلفة) — عوّاد

> الهدف: تشغيل المشروع حقيقياً على خطط مجانية بالكامل. الدفع الوحيد = الدومين (~12$/سنة). كل خطوة فيها "ليه" و"إزاي".

## 0) الترتيب الموصى به
1. Supabase (الباك إند) → 2. Brevo (إيميل OTP) → 3. Firebase (FCM) → 4. الدومين + Cloudflare Pages → 5. keep-alive → 6. ربط التطبيق.

---

## 1) Supabase (Auth + DB + RLS + Edge Functions)
1. اعمل حساب على [supabase.com](https://supabase.com) → New Project (اختر أقرب Region، مثلاً Frankfurt). احفظ كلمة مرور قاعدة البيانات.
2. من **Project Settings → API**: انسخ `Project URL` و`anon public key` و`service_role key` (الأخير سرّي — لا يُشحَن للعميل أبداً).
3. ثبّت Supabase CLI: `npm i -g supabase` ثم `supabase login`.
4. اربط المشروع وادفع المخطّط:
   ```bash
   cd supabase
   supabase link --project-ref <your-ref>
   supabase db push          # يطبّق migrations/
   supabase db dump --data-only   # (اختياري) للتأكد
   # طبّق seed.sql مرة واحدة:
   psql "<connection-string>" -f seed.sql
   ```
   بديل محلي للتجربة: `supabase start` ثم `supabase db reset` (يطبّق migrations + seed تلقائياً).
5. انشر الـ Edge Functions:
   ```bash
   supabase functions deploy login-guard register-trusted-device award-badges account-export-delete send-engagement
   ```
6. عيّن نفسك أدمن (لرؤية الداش بورد):
   ```sql
   insert into public.admin_users (user_id) values ('<your-auth-uid>');
   ```

## 2) Brevo (Custom SMTP لإيميلات OTP) — إلزامي
> SMTP المدمج في Supabase محدود بـ ~2/ساعة ويرسل لفريقك فقط = يكسر تسجيل الدخول. لازم SMTP مخصّص.
1. حساب مجاني على [brevo.com](https://www.brevo.com) (300 إيميل/يوم مجاناً).
2. **Senders & Domains → Domains**: أضف دومينك وفعّل **SPF + DKIM** (DNS) — مهم جداً عشان الـ OTP ما يروحش Spam.
3. **SMTP & API → SMTP**: انسخ `login` و`SMTP key`.
4. في Supabase: **Authentication → Emails → SMTP Settings → Enable Custom SMTP**:
   - Host: `smtp-relay.brevo.com` · Port: `587` · User: (Brevo login) · Pass: (SMTP key)
   - Sender: `no-reply@<your-domain>` · Sender name: `عوّاد Awwad`
5. **Authentication → Rate Limits**: ارفع حد إيميلات الـ Auth من 30/ساعة (لكن ابقَ ضمن 300/يوم).
6. **Authentication → Email Templates → Magic Link/OTP**: عدّل القالب ليُرسل كود 6 أرقام `{{ .Token }}` بنص عربي/إنجليزي/فرنسي.

## 3) Firebase Cloud Messaging (إشعارات Push — مجاني)
1. أنشئ مشروع على [console.firebase.google.com](https://console.firebase.google.com) (مجاني، حتى لو الباك إند Supabase).
2. أضف تطبيقات: Android (package `com.awwad.awwad`) + iOS (Bundle ID) + Web.
3. حمّل `google-services.json` (Android) و`GoogleService-Info.plist` (iOS) وضعهم في مساراتهم بمشروع Flutter (موجودة في `.gitignore`).
4. شغّل `flutterfire configure` لتوليد `firebase_options.dart` (P4).
5. iOS: ارفع مفتاح APNs في Firebase.

## 4) الدومين + Cloudflare Pages (استضافة مجانية، باندويدث غير محدود)
1. اشترِ دومين (مثلاً من Cloudflare Registstrar أو Namecheap) ووجّه DNS إلى Cloudflare.
2. **Cloudflare Pages → Create project**:
   - مشروع 1 (الموقع التسويقي): اربط ريبو `web/`، Build command: `npm run build`، Output: `dist`. الدومين: `awwad.com` (مثال).
   - مشروع 2 (تطبيق Flutter web): Build: `flutter build web`، Output: `build/web`، الدومين: `app.awwad.com`. **أضف `noindex`** عبر `_headers` أو meta.
3. حدّث `site` في `web/astro.config.mjs` و`appHref()` بالدومين الحقيقي.

## 5) keep-alive (يمنع توقّف Supabase بعد 7 أيام)
1. انسخ `ops/keep-alive.yml` إلى `.github/workflows/keep-alive.yml` في ريبو **عام**.
2. أضف Secrets: `SUPABASE_URL`, `SUPABASE_ANON_KEY`.
3. أضف **pinger ثانٍ** على [cron-job.org](https://cron-job.org) (مجاني) على نفس رابط REST.
4. أضف مراقبة [UptimeRobot](https://uptimerobot.com) (مجاني) على endpoint صحّي عشان يجيلك إيميل لو وقع.

## 6) ربط تطبيق Flutter بالباك إند (P2)
- مرّر المفاتيح وقت البناء عبر `--dart-define`:
  ```bash
  flutter build web --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
  ```
- `service_role key` لا يُستخدم في التطبيق إطلاقاً — فقط داخل Edge Functions.

## ملخص الحدود المجانية (راقبها)
| الخدمة | الحد | لو اقتربت |
|---|---|---|
| Supabase DB | 500MB | فعّل rollup/تقليم `analytics_events` |
| Brevo | 300 إيميل/يوم | "وثّق الجهاز" يقلّل الـ OTP؛ Resend احتياطي |
| Cloudflare Pages | باندويدث ∞ | مفيش قلق |
| Firebase FCM | ∞ | مفيش قلق |
