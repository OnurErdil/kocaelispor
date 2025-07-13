// android/app/build.gradle.kts - DÜZELTİLMİŞ SÜRÜM

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // ✅ Firebase plugin ekleyin
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.kocaelispor_1966_mobil"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.kocaelispor_1966_mobil"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // ✅ Push notification için multiDexEnabled ekleyin
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
dependencies {
    implementation("androidx.multidex:multidex:2.0.1")
}
// ✅ DİKKAT: Bu satırı KALDIR (çünkü plugin olarak yukarıda ekledik)
// apply plugin: 'com.google.gms.google-services'  // ← Bu satırı silin/yorumlayın