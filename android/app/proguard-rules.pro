# Flutter embedding
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# Flutter plugin list (GeneratedPluginRegistrant is generated code)
-keep class com.ztcd.app.** { *; }

# Google Maps Flutter
-keep class com.google.android.gms.maps.** { *; }
-keep class com.google.maps.android.** { *; }
-dontwarn com.google.android.gms.maps.**

# Google Generative AI (Gemini) – uses Gson + OkHttp reflection
-keep class com.google.ai.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keep class sun.misc.Unsafe { *; }
-dontwarn sun.misc.Unsafe

# OkHttp (transitive dep of generative-ai and other libs)
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

# Kotlin coroutines / serialization (used by Gemini SDK)
-keepclassmembers class kotlinx.coroutines.** { volatile <fields>; }
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**
-keepclasseswithmembers class kotlinx.serialization.** { *; }
-dontwarn kotlinx.serialization.**

# Geolocator
-keep class com.baseflow.geolocator.** { *; }
-dontwarn com.baseflow.geolocator.**

# Permission Handler
-keep class com.baseflow.permissionhandler.** { *; }
-dontwarn com.baseflow.permissionhandler.**

# Sensors Plus
-keep class dev.fluttercommunity.plus.sensors.** { *; }
-dontwarn dev.fluttercommunity.plus.sensors.**

# Flutter Bluetooth Serial (vendored)
-keep class io.github.edufolly.flutterbluetoothserial.** { *; }
-dontwarn io.github.edufolly.flutterbluetoothserial.**

# Keep Parcelable implementations intact (needed by Maps, Location, etc.)
-keepclassmembers class * implements android.os.Parcelable {
    static ** CREATOR;
}

# Keep Serializable classes
-keepnames class * implements java.io.Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}
