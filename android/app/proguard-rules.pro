# Flutter's deferred-components support references Play Core split-install
# classes even when unused; R8 fails to find them unless kept/ignored.
# https://docs.flutter.dev/deployment/android#enabling-multidex-support
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# google_maps_flutter
-keep class com.google.android.gms.maps.** { *; }
-dontwarn com.google.android.gms.**

# qr_code_scanner_plus / flutter_barcode_scanner_plus (ZXing + MLKit barcode backends)
-keep class com.google.zxing.** { *; }
-dontwarn com.google.zxing.**
-keep class com.google.mlkit.vision.** { *; }
-dontwarn com.google.mlkit.**

# file_picker — reflection-based platform channel handling
-keep class com.mr.flutter.plugin.filepicker.** { *; }
