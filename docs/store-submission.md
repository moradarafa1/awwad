# دليل رفع المتاجر — عوّاد (App Store + Google Play)

> أنت ترفع التطبيق بنفسك. هذا الدليل يغطّي التجهيز والخطوات وأسباب الرفض الشائعة.

## التكاليف (تخص المالك)
- Apple Developer Program: **99$/سنة** (متكرر، إلزامي للنشر على App Store).
- Google Play: **25$ مرة واحدة**.
- iOS يحتاج جهاز **Mac** للبناء والرفع (Xcode/Transporter) — لا بديل على ويندوز.

## قبل الرفع — قائمة الجاهزية
- [ ] **حذف الحساب يعمل** داخل التطبيق (الإعدادات → الحساب → حذف) + صفحة ويب `/delete-account` تقبل الطلب بدون تسجيل دخول (موجودة بالـ٣ لغات).
- [ ] **Privacy Policy** منشورة على رابط عام (`/privacy`) — تُدخَل في المتجرين.
- [ ] **Terms** على `/terms`.
- [ ] **إخلاء مسؤولية طبي** داخل التطبيق (الأونبوردنج + الإعدادات) — مهم لموضوع نتف الشعر.
- [ ] أيقونات: 1024×1024 (Apple) و512×512 (Play) + **Adaptive icon** أندرويد (foreground/background/monochrome).
- [ ] Splash screen (iOS + Android 12+).
- [ ] لقطات شاشة: عربي + إنجليزي + فرنسي، بمقاسات الأجهزة المطلوبة.
- [ ] Feature graphic (Play): 1024×500.
- [ ] **حساب تجريبي للمراجعين** + **طريقة لتخطّي OTP** للمراجع (سبب رفض شائع جداً) — اذكرها في App Review Notes.
- [ ] أذونات مبرّرة فقط (إشعارات) — مع نصوص الاستخدام في Info.plist / manifest.

## الإفصاحات (لازم تطابق سلوك الـ SDKs فعلاً)
- **Apple App Privacy:** أعلن: الاسم، الإيميل، بيانات المصادقة، وبيانات تشخيص/تحليلات. اذكر **Firebase (FCM)** كمعرّفات جهاز/إشعارات. لا إعلانات ولا تتبّع طرف ثالث للإعلان.
- **Play Data Safety:** نفس البيانات + **رابط حذف الحساب** (`/delete-account`) + "البيانات تُحذف عند الطلب" + التشفير أثناء النقل. **مطابقة لسياسة الخصوصية حرفياً.**
- إفصاح **جمع بيانات الاستبيان الاختياري** (بموافقة، وقابلة للمراجعة فردياً) ضمن سياسة الخصوصية.

## بناء Android (AAB موقّع)
```bash
cd app
# أنشئ مفتاح رفع (مرة واحدة، احفظه بأمان — لا يُرفع للريبو):
keytool -genkey -v -keystore awwad-upload.jks -keyalg RSA -keysize 2048 -validity 9125 -alias upload
# اضبط android/key.properties (storeFile, storePassword, keyAlias, keyPassword)
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
# الناتج: build/app/outputs/bundle/release/app-release.aab
```
- في Play Console: أنشئ تطبيقاً → فعّل **Play App Signing** → ارفع الـ AAB في مسار **Internal testing** أولاً.
- `applicationId = com.awwad.awwad` · اضبط `versionCode`/`versionName`.

## بناء iOS (على Mac)
```bash
cd app
flutter build ipa --release --dart-define=...   # أو افتح ios/Runner.xcworkspace في Xcode
```
- في App Store Connect: سجّل Bundle ID، أنشئ شهادة التوزيع + Provisioning Profile، ارفع عبر Xcode/Transporter، ثم **TestFlight** قبل المراجعة.

## تقييم المحتوى
- Play IARC + Apple age rating: غالباً Everyone / 4+. أجب أسئلة الصحة بصدق: التطبيق **مساعدة ذاتية سلوكية وليس تشخيصاً أو علاجاً**. تجنّب أي ادعاء بـ"علاج/شفاء".

## أسباب الرفض الشائعة (تجنّبها)
1. **المراجع عَلِق في شاشة OTP** → وفّر حساب تجريبي + كود تخطّي.
2. **حذف الحساب غير قابل للوصول** (5.1.1(v)) → تأكّد من المسار بدون تسجيل دخول.
3. **محتوى صحّي/نفسي** بدون disclaimer → موجود.
4. **إفصاحات لا تطابق الـ SDKs** → صرّح عن Firebase.
5. **شاشات وهمية/Paywall ميت** → الـ Paywall المستقبلي مخفي تماماً في نسخة الإصدار.

## النصوص (ASO)
راجع [`docs/aso.md`](aso.md) لحزمة العناوين والكلمات المفتاحية والأوصاف بالـ٣ لغات.
