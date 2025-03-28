# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Web3 related
-keep class com.ethereum.** { *; }
-keep class org.web3j.** { *; }

# Keep your model classes
-keep class com.example.pyusd_hub.models.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelable implementations
-keep class * implements android.os.Parcelable {
    static ** CREATOR;
}

# Keep Serializable implementations
-keepnames class * implements java.io.Serializable

# Keep WebView related classes
-keep class android.webkit.** { *; } 