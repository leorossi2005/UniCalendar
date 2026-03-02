# Dependencies – UnivrCore (Android / Kotlin)

Librerie necessarie da aggiungere al `build.gradle.kts` del modulo `univrcore`.

## Versioni di riferimento (Android 2026)

```kotlin
// build.gradle.kts (module :univrcore)

plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.serialization")
}

android {
    compileSdk = 35
    defaultConfig { minSdk = 26 }   // java.time disponibile nativamente da API 26
}

dependencies {
    // ── Serializzazione JSON ──
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.7.3")

    // ── Coroutines ──
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.9.0")

    // ── Lifecycle ViewModel + coroutine scope ──
    implementation("androidx.lifecycle:lifecycle-viewmodel-ktx:2.8.7")

    // ── Networking (OkHttp) ──
    implementation("com.squareup.okhttp3:okhttp:4.12.0")
    implementation("com.squareup.okhttp3:okhttp-coroutines:5.0.0-alpha.14") // opzionale, per suspend

    // ── DataStore Preferences (per UserSettings) ──
    implementation("androidx.datastore:datastore-preferences:1.1.4")
}
```

## Mapping Swift → Kotlin/Android

| Concetto Swift                | Libreria Android                               |
| ----------------------------- | ---------------------------------------------- |
| `Codable` / `CodingKeys`     | `kotlinx-serialization` (`@Serializable`)      |
| `async throws`               | `suspend fun` + `kotlinx-coroutines`           |
| `@Observable` / `@MainActor` | `ViewModel` + `StateFlow` / `SharedFlow`       |
| `Task { }`                   | `viewModelScope.launch { }`                    |
| `Task.detached`              | `withContext(Dispatchers.IO)`                   |
| `URLSession`                 | `OkHttpClient`                                 |
| `NWPathMonitor`              | `ConnectivityManager.NetworkCallback`           |
| `UserDefaults`               | `DataStore<Preferences>`                        |
| `FileManager` (cache)        | `context.cacheDir` + `java.io.File`            |
| `Date` / `Calendar`          | `java.time.LocalDate` / `DateTimeFormatter`    |
| Swift Regex                  | `kotlin.text.Regex` + `RegexOption`            |
| `Bundle.appVersion`          | `BuildConfig.VERSION_NAME` / `VERSION_CODE`    |
