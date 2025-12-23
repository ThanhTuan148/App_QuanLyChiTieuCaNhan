plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.quanlychitieu"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.example.quanlychitieu"
        minSdk = 28
        targetSdk = 36

        versionCode = flutter.versionCode
        versionName = flutter.versionName

        multiDexEnabled = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "21"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.multidex:multidex:2.0.1")
}


//android {
//    namespace = "com.example.quanlychitieu"
//
//    compileSdk = 36
//    ndkVersion = "27.0.12077973"
//
//    compileOptions {
//        sourceCompatibility = JavaVersion.VERSION_21
//        targetCompatibility = JavaVersion.VERSION_21
//        isCoreLibraryDesugaringEnabled = true
//    }
//
//    kotlin {
//        compilerOptions {
//            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_21)
//        }
//    }
//
//    defaultConfig {
//        applicationId = "com.example.quanlychitieu"
//        minSdk = 28
//        targetSdk = 36
//
//        versionCode = flutter.versionCode
//        versionName = flutter.versionName
//
//        multiDexEnabled = true
//    }
//
//    buildTypes {
//        release {
//            signingConfig = signingConfigs.getByName("debug")
//            isMinifyEnabled = false
//            isShrinkResources = false
//        }
//    }
//}
