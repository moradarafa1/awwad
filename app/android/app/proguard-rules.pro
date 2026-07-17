# flutter_local_notifications: scheduled notifications are serialized with
# GSON, whose generic-type reflection R8 strips in release builds. Without
# these keep rules every zonedSchedule() call throws in RELEASE ONLY (debug
# and tests pass), the runZonedGuarded zone swallows the error, and the user
# simply never receives a reminder. This is the documented fix from the
# plugin's own release-configuration notes. Do not remove.
-keep class com.dexterous.** { *; }
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}
-dontwarn com.google.errorprone.annotations.**
-dontwarn sun.misc.**
