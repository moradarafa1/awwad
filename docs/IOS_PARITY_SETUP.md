# دليل تكافؤ iOS - خطوات الماك الوحيدة المتبقية

> كل كود iOS جاهز في المستودع. المتبقي خطوات لا تتم إلا من Xcode على جهاز ماك،
> وكلها موصوفة هنا خطوة خطوة. بعد تنفيذها يصبح سلوك iOS مطابقاً لأندرويد في:
> ودجت الشاشة الرئيسية (بالسلسلة والتسجيل السريع) وصوت الأذان.

## 1) ودجت الشاشة الرئيسية (WidgetKit)

الملفات جاهزة في المستودع:
- `app/ios/AwwadWidget/AwwadWidgetBundle.swift` و `AwwadWidget.swift` (الامتداد نفسه)
- `app/ios/Runner/AwwadQuickLogIntent.swift` (زر التسجيل السريع، iOS 17+)

الخطوات في Xcode (مرة واحدة):
1. افتح `app/ios/Runner.xcworkspace`.
2. File ثم New ثم Target ثم «Widget Extension». الاسم: `AwwadWidget`
   (بدون Configuration Intent). احذف الملفات المولّدة تلقائياً داخل المجلد
   الجديد واستبدلها بملفّينا `AwwadWidgetBundle.swift` و `AwwadWidget.swift`.
3. Signing & Capabilities لكل من Runner و AwwadWidget: أضف capability باسم
   «App Groups» وفعّل المجموعة: `group.com.awwad.awwad`
   (الاسم مثبّت في الكود: kAwwadAppGroup في widget_sync.dart).
4. حدد ملف `AwwadQuickLogIntent.swift` واجعل Target Membership له في
   Runner و AwwadWidget معاً (لوحة File Inspector اليمنى).
5. إن ظهر خطأ import home_widget داخل الامتداد: نفّذ `pod install` في
   `app/ios` بعد التأكد أن Podfile يحتوي target الامتداد (أضف بلوك
   `target 'AwwadWidget' do inherit! :search_paths end` داخل target Runner
   إن لزم).
6. ابنِ وشغّل على جهاز حقيقي، وأضف الودجت من شاشة iOS الرئيسية.

ملاحظات سلوك (مطابقة لأندرويد):
- النصوص تصل مترجمة جاهزة من Flutter (aw_name/aw_streak/aw_btn_log/aw_btn_done).
- تجاوز منتصف الليل معالج داخل الامتداد (يتجدد تلقائياً بعد 00:01).
- زر التسجيل السريع يعمل والتطبيق مغلق على iOS 17+، وعلى iOS 16 يفتح التطبيق.

## 2) صوت الأذان في إشعارات iOS

قيد النظام: صوت الإشعار في iOS يجب أن يكون ملف caf/aiff/wav بطول 30 ثانية
أو أقل داخل حزمة التطبيق (لا يقبل mp3 الكامل المستخدم في أندرويد).

الخطوات على الماك:
1. انسخ ملف الأذان الأصلي (المرجع في أندرويد:
   `app/android/app/src/main/res/raw/adhan.mp3` - ملف المالك، لا يُستبدل).
2. قصّه إلى 29 ثانية وحوّله (أمر واحد في الطرفية عبر afconvert المدمج بعد
   قصّه بأي أداة، أو عبر ffmpeg إن وُجد):
   `ffmpeg -i adhan.mp3 -t 29 -af "afade=t=out:st=26:d=3" adhan29.wav`
   ثم: `afconvert -f caff -d LEI16 adhan29.wav adhan30.caf`
3. اسحب `adhan30.caf` إلى مشروع Runner في Xcode مع تفعيل
   «Copy items if needed» وعضوية Runner target (تأكد من ظهوره في
   Build Phases ثم Copy Bundle Resources).
4. في `app/lib/core/notifications/notifications_mobile.dart` بدّل
   `kIOSAdhanSoundBundled = false` إلى `true` ثم ابنِ.
   (قبل هذا التبديل يستخدم iOS صوت الإشعار الافتراضي عمداً: تسمية ملف غير
   موجود كانت ستكتم الإشعار كلياً.)

## 2.5) الإشعارات الحساسة زمنياً (دقة مواعيد الصلاة على iOS)

كود إشعارات الصلاة والأذان يرسل الآن بمستوى المقاطعة «حساس زمنياً»
(interruptionLevel: timeSensitive) حتى لا تؤجله أوضاع التركيز أو ملخص
الإشعارات المجدول - وهو المكافئ الحقيقي على iOS لإصلاح المنبهات الدقيقة
في أندرويد. خطوة الماك الوحيدة: في Xcode أضف capability باسم
«Time Sensitive Notifications» لهدف Runner (بدونها يعامل iOS الإشعار
كتنبيه عادي دون أي عطل).

## 3) ما لا يحتاج أي خطوة (جاهز أصلاً)

- دقة التوقيت: إشعارات iOS دقيقة بطبيعتها (قيد المنبهات الدقيقة خاص بأندرويد).
- صلاحية الإشعارات: تُطلب في أول فتح (alert/badge/sound) في
  notifications_mobile.dart.
- صوت خلفية للراديو وورد القرآن: Background Mode audio مضاف في Info.plist.
- شاشتا مراقبة الاستخدام ودرع DNS: غير ممكنتين تقنياً على iOS (قيود النظام)،
  والتطبيق يعرض إرشاداً بديلاً ولا ينهار (fail-open) - موثّق في
  PROJECT_STATE قسم 12.

## 4) التحقق بعد البناء على الماك

- أضف الودجت، سجّل يوماً من زرّه والتطبيق مغلق، ثم افتح التطبيق وتأكد أن
  اليوم مسجّل (المصالحة تتم عند العودة للواجهة تلقائياً).
- أوقف التطبيق كلياً وانتظر إشعار صلاة: يجب أن يصدح الأذان المقصوص.
