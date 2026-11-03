plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services") apply false
    id("com.google.firebase.crashlytics") apply false
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// A google-services.json a flutterfire configure után kerül a flavor mappájába.
// Amíg nincs meg, a plugin nem fut, és a build nem a régi projekthez kötődik.
val hasGoogleServices = listOf(
    "google-services.json",
    "src/dev/google-services.json",
    "src/prod/google-services.json",
).any { file(it).exists() }

if (hasGoogleServices) {
    apply(plugin = "com.google.gms.google-services")
    apply(plugin = "com.google.firebase.crashlytics")
}

android {
    namespace = "hu.subli.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "hu.subli.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Az üzletbe szánt aláírás az Apple/Google fiók után kerül ide.
            // Addig a helyi release build a debug kulccsal készül.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    flavorDimensions += "env"
    productFlavors {
        create("dev") {
            dimension = "env"
            applicationId = "hu.subli.app.dev"
        }
        create("prod") {
            dimension = "env"
            applicationId = "hu.subli.app"
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
