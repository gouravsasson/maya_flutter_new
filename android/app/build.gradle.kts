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
    namespace = "com.ravan.maya"
    compileSdk = 36    
    ndkVersion = "29.0.13846066"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
isCoreLibraryDesugaringEnabled = true 
   }
    dependencies {
        implementation("androidx.core:core:1.13.1") 
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.ravan.maya"
        minSdk = flutter.minSdkVersion
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


dependencies {
  // Import the Firebase BoM
  implementation(platform("com.google.firebase:firebase-bom:34.3.0"))


  // TODO: Add the dependencies for Firebase products you want to use
  // When using the BoM, don't specify versions in Firebase dependencies
  implementation("com.google.firebase:firebase-analytics")


  // Add the dependencies for any other desired Firebase products
  // https://firebase.google.com/docs/android/setup#available-libraries
}
