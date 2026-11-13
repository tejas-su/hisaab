import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing (docs/RELEASE.md). Only the maintainer has android/key.properties and the
// keystore beside it in android/, both git-ignored. Everyone else builds every variant,
// release and bundle included, with the debug keys: no setup needed to contribute.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) load(FileInputStream(keystorePropertiesFile))
}
val hasReleaseKey = keystorePropertiesFile.exists()

// why: a warning, not a failure, so contributors are never blocked. A debug-signed bundle can't
// reach users anyway, because Play rejects it.
if (!hasReleaseKey && gradle.startParameter.taskNames.any { it.contains("Release", ignoreCase = true) }) {
    logger.warn("hisaab: no android/key.properties, so this release build is signed with the debug key. Fine for local testing; not uploadable to Play (docs/RELEASE.md).")
}

android {
    namespace = "com.widgetsandco.hisaab"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // flutter_local_notifications needs the newer Java time APIs on older Android (D126).
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Permanent once published to Play: never change it.
        applicationId = "com.widgetsandco.hisaab"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                // Relative to android/, beside key.properties; an absolute path also works.
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // The upload key when key.properties exists; otherwise debug keys, so
            // `flutter run --release` still works on a machine without the key.
            signingConfig = signingConfigs.getByName(if (hasReleaseKey) "release" else "debug")
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // The widget's midnight job, beside the inexact alarm (widget spec §15 #3).
    implementation("androidx.work:work-runtime-ktx:2.10.1")
    // SnapshotReader's JVM tests; org.json stands in for Android's own, which unit tests stub out.
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.json:json:20240303")
}
