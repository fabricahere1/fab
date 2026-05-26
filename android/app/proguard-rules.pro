# Flutter Play Store deferred components (kullanılmıyor ama referans var)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# flutter_cache_manager / sqflite
-keep class com.tekartik.sqflite.** { *; }
-keep class * extends android.database.sqlite.SQLiteOpenHelper { *; }

# OkHttp (used by flutter_cache_manager)
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-keep class okio.** { *; }

# Firebase Storage
-keep class com.google.firebase.storage.** { *; }

# Glide / image loading internals
-keep public class * implements com.bumptech.glide.module.GlideModule
-keep class * extends com.bumptech.glide.AppGlideModule { *; }

# Dart / Flutter reflection
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
