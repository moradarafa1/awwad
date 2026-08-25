---
name: awwad-wave3-usage-monitoring
description: استكمال تلقائي لخطة عوّاد بعد ريست الليميت: تنفيذ Wave 3 مراقبة استهلاك التطبيقات + بناء ونشر
---

أنت تكمل خطة مشروع «عوّاد» (تطبيق تتبع عادات Flutter في D:\Claude\awwad) بتفويض مسبق صريح من المالك: «كمل شغلك تلقائي بعد الريست». اقرأ أولاً D:\Claude\awwad\docs\PROJECT_STATE.md (خصوصاً القسم 0 والقسم 12 بند 0c «Power features roadmap» والقسم 6 لأوامر البناء) وملف الذاكرة project_awwad.md.

المهمة: نفّذ Wave 3 من الخطة المعتمدة = مراقبة استهلاك التطبيقات لعادة «إدمان الهاتف» (المرحلة أ فقط، بدون قفل إجباري):
1. كود Kotlin أصلي في MainActivity.kt (قناة awwad/usage_stats بنفس نمط قناة awwad/dns_shield الموجودة): فحص صلاحية PACKAGE_USAGE_STATS عبر AppOpsManager، فتح شاشة Settings.ACTION_USAGE_ACCESS_SETTINGS، وقراءة استهلاك اليوم لكل تطبيق عبر UsageStatsManager (اسم الحزمة + الدقائق) مع أسماء التطبيقات القابلة للعرض من PackageManager. أضف <uses-permission android:name="android.permission.PACKAGE_USAGE_STATS" tools:ignore="ProtectedPermissions"/> في AndroidManifest الرئيسي.
2. طبقة Dart فاشلة-بأمان (fail-open) في core/platform/usage_stats.dart: أي خطأ = «غير مدعوم»، بدون كراش، و«no-op» على الويب وiOS.
3. شاشة features/phone/usage_screen.dart ثلاثية اللغة (خرائط نصوص inline بنمط dns_shield_screen، فصحى، ممنوع em-dash): حالة الصلاحية + زر منحها، قائمة استهلاك اليوم مرتبة تنازلياً، تحديد حد يومي بالدقائق لكل تطبيق (يُحفظ في SharedPreferences عبر نمط LocalStore الموجود أو مفاتيح مستقلة)، ومؤشر تجاوز الحد بلون تحذيري. تحذير الإشعارات عند التجاوز يتطلب فحصاً دورياً في الخلفية - نفّذه بأبسط شكل آمن: فحص عند فتح التطبيق فقط في هذه المرحلة، ووثّق أن الفحص الدوري بالخلفية مرحلة لاحقة.
4. مدخل للشاشة: بطاقة في daily_log_screen تظهر فقط عندما تكون العادة النشطة catalogKey == 'phone_addiction' + بند في الإعدادات.
5. تحقق: flutter analyze نظيف + flutter test كلها تنجح (أضف اختبارات لأي منطق صافٍ مثل تحويل الدقائق). البناء بالأوامر الدقيقة في PROJECT_STATE §6 (Flutter في D:\flutter\bin\flutter.bat، مفاتيح --dart-define إلزامية، تحقق من صلاحية INTERNET بعد بناء الـ release).
6. النشر: انسخ app/build/web إلى مجلد app/ في مستودع github.io (الخطوات في ذاكرة project_awwad_hosting: clone https://github.com/moradarafa1/moradarafa1.github.io ثم استبدال /app/ مع نسخ index.html إلى 404.html والحفاظ على .nojekyll ثم push) وتحقق من تطابق حجم main.dart.js بالبايت مع النسخة الحية. ثم commit وpush للمصدر في D:\Claude\awwad (هوية git: Morad Arafa <olenshop.sa@gmail.com>).
7. حدّث docs/PROJECT_STATE.md (changelog + علّم Wave 3 مرحلة أ كمنجزة في بند 0c) وملف الذاكرة project_awwad.md.
8. أرسل للمالك رسالة عربية (مصرية) واضحة: ما أُنجز، مسار الـ APK الجديد (D:\Claude\awwad\app\build\app\outputs\flutter-apk\app-release.apk)، وخطوات الاختبار على جهازه (منح صلاحية Usage Access وتجربة الشاشة) - الكود الأصلي غير مجرب على جهاز حقيقي فذكّره بذلك بصراحة.

قواعد صارمة: صفر تكلفة تشغيلية، لا تنشئ مشروع Supabase ثانياً، لا تنشر على Netlify إطلاقاً، العربية فصحى بلا em-dash في أي نص داخل المنتج، الكود الأصلي fail-open دائماً، ولا تحذف مستخدمي auth الحقيقيين (المالك + Menna). إن تعذّر أمر ما فوثّقه في PROJECT_STATE وأكمل الباقي. إن وجدت الليميت ما زال فعالاً فأنهِ فوراً بأقل استهلاك واكتب أن المحاولة القادمة تحتاج إعادة جدولة.