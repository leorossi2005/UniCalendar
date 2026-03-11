//
//  Onboarding.kt
//  Univr Calendar
//
//  Translated from Onboarding.swift
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

package dev.leonardorossi.unicalendar.views

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.systemBars
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import dev.leonardorossi.unicalendar.LocalUserSettings
import dev.leonardorossi.unicalendar.R
import dev.leonardorossi.unicalendar.components.CourseSelector
import dev.leonardorossi.univrcore.NetworkMonitor
import dev.leonardorossi.univrcore.NetworkStatus
import dev.leonardorossi.univrcore.UniversityDataManager
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

@Composable
fun Onboarding(
    net: NetworkMonitor,
    viewModel: UniversityDataManager
) {
    val settings = LocalUserSettings.current
    val coroutineScope = rememberCoroutineScope()

    val pagerState = rememberPagerState(pageCount = { 5 })
    var nextIndexLoading by remember { mutableIntStateOf(-1) }
    var errorText by remember { mutableStateOf("nope") }
    var searchTextFieldFocus by remember { mutableStateOf(false) }

    // Collect settings
    val selectedYear by settings.selectedYear.collectAsStateWithLifecycle()
    val selectedCourse by settings.selectedCourse.collectAsStateWithLifecycle()
    val selectedAcademicYear by settings.selectedAcademicYear.collectAsStateWithLifecycle()
    val foundMatricola by settings.foundMatricola.collectAsStateWithLifecycle()
    val matricola by settings.matricola.collectAsStateWithLifecycle()
    val networkStatus by net.status.collectAsStateWithLifecycle()

    // Collect viewModel state
    val years by viewModel.years.collectAsStateWithLifecycle()
    val courses by viewModel.courses.collectAsStateWithLifecycle()
    val academicYears by viewModel.academicYears.collectAsStateWithLifecycle()

    fun handlePageTransition(targetIndex: Int, operation: suspend () -> Unit) {
        nextIndexLoading = targetIndex
        coroutineScope.launch {
            try {
                operation()
                pagerState.animateScrollToPage(
                    page = targetIndex,
                    animationSpec = spring(
                        dampingRatio = 1f,
                        stiffness = 250f
                    )
                )
            } catch (_: Exception) {
                val msg = viewModel.errorMessage.value
                if (msg != null) errorText = msg
                nextIndexLoading = pagerState.currentPage
            }
        }
    }

    fun completeOnboarding() {
        settings.setOnboardingCompleted(true)
    }

    LaunchedEffect(Unit) {
        viewModel.loadFromCache()
    }

    Box(modifier = Modifier.fillMaxSize()) {
        HorizontalPager(
            state = pagerState,
            userScrollEnabled = false,
            modifier = Modifier.fillMaxSize()
        ) { page ->
            when (page) {
                // MARK: - Page 0: Benvenuto
                0 -> OnboardingPage(
                    title = "Benvenuto!",
                    subtitle = "Non capisci mai che lezioni hai? Non hai voglia di aprire il sito ogni volta o usare app obsolete? Ora puoi fare tutto qui!",
                    errorMessage = errorText,
                    onErrorDismiss = { errorText = "nope" },
                    isTopContent = true,
                    content = {
                        Image(
                            painter = painterResource(R.drawable.internalicon),
                            contentDescription = null,
                            modifier = Modifier
                                .size(100.dp)
                                .clip(RoundedCornerShape(22.dp))
                        )
                    },
                    buttonTitle = "Continua",
                    isLoading = nextIndexLoading > 0,
                    isButtonDisabled = networkStatus != NetworkStatus.CONNECTED,
                    buttonAction = {
                        handlePageTransition(1) {
                            viewModel.loadYears()
                        }
                    }
                )

                // MARK: - Page 1: Scegli un anno
                1 -> OnboardingPage(
                    title = "Scegli un anno",
                    subtitle = "Seleziona un anno precedente per vedere l'archivio, sennò procedi pure con l'ultimo ;)",
                    errorMessage = errorText,
                    onErrorDismiss = { errorText = "nope" },
                    isTopContent = false,
                    content = {
                        SingleChoiceSegmentedButtonRow(
                            modifier = Modifier.padding(16.dp)
                        ) {
                            years.forEachIndexed { index, year ->
                                SegmentedButton(
                                    selected = selectedYear == year.valore,
                                    onClick = { settings.setSelectedYear(year.valore) },
                                    shape = SegmentedButtonDefaults.itemShape(index, years.size)
                                ) {
                                    Text(year.label)
                                }
                            }
                        }
                    },
                    buttonTitle = "Continua",
                    isLoading = nextIndexLoading > 1,
                    isButtonDisabled = networkStatus != NetworkStatus.CONNECTED,
                    buttonAction = {
                        viewModel.clearCourses()
                        settings.setSelectedCourse("0")

                        handlePageTransition(2) {
                            viewModel.loadCourses(selectedYear)
                        }
                    }
                )

                // MARK: - Page 2: Scegli un corso
                2 -> {
                    val yearLabel = years.firstOrNull { it.valore == selectedYear }?.label ?: ""

                    OnboardingPage(
                        title = "Bene! Ora scegli un corso",
                        subtitle = "Sono mostrati i corsi per l'anno $yearLabel",
                        errorMessage = errorText,
                        onErrorDismiss = { errorText = "nope" },
                        isTopContent = false,
                        content = {
                            CourseSelector(
                                isFocused = searchTextFieldFocus,
                                onIsFocusedChange = { searchTextFieldFocus = it },
                                selectedCourse = selectedCourse,
                                onSelectedCourseChange = { settings.setSelectedCourse(it) },
                                courses = courses
                            )
                        },
                        buttonTitle = "Continua",
                        isLoading = nextIndexLoading > 2,
                        isButtonDisabled = selectedCourse == "0",
                        buttonAction = {
                            searchTextFieldFocus = false

                            viewModel.clearAcademicYears()
                            settings.setFoundMatricola(false)

                            handlePageTransition(3) {
                                viewModel.updateAcademicYears(selectedCourse, selectedYear)

                                val firstYear = viewModel.academicYears.value.firstOrNull()
                                if (firstYear != null) {
                                    settings.setSelectedAcademicYear(firstYear.valore)
                                    settings.setFoundMatricola(
                                        viewModel.checkForMatricola(firstYear.valore)
                                    )
                                }
                            }
                        }
                    )
                }

                // MARK: - Page 3: Che anno frequenti?
                3 -> OnboardingPage(
                    title = "Che anno frequenti?",
                    subtitle = "Se vedi solo un anno allora lascia così, non puoi sbagliare!",
                    errorMessage = errorText,
                    onErrorDismiss = { errorText = "nope" },
                    isTopContent = false,
                    content = {
                        SingleChoiceSegmentedButtonRow(
                            modifier = Modifier.padding(16.dp)
                        ) {
                            academicYears.forEachIndexed { index, year ->
                                SegmentedButton(
                                    selected = selectedAcademicYear == year.valore,
                                    onClick = {
                                        settings.setSelectedAcademicYear(year.valore)
                                        settings.setFoundMatricola(
                                            viewModel.checkForMatricola(year.valore)
                                        )
                                    },
                                    shape = SegmentedButtonDefaults.itemShape(index, academicYears.size),
                                    enabled = courses.isNotEmpty()
                                ) {
                                    Text(year.label)
                                }
                            }
                        }
                    },
                    buttonTitle = if (foundMatricola) "Continua" else "Comincia!",
                    isLoading = nextIndexLoading > 3,
                    isButtonDisabled = false,
                    buttonAction = {
                        if (foundMatricola) {
                            handlePageTransition(4) {}
                        } else {
                            completeOnboarding()
                        }
                    }
                )

                // MARK: - Page 4: Matricola pari/dispari
                4 -> OnboardingPage(
                    title = "Sei matricola pari o dispari?",
                    subtitle = "O il tuo amico, ovvio",
                    errorMessage = errorText,
                    onErrorDismiss = { errorText = "nope" },
                    isTopContent = false,
                    content = {
                        val options = listOf("pari" to "Pari", "dispari" to "Dispari")

                        SingleChoiceSegmentedButtonRow(
                            modifier = Modifier.padding(16.dp)
                        ) {
                            options.forEachIndexed { index, (value, label) ->
                                SegmentedButton(
                                    selected = matricola == value,
                                    onClick = { settings.setMatricola(value) },
                                    shape = SegmentedButtonDefaults.itemShape(index, options.size)
                                ) {
                                    Text(label)
                                }
                            }
                        }
                    },
                    buttonTitle = "Comincia!",
                    isLoading = false,
                    isButtonDisabled = false,
                    buttonAction = {
                        completeOnboarding()
                    }
                )
            }
        }

        // MARK: - Offline Banner
        OfflineBanner(
            isOffline = networkStatus != NetworkStatus.CONNECTED,
            modifier = Modifier.align(Alignment.TopCenter)
        )
    }
}

// MARK: - OnboardingPage

@Composable
private fun OnboardingPage(
    title: String,
    subtitle: String,
    errorMessage: String,
    onErrorDismiss: () -> Unit,
    isTopContent: Boolean,
    content: @Composable () -> Unit,
    buttonTitle: String,
    isLoading: Boolean,
    isButtonDisabled: Boolean,
    buttonAction: () -> Unit
) {
    LaunchedEffect(errorMessage) {
        if (errorMessage != "nope") {
            delay(3000)
            onErrorDismiss()
        }
    }

    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier
            .fillMaxSize()
            .imePadding()
            .padding(horizontal = 24.dp)
    ) {
        Spacer(modifier = Modifier.weight(1f))

        if (isTopContent) {
            content()
        }

        Text(
            text = title,
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.Center
        )

        Text(
            text = subtitle,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center,
            modifier = Modifier
                .padding(horizontal = 16.dp)
                .padding(bottom = 16.dp)
        )

        if (!isTopContent) {
            content()
        }

        Spacer(modifier = Modifier.weight(1f))

        // Error text
        Text(
            text = if (errorMessage != "nope") errorMessage else "",
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.error,
            textAlign = TextAlign.Center
        )

        OnboardingButton(
            title = buttonTitle,
            isLoading = isLoading,
            isDisabled = isButtonDisabled,
            action = buttonAction
        )
    }
}

// MARK: - OnboardingButton

@Composable
private fun OnboardingButton(
    title: String,
    isLoading: Boolean,
    isDisabled: Boolean,
    action: () -> Unit
) {
    Button(
        onClick = {
            // TODO: Haptics
            action()
        },
        enabled = !isDisabled && !isLoading,
        modifier = Modifier
            .fillMaxWidth()
            .windowInsetsPadding(WindowInsets.systemBars)
    ) {
        if (isLoading) {
            RotatingSemicircleLoader()
        } else {
            Text(
                text = title,
                fontWeight = FontWeight.SemiBold
            )
        }
    }
}

// MARK: - RotatingSemicircleLoader

@Composable
private fun RotatingSemicircleLoader() {
    val infiniteTransition = rememberInfiniteTransition(label = "loader")
    val rotation by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = 360f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 1000, easing = LinearEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "rotation"
    )

    val color = MaterialTheme.colorScheme.onPrimary

    androidx.compose.foundation.Canvas(
        modifier = Modifier
            .size(20.dp)
            .rotate(rotation)
    ) {
        drawArc(
            color = color,
            startAngle = 0f,
            sweepAngle = 216f, // 0.6 * 360
            useCenter = false,
            style = Stroke(width = 4.dp.toPx(), cap = StrokeCap.Round)
        )
    }
}

// MARK: - OfflineBanner

@Composable
private fun OfflineBanner(
    isOffline: Boolean,
    modifier: Modifier = Modifier
) {
    val isDark = isSystemInDarkTheme()
    val backgroundColor = if (isDark) Color(0xFFCCAA00) else Color.Yellow
    val borderColor = if (isDark) Color(0xFFB39500) else Color(0xFFCCAA00)

    AnimatedVisibility(
        visible = isOffline,
        enter = slideInVertically(animationSpec = spring()) { -it } + scaleIn(animationSpec = spring()),
        exit = slideOutVertically(animationSpec = spring()) { -it } + scaleOut(animationSpec = spring()),
        modifier = modifier.padding(top = 48.dp)
    ) {
        Text(
            text = "Al momento sei offline.",
            color = Color.Black,
            modifier = Modifier
                .clip(RoundedCornerShape(25.dp))
                .background(backgroundColor)
                .border(2.dp, borderColor, RoundedCornerShape(25.dp))
                .padding(horizontal = 24.dp, vertical = 12.dp)
        )
    }
}