# Keep OkHttp3 classes
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**

# Keep Okio (required by OkHttp)
-keep class okio.** { *; }
-dontwarn okio.**

# === Critical: Prevent removal of optional TLS platform classes that OkHttp uses via reflection ===
-keep class org.conscrypt.** { *; }
-keep class org.bouncycastle.jsse.** { *; }
-keep class org.openjsse.** { *; }

-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.jsse.**
-dontwarn org.openjsse.**

# Alternative (slightly more aggressive but 100% safe)
# -keep class com.google.crypto.** { *; }
# -keep class org.conscrypt.** { *; }
# -keep class org.bouncycastle.** { *; }
# -keep class org.openjsse.** { *; }