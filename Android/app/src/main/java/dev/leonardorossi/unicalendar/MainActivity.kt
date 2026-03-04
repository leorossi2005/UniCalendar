package dev.leonardorossi.unicalendar

import android.content.Context
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import dev.leonardorossi.unicalendar.ui.theme.UnivrCalendarTheme
import dev.leonardorossi.univrcore.CacheManager
import dev.leonardorossi.univrcore.CalendarViewModel
import dev.leonardorossi.univrcore.UserSettings

class MainActivity : ComponentActivity() {
    private val cacheManager: CacheManager by lazy {
        CacheManager.getInstance(applicationContext.cacheDir)
    }
    private val viewModel: CalendarViewModel by lazy {
        CalendarViewModel(
            cacheManager = cacheManager
        )
    }

    private val settings by lazy {
        UserSettings.getInstance(applicationContext)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        settings.setSelectedYear("2025")
        settings.setSelectedCourse("1348")
        settings.setSelectedAcademicYear("999|1")
        settings.setMatricola("dispari")

        setContent {
            ProvideUserSettings(context = this) {
                CalendarScreen(
                    viewModel
                )
            }
        }
    }
}

val LocalUserSettings = compositionLocalOf<UserSettings> {
    error("UserSettings non fornito. Avvolgi il contenuto in ProvideUserSettings.")
}

@Composable
fun ProvideUserSettings(
    context: Context,
    content: @Composable () -> Unit
) {
    val userSettings = UserSettings.getInstance(context)

    CompositionLocalProvider(
        LocalUserSettings provides userSettings
    ) {
        content()
    }
}