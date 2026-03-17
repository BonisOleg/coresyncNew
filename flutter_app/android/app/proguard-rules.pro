# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Stripe
-dontwarn com.stripe.android.**
-keep class com.stripe.android.** { *; }

# Google Pay
-dontwarn com.google.android.gms.**
-keep class com.google.android.gms.wallet.** { *; }
