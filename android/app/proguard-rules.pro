# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# SQLite / Drift native libs
-keep class org.sqlite.** { *; }
-dontwarn org.sqlite.**

# Play Core / Deferred Components
-dontwarn com.google.android.play.core.**
