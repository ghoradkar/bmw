import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("kotlin-kapt")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.bmw.app"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.bmw.app"
        minSdk = 24
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    kotlin {
        jvmToolchain(17)
    }
//    signingConfigs {
//        create("release") {
//            keyAlias = keystoreProperties["keyAlias"] as String
//            keyPassword = keystoreProperties["keyPassword"] as String
//            storeFile = file(keystoreProperties["storeFile"] as String)
//            storePassword = keystoreProperties["storePassword"] as String
//        }
//    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")

            isMinifyEnabled = true
            isShrinkResources = true

            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.room:room-runtime:2.8.4")
    kapt("androidx.room:room-compiler:2.8.4")
    implementation("androidx.room:room-ktx:2.8.4")
}


//
//plugins {
//    id("com.android.application")
//    id("kotlin-android")
//    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
//    id("dev.flutter.flutter-gradle-plugin")
//}
//
//android {
//    namespace = "com.mpcb_bio_waste.app"
//    compileSdk = flutter.compileSdkVersion
//    ndkVersion = flutter.ndkVersion
//
//    compileOptions {
//        sourceCompatibility = JavaVersion.VERSION_11
//        targetCompatibility = JavaVersion.VERSION_11
//    }
//
//    kotlinOptions {
//        jvmTarget = JavaVersion.VERSION_11.toString()
//    }
//
//    defaultConfig {
//        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
//        applicationId = "com.mpcb_bio_waste.app"
//        // You can update the following values to match your application needs.
//        // For more information, see: https://flutter.dev/to/review-gradle-config.
//        minSdk = flutter.minSdkVersion
//        targetSdk = flutter.targetSdkVersion
//        versionCode = flutter.versionCode
//        versionName = flutter.versionName
//    }
//    signingConfigs {
//        release {
//            storeFile file("bmw.jks")
//            storePassword "Pass@123"
//            keyAlias "key0"
//            keyPassword "Pass@123"
//        }
//    }
//
//    buildTypes {
//        release {
//            signingConfig signingConfigs.release
//                    minifyEnabled true
//            shrinkResources true
//            crunchPngs false
//            proguardFiles getDefaultProguardFile(
//                    "proguard-android-optimize.txt"
//                    ), "proguard-rules.pro"
//        }
//
//    }
//}
//
//flutter {
//    source = "../.."
//}
