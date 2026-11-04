# Unio

**Unio** is a modern, native iOS application (SwiftUI + UIKit) designed to simplify university experience for students. It offers a fluid, responsive interface for viewing class schedules, discovering free classrooms in real time, and keeping track of personal commitments.

> 🚀 **Project Status**: v1.0.0 — Production Ready

## ✨ Key Features

### 📅 Smart Schedule & Timetable
*   **Fluid Weekly & Daily View**: Intuitive navigation with fractional scrolling and daily workload indicators.
*   **Apple Calendar Integration**: Export any class directly to Apple Calendar with accurate hours, instructors, and GPS coordinates.
*   **Quick Actions & Previews**: Haptic Touch context menus on lessons and commitments for fast actions.
*   **Smart Caching & Offline Support**: Works seamlessly without an active internet connection thanks to local data persistence.

### 🏫 Real-Time Classroom Availability
*   **Find Free Rooms**: Instantly discover which classrooms are currently unoccupied for studying.
*   **Detailed Room Schedules**: View daily occupancy breakdowns and subsequent events for any classroom.

### 📝 Personal Commitments
*   **Custom Events**: Add personal study sessions, exams, or meetings directly alongside your university timetable.
*   **Rich Metadata**: Attach locations, custom notes, and distinct colors.

### 🔔 Smart Reminders & Notifications
*   **Custom Notification Content Extension**: Expand notifications to see an interactive, rich preview of the upcoming class or commitment.
*   **Configurable Offsets**: Get alerted right on time or minutes before the event starts.

### 🎨 Design & Accessibility
*   **Apple Design**: Modern materials, custom sheets, and light/dark theme support.
*   **iPad Optimized**: SplitView and adaptive layouts designed specifically for larger screens.
*   **Comprehensive Accessibility**: Full VoiceOver integration with natural language labels (`SpeechLanguageLabel`) and Dynamic Type support up to `AX5`.

## 🛠 Requirements
*   **iOS**: 17.0+
*   **Xcode**: 27.0+ (Tested on 27.2)
*   **Language**: Swift 6.4+

## 🚀 Installation & Setup

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/leorossi2005/unio.git
    ```
2.  **Open the project**:
    Double-click on `Unio.xcodeproj`.
3.  **Wait for dependencies**:
  Xcode will resolve internal local packages (`UnioCore`, `CustomSheet`).
4.  **Run**:
    Select your target device or simulator and press `Cmd + R`.

## 🧩 Architecture & Modules

The project is architected cleanly into modular components:

*   **Unio (Main App Target)**:
    *   `App/`: App lifecycle and entry points.
    *   `UI/Views/`: Feature views (Calendar, Availability, Commitments, Settings, WhatsNew).
    *   `UI/Components/`: Reusable SwiftUI design elements.
    *   `UI/Helpers/`: Platform providers (Notifications, Haptics, Device, Network).
*   **NotificationContent (App Extension Target)**:
    *   Dedicated interactive UI for expanded lock-screen notifications.
*   **UnioCore (Local Swift Package)**:
    *   Shared business logic, models, networking (BFF communication), and local storage.

## 📄 License

This project is open source and distributed under the **GNU General Public License v3.0**.
See the [LICENSE](LICENSE) file for more details.