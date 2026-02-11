import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("kotlin-kapt")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.mpcb_bio_waste.app"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.mpcb_bio_waste.app"
        minSdk = 24
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    kotlinOptions {
        jvmTarget = "17"
    }

    kotlin {
        jvmToolchain(17)
    }


    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }




    // 🔐 Release signing config
    signingConfigs {
        create("release") {
            val props = Properties()
            val propsFile = rootProject.file("key.properties")

            if (propsFile.exists()) {
                props.load(FileInputStream(propsFile))

                storeFile = file(props["storeFile"] as String)
                storePassword = props["storePassword"] as String
                keyAlias = props["keyAlias"] as String
                keyPassword = props["keyPassword"] as String
            }
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
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
    // Room
    implementation("androidx.room:room-runtime:2.8.4")
    kapt("androidx.room:room-compiler:2.8.4")

    // Optional - Kotlin extensions (safe to keep)
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
