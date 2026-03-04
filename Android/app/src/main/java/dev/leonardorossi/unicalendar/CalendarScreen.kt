package dev.leonardorossi.unicalendar

import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Build
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.Composable
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import dev.leonardorossi.unicalendar.components.LessonCard
import dev.leonardorossi.univrcore.CacheManager
import dev.leonardorossi.univrcore.CalendarViewModel
import dev.leonardorossi.univrcore.Lesson
import dev.leonardorossi.univrcore.NetworkMonitor
import dev.leonardorossi.univrcore.NetworkStatus
import dev.leonardorossi.univrcore.TempSettingsState
import kotlinx.coroutines.Job
import java.time.LocalDate

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CalendarScreen(
    viewModel: CalendarViewModel
) {
    val safeAreas = WindowInsets.systemBars
    val isDarkTheme = isSystemInDarkTheme()
    val settings = LocalUserSettings.current

    val net = NetworkMonitor.getInstance(LocalContext.current)
    var tempSettings by remember { mutableStateOf(TempSettingsState()) }
    var selectedLesson by remember {  mutableStateOf<Lesson?>(null) }
    var selectedWeek by remember { mutableStateOf(LocalDate.now()) }
    var selection by remember { mutableStateOf<String?>("") }

    var firstLoading by remember { mutableStateOf(true) }
    val coroutineScope = rememberCoroutineScope()
    var scrollUpdateJob by remember { mutableStateOf<Job?>(null) }

    //var selectedDetent: CustomSheetDetent = .small
    //var openSettings: Bool = false
    //var openCalendar: Bool = false
    //var oldOpenCalendar: Bool = false

    //var sheetShape = UnevenRoundedRectangle()
    //var sheetShapeRadii: SheetCornerRadii = .init(tl: 0, tr: 0, bl: 0, br: 0)

    Box(Modifier.fillMaxSize()) {
        Scaffold(
            topBar = {
                TopAppBar(
                    title = {
                        Row(
                            Modifier.padding(end = 16.dp)
                        ) {
                            Column() {
                                Text(
                                    text = "Martedì",
                                    fontWeight = FontWeight.Bold,
                                    style = MaterialTheme.typography.bodyLarge
                                )
                                Text(
                                    text = "3 Marzo",
                                    style = MaterialTheme.typography.bodyMedium
                                )
                            }
                            Spacer(Modifier.weight(1f))
                            IconButton(
                                onClick = {}
                            ) {
                                Icon(
                                    imageVector = Icons.Default.Settings,
                                    contentDescription = null
                                )
                            }
                        }
                    }
                )
            }
        ) { innerPadding ->
            MainScrollView (
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding),
                viewModel = viewModel,
                net = net,
                firstLoading = firstLoading
            )
        }

        Box(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .fillMaxWidth()
        ) {
            // CustomSheet
        }
    }
}

@Composable
fun MainScrollView(
    modifier: Modifier = Modifier,
    viewModel: CalendarViewModel,
    net: NetworkMonitor,
    firstLoading: Boolean
) {
    val days by viewModel.days.collectAsStateWithLifecycle()
    val status by net.status.collectAsStateWithLifecycle()
    val loading by viewModel.loading.collectAsStateWithLifecycle()

    Row (
        modifier = modifier
            .fillMaxSize()
            .horizontalScroll(rememberScrollState())
    ) {
        when {
            status != NetworkStatus.CONNECTED && days.isEmpty() -> {
                // Offline
            }

            !loading || !firstLoading -> {
                Box (
                    Modifier
                        .fillMaxSize()
                        .align(Alignment.CenterVertically)
                ) {
                    CircularProgressIndicator()
                }
                // Loading Placeholder
            }

            else -> {
                LoadedContent(
                    viewModel = viewModel,
                    //selectedLesson = TODO(),
                    //onSelectedLessonChange = TODO(),
                    //openCalendar = TODO(),
                    //onOpenCalendarChange = TODO(),
                    //firstLoading = TODO(),
                    //onFirstLoadingChange = TODO(),
                    //changeOpenCalendar = TODO(),
                    modifier = Modifier.fillMaxSize()
                )
            }
        }
    }
}

@Composable
fun LoadedContent(
    viewModel: CalendarViewModel,
    //selectedLesson: Lesson?,
    //onSelectedLessonChange: (Lesson?) -> Unit,
    //openCalendar: Boolean,
    //onOpenCalendarChange: (Boolean) -> Unit,
    //selectedDetent: CustomSheetDetent,
    //onSelectedDetentChange: (CustomSheetDetent) -> Unit,
    //firstLoading: Boolean,
    //onFirstLoadingChange: (Boolean) -> Unit,
    //changeOpenCalendar: (Boolean) -> Unit,
    modifier: Modifier = Modifier
) {
    val noLessonsFound by viewModel.noLessonsFound.collectAsStateWithLifecycle()
    val days by viewModel.days.collectAsStateWithLifecycle()
    val daysString by viewModel.daysString.collectAsStateWithLifecycle()

    Row(
        modifier = modifier
            .fillMaxSize()
    ) {
        if (!noLessonsFound) {
            LessonCard(
                lesson = Lesson.sample
            )
            days.forEachIndexed { index, lessonsForDay ->
                if (lessonsForDay.isNotEmpty()) {
                    Box (
                        modifier = Modifier
                            .fillMaxHeight()
                            .weight(1f)
                    ) {
                        CalendarViewDayCompose(
                            filteredLessons = lessonsForDay,
                            //selectedLesson = selectedLesson,
                            //onSelectedLessonChange = onSelectedLessonChange,
                            //openCalendar = openCalendar,
                            //onOpenCalendarChange = onOpenCalendarChange,
                            //selectedDetent = selectedDetent,
                            //onSelectedDetentChange = onSelectedDetentChange,
                            //firstLoading = firstLoading,
                            //onFirstLoadingChange = onFirstLoadingChange,
                            //changeOpenCalendar = changeOpenCalendar,
                            //dayId = daysString.getOrNull(index)
                        )
                    }
                } else {
                    Box(
                        modifier = Modifier
                            .fillMaxHeight()
                            .weight(1f),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = "Oggi non hai lezioni!",
                            style = MaterialTheme.typography.titleMedium
                        )
                    }
                }
            }
        } else {
            Box(
                modifier = Modifier
                    .fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "Nessuna lezione trovata per questo corso",
                    style = MaterialTheme.typography.titleMedium
                )
            }
        }
    }
}

@Composable
fun CalendarViewDayCompose(
    modifier: Modifier = Modifier,
    filteredLessons: List<Lesson>,
    //selectedLesson: Lesson?,
    //onSelectedLessonChange: (Lesson?) -> Unit,
    //openCalendar: Boolean,
    //onOpenCalendarChange: (Boolean) -> Unit,
    //selectedDetent: CustomSheetDetent,
    //onSelectedDetentChange: (CustomSheetDetent) -> Unit,
    //firstLoading: Boolean,
    //onFirstLoadingChange: (Boolean) -> Unit,
    //changeOpenCalendar: (Boolean) -> Unit,
    //dayId: String? = null
) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
    ) {
        filteredLessons.forEach { lesson ->
            if (lesson.tipo != "pause" && lesson.tipo != "chiusura_type") {
                LessonCard(
                    lesson = Lesson.sample
                )
                //LessonCardCompose(
                //    lesson = lesson,
                //    onClick = {
                //        // equivalente di onTapGesture { ... }
                //        onSelectedLessonChange(lesson)
                //        onSelectedDetentChange(CustomSheetDetent.Large)
                //    }
                //)
            } else {
                Row(
                    verticalAlignment = Alignment.Bottom,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.Build, // cupDynamic in SF Symbols
                        contentDescription = null,
                        modifier = Modifier.size(40.dp)
                    )
                    Text(
                        text = lesson.durationCalculated,
                        style = MaterialTheme.typography.headlineSmall,
                        fontStyle = FontStyle.Italic,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
        }
    }
}

@Preview
@Composable
fun CalendarScreenPreview() {
    CalendarScreen(CalendarViewModel(cacheManager = CacheManager.getInstance(LocalContext.current.applicationContext.cacheDir)))
}

//@Composable
//fun CalendarScreen(
//    viewModel: CalendarViewModel,
//    settings: UserSettings
//) {
//    val days by viewModel.days.collectAsStateWithLifecycle()
//    val daysString by viewModel.daysString.collectAsStateWithLifecycle()
//    val loading by viewModel.loading.collectAsStateWithLifecycle()
//    val error by viewModel.errorMessage.collectAsStateWithLifecycle()
//    val noLessons by viewModel.noLessonsFound.collectAsStateWithLifecycle()
//
//    val  aa = settings.selectedCourse.collectAsStateWithLifecycle()
//    // Per ora: appena entri, se non hai lezioni, chiediamo al VM di usare
//    // gli stessi parametri che usi su iOS li aggiungeremo dopo.
//    LaunchedEffect(Unit) {
//        if (settings.selectedCourse.value == "0") return@LaunchedEffect
//
//        viewModel.loadNetworkFromCache()
//        viewModel.loadFromCache(
//            selYear = settings.selectedYear.value,
//            matricola = settings.matricola.value
//        )
//        viewModel.loadLessons(
//            corso = settings.selectedCourse.value,
//            anno = settings.selectedAcademicYear.value,
//            selYear = settings.selectedYear.value,
//            matricola = settings.matricola.value,
//            updating = false
//        )
//    }
//
//    Box(
//        modifier = Modifier
//            .fillMaxSize()
//            .padding(bottom = 16.dp),
//        contentAlignment = Alignment.Center
//    ) {
//        when {
//            loading -> {
//                CircularProgressIndicator()
//            }
//            error != null -> {
//                Text(
//                    text = error ?: "Errore sconosciuto",
//                    style = MaterialTheme.typography.bodyLarge
//                )
//            }
//            noLessons -> {
//                Text(
//                    text = "Nessuna lezione trovata",
//                    style = MaterialTheme.typography.titleMedium
//                )
//            }
//            days.isEmpty() -> {
//                Text(
//                    text = "Seleziona un corso e scarica le lezioni",
//                    style = MaterialTheme.typography.titleMedium
//                )
//            }
//            else -> {
//                CalendarPager(
//                    days = days,
//                    dayLabels = daysString
//                )
//            }
//        }
//    }
//}
//
//@Composable
//private fun CalendarPager(
//    days: List<List<Lesson>>,
//    dayLabels: List<String>
//) {
//    val pagerState = rememberPagerState(
//        initialPage = 0,
//        pageCount = { days.size }
//    )
//
//    HorizontalPager(
//        state = pagerState,
//        modifier = Modifier.fillMaxSize()
//    ) { page ->
//        val label = dayLabels.getOrNull(page) ?: "---"
//        val lessonsInDay = days[page]
//
//        Column(
//            modifier = Modifier
//                .fillMaxSize()
//                .padding(horizontal = 16.dp, vertical = 8.dp)
//        ) {
//            Text(
//                text = label,
//                style = MaterialTheme.typography.titleLarge
//            )
//            Spacer(Modifier.height(8.dp))
//
//            if (lessonsInDay.isEmpty()) {
//                Text(
//                    text = "Oggi non hai lezioni",
//                    style = MaterialTheme.typography.bodyMedium
//                )
//            } else {
//                LazyColumn(
//                    modifier = Modifier.fillMaxSize(),
//                    verticalArrangement = Arrangement.spacedBy(8.dp)
//                ) {
//                    items(lessonsInDay) { lesson ->
//                        LessonRow(lesson = lesson)
//                    }
//                }
//            }
//        }
//    }
//}
//
//@Composable
//private fun LessonRow(lesson: Lesson) {
//    Column(
//        modifier = Modifier
//            .fillMaxWidth()
//            .padding(12.dp)
//    ) {
//        Text(
//            text = lesson.nomeInsegnamento,
//            style = MaterialTheme.typography.titleMedium
//        )
//        Text(
//            text = lesson.orario,
//            style = MaterialTheme.typography.bodyMedium
//        )
//        if (lesson.aula.isNotBlank()) {
//            Text(
//                text = lesson.formattedClassroom,
//                style = MaterialTheme.typography.bodySmall,
//                color = MaterialTheme.colorScheme.secondary
//            )
//        }
//    }
//}
