# UniCalendar

**UniCalendar** is a native iOS application (SwiftUI + UIKit) designed to simplify the lives of University of Verona (UniVR) students. It offers a modern, fluid, and responsive interface for viewing class schedules, helping students organize themselves better and free their minds for studying.

> 🚧 **Project Status**: Active development (v0.9)

## ✨ Key Features

### 📅 Advanced Schedule Management
*   **Fluid Weekly View**: Intuitive navigation between weeks with fractional scrolling support.
*   **Interactive Custom Sheet**: A custom bottom panel (UIKit-based) supporting multiple detents (medium/large) and fluid "liquid glass" transitions.
*   **Complete Lesson Details**: View time, classroom, and approximate location on the integrated map.
*   **Offline Support**: Automatically detects connection status and allows viewing of local cache when offline.

### 🎨 Design & UX
*   **Adaptive Interface**: Optimized for both iPhone and iPad (with SplitView and rotation support).
*   **Polished Animations**: "Snappy" transitions, dynamic glass/blur effects, and custom animations for calendar opening.
*   **Localization**: Fully translated into **Italian** and **English**.
*   **Dark Mode**: Native support for dark theme with automatic color adaptation.

### ⚙️ Technical Aspects
*   **Hybrid Architecture**: Shared multi-platform core (ready for Android) and native Apple UI.
*   **Smart Caching**: Advanced caching system to reduce loading times (from ~500ms to <50ms) and save data.
*   **Resilient Network**: Robust API call management with background refresh.

## 🛠 Requirements
*   **iOS**: 17.0+
*   **Xcode**: 26.0+ (Tested on 26.2)
*   **Language**: Swift 5.9+

## 🚀 Installation

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/leorossi2005/UniCalendar.git
    ```
2.  **Open the project**:
    Double-click on `Univr Calendar.xcodeproj` in the downloaded folder.
3.  **Wait for packages**:
    Let Xcode resolve dependencies via Swift Package Manager.
4.  **Run**:
    Select a simulator (e.g., iPhone 15 Pro) and press `Cmd + R` to start the app.

## 🧩 Project Structure

The project is divided into two main modules to promote portability and order:

*   **Univr App** (Apple-specific code):
    *   `App/`: Base app files.
    *   `UI/Components/`: Independent SwiftUI components.
    *   `UI/Helpers/`: UIKit components assisting SwiftUI.
    *   `UI/UIKit/`: UIKit views and components.
    *   `UI/Views/`: Main SwiftUI views of the app.
*   **Univr Core** (Shared logic):
    *   `ViewModels/`: Computational code for views.
    *   `/`: General package files.

## 📄 License

This project is distributed under the **GNU GPLv3** license.
See the [LICENSE](LICENSE) file for more details.

Free software: you can use it, study it, and modify it, but derivatives must remain open source.
