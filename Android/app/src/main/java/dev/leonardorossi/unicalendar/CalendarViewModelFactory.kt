package dev.leonardorossi.unicalendar

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import dev.leonardorossi.univrcore.CacheManager
import dev.leonardorossi.univrcore.CalendarViewModel
import java.io.File

class CalendarViewModelFactory: ViewModelProvider.Factory  {
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        if (modelClass.isAssignableFrom(CalendarViewModel::class.java)) {
            @Suppress("UNCHECKED_CAST")
            return CalendarViewModel(
                cacheManager = CacheManager.getInstance(File(""))
            ) as T
        }
        throw IllegalArgumentException("Unknown ViewModel class")
    }
}