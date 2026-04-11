# ═══════════════════════════════════════════════════════════════════
#                         FLUTTER CORE
# ═══════════════════════════════════════════════════════════════════
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# ═══════════════════════════════════════════════════════════════════
#                         APP MAIN ACTIVITY
# ═══════════════════════════════════════════════════════════════════
-keep class com.chartsense.ai.app.MainActivity { *; }
-keep class com.chartsense.ai.app.** { *; }

# ═══════════════════════════════════════════════════════════════════
#                         APP LINKS / DEEP LINKS
# ═══════════════════════════════════════════════════════════════════
-keep class com.llfbandit.app_links.** { *; }

# ═══════════════════════════════════════════════════════════════════
#                         GOOGLE MOBILE ADS (AdMob)
# ═══════════════════════════════════════════════════════════════════
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# ═══════════════════════════════════════════════════════════════════
#                         FIREBASE
# ═══════════════════════════════════════════════════════════════════
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Firebase Auth
-keepattributes Signature
-keepattributes *Annotation*

# ═══════════════════════════════════════════════════════════════════
#                         GOOGLE SIGN-IN
# ═══════════════════════════════════════════════════════════════════
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }

# ═══════════════════════════════════════════════════════════════════
#                         PLAY CORE (In-App Update)
# ═══════════════════════════════════════════════════════════════════
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.appupdate.** { *; }
-keep class com.google.android.play.core.install.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# ═══════════════════════════════════════════════════════════════════
#                         IN-APP BILLING (Google Play Billing)
# ═══════════════════════════════════════════════════════════════════
-keep class com.android.vending.billing.** { *; }
-keep class com.android.billingclient.** { *; }

# ═══════════════════════════════════════════════════════════════════
#                         BETTER PLAYER / ExoPlayer / Media3
# ═══════════════════════════════════════════════════════════════════
-keep class com.jhomlala.better_player.** { *; }
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**
-keep class androidx.media3.** { *; }
-dontwarn androidx.media3.**

# ═══════════════════════════════════════════════════════════════════
#                         WEBVIEW
# ═══════════════════════════════════════════════════════════════════
-keep class io.flutter.plugins.webviewflutter.** { *; }
-keep class android.webkit.** { *; }

# ═══════════════════════════════════════════════════════════════════
#                         ONESIGNAL
# ═══════════════════════════════════════════════════════════════════
-keep class com.onesignal.** { *; }
-dontwarn com.onesignal.**

# ═══════════════════════════════════════════════════════════════════
#                         OKHTTP / RETROFIT (used by many SDKs)
# ═══════════════════════════════════════════════════════════════════
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-dontwarn javax.annotation.**

# ═══════════════════════════════════════════════════════════════════
#                         GSON (used by Firebase / Google libs)
# ═══════════════════════════════════════════════════════════════════
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# ═══════════════════════════════════════════════════════════════════
#                         KOTLIN
# ═══════════════════════════════════════════════════════════════════
-dontwarn kotlin.**
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }
-dontwarn kotlinx.coroutines.**

# ═══════════════════════════════════════════════════════════════════
#                         ANDROIDX
# ═══════════════════════════════════════════════════════════════════
-keep class androidx.** { *; }
-dontwarn androidx.**
-keep class androidx.lifecycle.** { *; }

# ═══════════════════════════════════════════════════════════════════
#                         IMAGE PICKER / FILE PICKER
# ═══════════════════════════════════════════════════════════════════
-keep class io.flutter.plugins.imagepicker.** { *; }
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# ═══════════════════════════════════════════════════════════════════
#                         SHARE PLUS
# ═══════════════════════════════════════════════════════════════════
-keep class dev.fluttercommunity.plus.share.** { *; }

# ═══════════════════════════════════════════════════════════════════
#                         PATH PROVIDER
# ═══════════════════════════════════════════════════════════════════
-keep class io.flutter.plugins.pathprovider.** { *; }

# ═══════════════════════════════════════════════════════════════════
#                         URL LAUNCHER
# ═══════════════════════════════════════════════════════════════════
-keep class io.flutter.plugins.urllauncher.** { *; }

# ═══════════════════════════════════════════════════════════════════
#                         SHARED PREFERENCES
# ═══════════════════════════════════════════════════════════════════
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# ═══════════════════════════════════════════════════════════════════
#                         VIDEO THUMBNAIL
# ═══════════════════════════════════════════════════════════════════
-keep class xyz.appmaker.video_thumbnail.** { *; }

# ═══════════════════════════════════════════════════════════════════
#                         PACKAGE INFO PLUS
# ═══════════════════════════════════════════════════════════════════
-keep class dev.fluttercommunity.plus.packageinfo.** { *; }

# ═══════════════════════════════════════════════════════════════════
#                         PERMISSION HANDLER
# ═══════════════════════════════════════════════════════════════════
-keep class com.baseflow.permissionhandler.** { *; }

# ═══════════════════════════════════════════════════════════════════
#                         GENERAL R8 SAFETY
# ═══════════════════════════════════════════════════════════════════
# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelables
-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}

# Keep Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep R class fields (resource IDs)
-keepclassmembers class **.R$* {
    public static <fields>;
}

# Suppress warnings for missing classes from optional dependencies
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**
-dontwarn java.lang.invoke.**
-dontwarn com.google.errorprone.annotations.**
