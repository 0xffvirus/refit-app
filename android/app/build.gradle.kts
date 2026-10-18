import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing comes from android/key.properties (gitignored; see
// android/key.properties.example) or REFIT_* environment variables. Release
// builds fail without it rather than silently shipping with the debug key.
// Set REFIT_ALLOW_DEBUG_SIGNING=true to sign a local release build with the
// debug key on purpose (e.g. `flutter run --release`).
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

fun signingValue(key: String, env: String): String? =
    keystoreProperties.getProperty(key)?.takeIf { it.isNotBlank() }
        ?: System.getenv(env)?.takeIf { it.isNotBlank() }

val releaseStoreFile = signingValue("storeFile", "REFIT_KEYSTORE_PATH")
val releaseStorePassword = signingValue("storePassword", "REFIT_KEYSTORE_PASSWORD")
val releaseKeyAlias = signingValue("keyAlias", "REFIT_KEY_ALIAS")
val releaseKeyPassword = signingValue("keyPassword", "REFIT_KEY_PASSWORD")
val hasReleaseSigning = listOf(
    releaseStoreFile, releaseStorePassword, releaseKeyAlias, releaseKeyPassword,
).all { it != null }
val allowDebugSigning = System.getenv("REFIT_ALLOW_DEBUG_SIGNING") == "true"

android {
    namespace = "com.habitgame.habit_game"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Required by flutter_local_notifications for scheduled notifications.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.habitgame.habit_game"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                // Relative paths resolve against the android/ directory.
                storeFile = rootProject.file(releaseStoreFile!!)
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        release {
            signingConfig = when {
                hasReleaseSigning -> signingConfigs.getByName("release")
                allowDebugSigning -> signingConfigs.getByName("debug")
                else -> null
            }
        }
    }
}

gradle.taskGraph.whenReady {
    val buildsRelease = allTasks.any { task ->
        task.project == project &&
            task.name.contains("Release") &&
            listOf("assemble", "bundle", "package").any { task.name.startsWith(it) }
    }
    if (buildsRelease && !hasReleaseSigning && !allowDebugSigning) {
        throw GradleException(
            "Release signing is not configured. Copy android/key.properties.example " +
                "to android/key.properties (or set REFIT_KEYSTORE_PATH, " +
                "REFIT_KEYSTORE_PASSWORD, REFIT_KEY_ALIAS, REFIT_KEY_PASSWORD). " +
                "To sign a local test build with the debug key, set " +
                "REFIT_ALLOW_DEBUG_SIGNING=true.",
        )
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
