package dev.leonardorossi.unicalendar.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.FocusState
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import dev.leonardorossi.univrcore.Corso
import dev.leonardorossi.univrcore.CourseSelectorManager
import dev.vicart.compose.material.symbols.OutlinedRoundedSymbol

@Composable
fun CourseSelector(
    isFocused: Boolean,
    onIsFocusedChange: (Boolean) -> Unit,
    selectedCourse: String,
    onSelectedCourseChange: (String) -> Unit,
    courses: List<Corso>
) {
    var sm by remember { mutableStateOf(CourseSelectorManager()) }
    val focusRequester = remember { FocusRequester() }

    val searchText by sm.searchText.collectAsStateWithLifecycle()

    val isSearching: Boolean = searchText.isNotEmpty() || isFocused

    LaunchedEffect(courses) {
        sm.setCourses(courses)
    }

    LaunchedEffect(isFocused) {
        if (isFocused) {
            focusRequester.requestFocus()
        } else {
            focusRequester.freeFocus()
        }
    }

    Column(
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        Box {
            SearchBar(
                sm = sm,
                searchText = searchText,
                onSearchTextChange = { sm.setSearchText(it) },
                focusRequester = focusRequester,
                onFocusChanged = { focusState ->
                    val new = focusState.isFocused
                    if (new != isFocused) {
                        if (new) {
                            //TODO: Haptics
                        }
                        onIsFocusedChange(new)
                    }
                },
                isFocused = isFocused,
                modifier = Modifier
                    .alpha(if (isSearching || selectedCourse === "0") 1f else 0f)
            )
            if (!isSearching && selectedCourse != "0") {
                Text(
                    text = sm.labelForCourse(selectedCourse),
                    color = MaterialTheme.colorScheme.onSurface,
                    textAlign = TextAlign.Center,
                    modifier = Modifier
                        .fillMaxWidth()
                        .defaultMinSize(minHeight = 50.dp)
                        .background(
                            color = MaterialTheme.colorScheme.surfaceVariant,
                            shape = RoundedCornerShape(25.dp)
                        )
                        .padding(16.dp)
                        .clickable {
                            focusRequester.requestFocus()
                        }
                )
            }
        }
        if (isSearching) {
            SearchResults(sm, selectedCourse, onSelectedCourseChange, focusRequester)
        }
    }
}

@Composable
fun SearchBar(
    sm: CourseSelectorManager,
    searchText: String,
    onSearchTextChange: (String) -> Unit = {},
    focusRequester: FocusRequester,
    onFocusChanged: (FocusState) -> Unit = {},
    isFocused: Boolean,
    modifier: Modifier
) {
    Row(
        horizontalArrangement = Arrangement.spacedBy(16.dp),
        modifier = modifier
            .height(IntrinsicSize.Min)
    ) {
        TextField(
            placeholder = { Text(text = "Cerca un corso", textAlign = TextAlign.Center) },
            value = searchText,
            onValueChange = onSearchTextChange,
            singleLine = true,
            shape = CircleShape,
            keyboardOptions = KeyboardOptions(
                keyboardType = KeyboardType.Ascii,
                autoCorrectEnabled = false,
                imeAction = ImeAction.Done
            ),
            trailingIcon = {
                if (searchText.isNotEmpty()) {
                    IconButton(
                        onClick = {
                            //TODO: Haptics
                            sm.clearSearch()
                            focusRequester.requestFocus()
                        }
                    ) {
                        OutlinedRoundedSymbol(
                            icon = "close",
                            tint = Color.Gray
                        )
                    }
                }
            },
            modifier = Modifier
                .weight(1f)
                .focusRequester(focusRequester)
                .onFocusChanged(onFocusChanged)
        )
        if (isFocused) {
            Box(
                contentAlignment = Alignment.Center, // Centra l'icona perfettamente al centro
                modifier = Modifier
                    .fillMaxHeight()
                    .aspectRatio(1f)
                    .background(
                        color = MaterialTheme.colorScheme.surfaceVariant,
                        shape = CircleShape
                    )
                    .clip(CircleShape)
                    .clickable {
                        //TODO: Haptics
                        sm.clearSearch()
                        focusRequester.freeFocus()
                    }
            ) {
                OutlinedRoundedSymbol(
                    icon = "close",
                    size = MaterialTheme.typography.headlineLarge.fontSize.value.dp
                )
            }
        }
    }
}

@Composable
fun SearchResults(
    sm: CourseSelectorManager,
    selectedCourse: String,
    onSelectedCourseChange: (String) -> Unit,
    focusRequester: FocusRequester
) {
    val filtered = sm.filteredCourses

    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(25.dp))
            .background(MaterialTheme.colorScheme.surfaceVariant)
    ) {
        if (filtered.isEmpty()) {
            Text(
                text = "Nessun corso trovato",
                textAlign = TextAlign.Center,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier
                    .padding(16.dp)
                    .fillMaxWidth()
            )
        } else {
            LazyColumn(
                horizontalAlignment = Alignment.Start,
                verticalArrangement = Arrangement.spacedBy(0.dp),
                modifier = Modifier
                    .heightIn(min = 150.dp, max = 250.dp)
            ) {
                itemsIndexed(filtered) { index, course ->
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(16.dp),
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable {
                                if (course.valore != selectedCourse) {
                                    //TODO: Haptics
                                    onSelectedCourseChange(course.valore)
                                    sm.clearSearch()
                                    focusRequester.freeFocus()
                                }
                            }
                            .padding(16.dp)
                    ) {
                        OutlinedRoundedSymbol(
                            icon = "checkmark",
                            modifier = Modifier
                                .alpha(if (selectedCourse == course.valore) 1f else 0f)
                        )
                        Text(
                            text = course.label,
                            textAlign = TextAlign.Start,
                            modifier = Modifier
                                .weight(1f)
                        )
                    }

                    if (index < filtered.lastIndex) {
                        HorizontalDivider()
                    }
                }
            }
        }
    }
}

@Preview
@Composable
fun CourseSelectorPreview() {
    var isFocused by remember { mutableStateOf(false) }

    CourseSelector(
        isFocused = isFocused,
        onIsFocusedChange = { isFocused = it },
        selectedCourse = "0",
        onSelectedCourseChange = {},
        courses = emptyList(),
    )
}