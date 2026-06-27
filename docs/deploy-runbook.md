# Deploy Runbook — عوّاد (يُنفّذ بعد تحميل Supabase MCP)

> هذا دليل تنفيذي للجلسة التالية (بعد restart) أو للمالك. كل الكود جاهز؛ هذه خطوات النشر فقط.
> مشروع Supabase: `kdczbzzjezyhfxgpegqc` · URL: `https://kdczbzzjezyhfxgpegqc.supabase.co`

## 1) تطبيق المخطّط (عبر Supabase MCP — `apply_migration` أو `execute_sql`)
نفّذ بالترتيب محتوى الملفات:
1. `supabase/migrations/0001_extensions_and_helpers.sql`
2. `supabase/migrations/0002_core_tables.sql`
3. `supabase/migrations/0003_gamification_and_devices.sql`
4. `supabase/migrations/0004_analytics_and_admin.sql`

> ملاحظة: `0003` فيه `create trigger on_auth_user_created on auth.users` — يحتاج صلاحية على schema `auth` (متاحة عبر الـ MCP/الإدارة). لو رفض، انقل الـ trigger لطريقة بديلة (Auth Hook) أو طبّقه من Dashboard SQL editor.

## 2) بذر البيانات المرجعية (`execute_sql`)
نفّذ محتوى `supabase/seed.sql` (كتالوج ٢٨ عادة + ١٠ دروع، ٣ لغات).

تحقّق:
```sql
select count(*) from public.habit_catalog;     -- متوقع 28
select count(*) from public.badge_definitions; -- متوقع 10
```

## 3) نشر Edge Functions (`deploy_edge_function` أو CLI)
انشر الخمسة من `supabase/functions/`:
`login-guard` · `register-trusted-device` · `award-badges` · `account-export-delete` · `send-engagement`
(الإعدادات في `supabase/config.toml`: `login-guard` و`account-export-delete` و`send-engagement` بـ `verify_jwt=false`؛ الباقي `true`.)

## 4) تعيين المالك أدمن (بعد أول تسجيل دخول)
بعد أن ينشئ المالك حساباً في التطبيق:
```sql
insert into public.admin_users (user_id, role)
select id, 'owner' from auth.users where email = 'OWNER_EMAIL' 
on conflict do nothing;
```

## 5) إعداد الإيميل (Brevo SMTP) — Dashboard
Authentication → Emails → SMTP: host `smtp-relay.brevo.com`, port 587، user/key من Brevo، sender على الدومين. ثم عدّل قالب OTP ليرسل `{{ .Token }}` (٦ أرقام). ارفع حد Auth rate limit. (بدون هذا، تسجيل الدخول بالباسورد يعمل لكن إرسال OTP لا.)

## 6) اختبار حيّ للتطبيق
```powershell
# المفاتيح العامة مدمجة في السكربت:
ops\build-app-cloud.ps1     # يشغّل التطبيق على Chrome مع المزامنة مفعّلة
```
خطوات الاختبار: سجّل حساب جديد → أكمل الأونبوردنج → سجّل يوم → افتح الإعدادات → «حساب ومزامنة» → سجّل دخول → «زامن الآن». ثم تحقّق في DB:
```sql
select count(*) from public.profiles;
select count(*) from public.daily_entries;
```
واختبر **عزل RLS**: مستخدم لا يرى صفوف غيره.

## 7) النشر/الاستضافة (Cloudflare Pages)
- موقع: `web/` build `npm run build` out `dist` → `awwad-domain`.
- تطبيق ويب: `flutter build web --dart-define=...` out `app/build/web` → `app.awwad-domain` (noindex موجود).
- أدمن: `admin/` (انسخ `config.example.js` → `config.js`).
- حدّث `site` في `web/astro.config.mjs` و`appHref()` بالدومين الحقيقي.

## 8) keep-alive
في إعدادات ريبو GitHub: أضف Secrets `SUPABASE_URL` و`SUPABASE_ANON_KEY` (الـ Action موجود في `.github/workflows/keep-alive.yml`). + pinger ثانٍ (cron-job.org) + UptimeRobot.
