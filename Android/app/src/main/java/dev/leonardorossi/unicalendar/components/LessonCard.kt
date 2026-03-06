package dev.leonardorossi.unicalendar.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import dev.leonardorossi.unicalendar.fromHex
import dev.leonardorossi.univrcore.Lesson
import dev.vicart.compose.material.symbols.OutlinedRoundedSymbol

@Composable
fun LessonCard(
    lesson: Lesson
) {
    val backgroundColor: Color = if (lesson.annullato) {
        MaterialTheme.colorScheme.background
    } else {
        Color.fromHex(lesson.color) ?: MaterialTheme.colorScheme.background
    }

    Row(
        horizontalArrangement = Arrangement.spacedBy(20.dp),
        modifier = Modifier
            .padding(horizontal = 15.dp)
            .background(
                color = backgroundColor,
                shape = RoundedCornerShape(35.dp)
            )
            .border(
                width = 0.5.dp,
                color = if (lesson.annullato) MaterialTheme.colorScheme.outline else Color.Transparent,
                shape = RoundedCornerShape(35.dp)
            )
            .alpha(if (lesson.annullato) 0.5f else 1f)
            .padding(16.dp)
    ) {
        TimeInfo(lesson)
        LessonInfo(lesson, backgroundColor)
    }
}

@Composable
fun TimeInfo(
    lesson: Lesson
) {
    Column(
        verticalArrangement = Arrangement.spacedBy(5.dp)
    ) {
        Text(
            text = lesson.startTime,
            color = if (lesson.annullato) MaterialTheme.colorScheme.primary else Color.Black,
            fontWeight = FontWeight.Medium,
            style = MaterialTheme.typography.headlineLarge.copy(
                fontFeatureSettings = "tnum"
            )
        )
        if (!lesson.annullato) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(5.dp),
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier
                    .background(
                        color = Color.Black.copy(alpha = 0.1f),
                        shape = RoundedCornerShape(10.dp)
                    )
                    .padding(
                        horizontal = 7.dp,
                        vertical = 3.dp
                    )
            ) {
                OutlinedRoundedSymbol(
                    icon = "schedule",
                    size = MaterialTheme.typography.bodyLarge.fontSize.value.dp
                )
                Text(
                    text = lesson.durationCalculated,
                    style = MaterialTheme.typography.bodyLarge
                )
            }
        }
    }
}

@Composable
fun LessonInfo(
    lesson: Lesson,
    backgroundColor: Color
) {
    Column(
        verticalArrangement = Arrangement.spacedBy(5.dp)
    ) {
        Text(
            text = lesson.cleanName,
            color = if (lesson.annullato) MaterialTheme.colorScheme.primary else Color.Black,
            fontWeight = FontWeight.Medium,
            style = MaterialTheme.typography.bodyLarge,
            textAlign = TextAlign.Start,
            textDecoration = if (lesson.annullato) TextDecoration.LineThrough else TextDecoration.None
        )
        if (!lesson.annullato) {
            Text(
                text = lesson.formattedClassroom,
                color = Color(red = 0.3f, green = 0.3f, blue = 0.3f),
                style = MaterialTheme.typography.bodyMedium,
                textAlign = TextAlign.Start
            )

            if (lesson.tags.isNotEmpty()) {
                TagList(lesson, backgroundColor)
            }
        }
    }
}

@Composable
fun TagList(
    lesson: Lesson,
    backgroundColor: Color
) {
    Column(
        horizontalAlignment = Alignment.Start,
        verticalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        lesson.tags.forEach { tag ->
            Text(
                text = tag,
                color = Color.Black,
                style = MaterialTheme.typography.labelSmall,
                modifier = Modifier
                    .clip(RoundedCornerShape(7.dp))
                    .background(Color.Black.copy(alpha = 0.1f))
                    .background(backgroundColor.copy(alpha = 0.3f))
                    .padding(
                        horizontal = 7.dp,
                        vertical = 3.dp
                    )
            )
        }
    }
}

@Composable
fun BreakCard(
    lesson: Lesson
) {
    Row(
        verticalAlignment = Alignment.Bottom,
        horizontalArrangement = Arrangement.spacedBy(5.dp)
    ) {
        OutlinedRoundedSymbol(
            icon = "local_cafe",
            size = 40.dp,
            tint = Color(red = 0.35f, green = 0.35f, blue = 0.35f)
        )
        Text(
            text = lesson.durationCalculated,
            fontSize = 30.sp,
            fontWeight = FontWeight.Bold,
            fontStyle = FontStyle.Italic,
            color = Color(red = 0.35f, green = 0.35f, blue = 0.35f)
        )
    }
}

@Composable
fun ScheduleRow(
    lesson: Lesson
) {
    when (lesson.category) {
        Lesson.EventCategory.REGULAR -> LessonCard(lesson)
        Lesson.EventCategory.PAUSE -> BreakCard(lesson)
        else -> {}
    }
}

@Preview
@Composable
fun LessonCardPreview() {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(10.dp),
        modifier = Modifier.verticalScroll(rememberScrollState())
    ) {
        listOf(Lesson.sample, Lesson.pausaSample, Lesson.sample).forEach { lesson ->
            ScheduleRow(lesson)
        }
    }
}