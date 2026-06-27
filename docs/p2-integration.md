# تفعيل السحابة (P2/P3) — Auth + المزامنة

> الكود **مكتوب ومهيّأ** في التطبيق، لكنه **معطّل افتراضياً** ويحتاج اختباراً حياً مع مشروع Supabase حقيقي (مفيش Docker محلياً عندنا الآن).

## إزاي تفعّله
1. جهّز Supabase وانشر الـ migrations + Edge Functions (راجع [`setup-accounts.md`](setup-accounts.md)).
2. ابنِ/شغّل التطبيق مع المفاتيح:
   ```bash
   flutter run -d chrome \
     --dart-define=SUPABASE_URL=https://YOUR.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
   ```
3. أول ما المفاتيح موجودة، يظهر في الإعدادات قسم **«حساب ومزامنة»** (مخفي بدونها).

## اللي اتعمل (كود جاهز)
- `core/cloud/supabase_service.dart`: تهيئة + تسجيل/دخول بإيميل وباسورد + **OTP بالإيميل** (`sendLoginOtp`/`verifyEmailOtp`) + استدعاء Edge Functions (`login-guard`, `register-trusted-device`).
- `core/cloud/sync_service.dart`: **Push/Pull** للعادة + التسجيلات اليومية + الاستبيان (upsert على المفاتيح الطبيعية، LWW).
- `features/auth/auth_screen.dart`: واجهة دخول/تسجيل + مسار OTP، وبعد النجاح تسحب السحابة وتدمج محلياً ثم ترفع.
- الإعدادات: «زامن الآن» + «تسجيل الخروج».

## اللي محتاج اختبار حيّ أو إكمال (P2/P3)
- [ ] اختبار end-to-end لتدفّق التسجيل/الدخول/الـ OTP مع SMTP حقيقي.
- [ ] **الجهاز الموثوق:** توليد device_secret وتخزينه في `flutter_secure_storage`، واستدعاء `login-guard`/`register-trusted-device` في تدفّق الدخول (الدوال جاهزة في `SupabaseService`، يتبقّى ربطها بالـ UI).
- [ ] مزامنة **اختيارات القوائم** (`entry_selections`) والحقول المخصّصة (`custom_field_defs`) — حالياً تتزامن السكالرز الأساسية فقط.
- [ ] ترقية التخزين المحلي من `shared_preferences` إلى **Drift + outbox** (خلف نفس واجهة `LocalStore`) لمزامنة دلتا أكفأ.
- [ ] ربط `account-export-delete` بزر حذف الحساب (حالياً يمسح محلياً).

## ملاحظة أمان (مهمة وصريحة)
الـ OTP بالإيميل + الجهاز الموثوق = **تحقّق دخول**، وليس 2FA لا يُخترق (Supabase بيرجّع جلسة بعد الباسورد). مُقوّى بالـ rate limits وتدوير السرّ وإعادة الطلب عند تغيّر الـ IP، وموثّق على هذا الأساس.
