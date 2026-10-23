# ==============================================================================
# SubZero - ProGuard / R8 Configuration Rules
# ==============================================================================

# Flutter Core & Platform Channels
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# ------------------------------------------------------------------------------
# 1. HIVE & MODEL ADAPTERS
# ------------------------------------------------------------------------------
# Preservar modelos DTO de inventario y sus adaptadores generados de Hive
-keep class dev.matute.subzero.features.inventory.data.models.** { *; }
-keepclassmembers class dev.matute.subzero.features.inventory.data.models.** { *; }

# Clases internas y adaptadores binarios de Hive
-keep class * extends io.flutter.plugin.common.StandardMessageCodec { *; }
-dontwarn hive.**

# ------------------------------------------------------------------------------
# 2. GOOGLE MOBILE ADS (ADMOB) SDK
# ------------------------------------------------------------------------------
-keep class com.google.android.gms.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# ------------------------------------------------------------------------------
# 3. FLUTTER LOCAL NOTIFICATIONS
# ------------------------------------------------------------------------------
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.google.gson.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# ------------------------------------------------------------------------------
# 4. IN-APP PURCHASE & GOOGLE PLAY BILLING
# ------------------------------------------------------------------------------
-keep class com.android.billingclient.** { *; }
-keep class io.flutter.plugins.inapppurchase.** { *; }
-dontwarn com.android.billingclient.**

