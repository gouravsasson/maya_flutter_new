plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.ravan.Maya"
    compileSdk = 36    
    ndkVersion = "29.0.13846066"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.ravan.Maya"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
    create("customDebug") {
        keyAlias = "tushar"
        keyPassword = "tushar"
        storeFile = file("upload-keystore.jks")
        storePassword = "tushar"
    }
}

    buildTypes {
    release {
        signingConfig = signingConfigs.getByName("customDebug")
    }
    debug {
        signingConfig = signingConfigs.getByName("customDebug")
    }
}
}

flutter {
    source = "../.."
}
