# NeighbourShield Mobile App

NeighbourShield is a community safety and emergency alerting Flutter mobile application built with MVVM architecture. It connects with a Django REST API backend to provide resident authentication, instant SOS emergency alerts with GPS coordinates, community safety reporting, emergency broadcast sync/overlays, and volunteer responder workflows.

---

## 📋 Table of Contents

- [Overview & Key Features](#-overview--key-features)
- [Architecture & Tech Stack](#-architecture--tech-stack)
- [Project Directory Structure](#-project-directory-structure)
- [System Requirements & Prerequisites](#-system-requirements--prerequisites)
- [Step-by-Step Setup & Run Guide](#-step-by-step-setup--run-guide)
  - [Step 1: Verify Environment with Flutter Doctor](#step-1-verify-environment-with-flutter-doctor)
  - [Step 2: Enable Windows Developer Mode (Windows Users)](#step-2-enable-windows-developer-mode-windows-users)
  - [Step 3: Accept Android Licenses](#step-3-accept-android-licenses)
  - [Step 4: Install Dependencies](#step-4-install-dependencies)
  - [Step 5: Configure Backend API Endpoint](#step-5-configure-backend-api-endpoint)
  - [Step 6: Launch an Emulator or Connect a Physical Device](#step-6-launch-an-emulator-or-connect-a-physical-device)
  - [Step 7: Run the Application](#step-7-run-the-application)
  - [Step 8: Run Code Quality Checks & Tests](#step-8-run-code-quality-checks--tests)
- [Backend (Django) Integration Setup](#-backend-django-integration-setup)
- [Device Permissions Setup](#-device-permissions-setup)
- [Useful Flutter Commands](#-useful-flutter-commands)
- [Troubleshooting & Common Issues](#-troubleshooting--common-issues)

---

## 🌟 Overview & Key Features

- **Instant SOS Emergency Alerts:** High-accuracy GPS location retrieval using `geolocator` with one-tap emergency trigger sent directly to backend incident services.
- **Emergency Broadcasts & Overlays:** In-app real-time priority alerts and critical full-screen barrier modals for community threats.
- **Community Safety Reports:** Residents can submit, view, filter, and track neighbourhood incidents and safety issues.
- **Community Feed & Discussions:** Interactive social feed with posts, comments, likes, and official advisories.
- **Volunteer Responder Dispatch:** Dedicated workflow allowing certified volunteer responders to view active emergencies and take action.
- **Token-Based Authentication & Session:** Secure token authentication and user role management (`Resident`, `Volunteer`, `Admin`) persisted locally with `shared_preferences`.

---

## 🛠️ Architecture & Tech Stack

- **Framework:** [Flutter](https://flutter.dev/) (Flutter 3.24+, Dart SDK `>=3.5.0 <4.0.0`)
- **Architecture Pattern:** MVVM (Model - View - ViewModel) with native Flutter state management (`ChangeNotifier`, `ListenableBuilder`, `StatefulWidget`)
- **Key Dependencies:**
  - [`http`](https://pub.dev/packages/http) (`^1.2.0`) — REST API communication with Django REST Framework
  - [`shared_preferences`](https://pub.dev/packages/shared_preferences) (`^2.3.0`) — Secure local persistence for auth token and user session
  - [`geolocator`](https://pub.dev/packages/geolocator) (`^14.0.0`) — High-precision GPS coordinates retrieval for emergency alerts
  - [`cupertino_icons`](https://pub.dev/packages/cupertino_icons) (`^1.0.8`) — Modern iconography
- **Backend:** Django REST Framework (DRF) running external API services (Authentication, Incidents, Reports, Posts, Broadcasts)

---

## 📂 Project Directory Structure

The project follows a **feature-first** modular MVVM structure:

```text
lib/
├── app/
│   ├── api_config.dart          # Backend API base URL configuration
│   ├── app.dart                 # MaterialApp shell and root route initialization
│   └── app_theme.dart           # Custom styling, color palette, and component themes
├── core/
│   ├── services/                # App-wide services (EmergencyBroadcastService, LocalBroadcastSyncService)
│   └── session/                 # AppSession singleton and UserRole enum
├── features/
│   ├── auth/                    # Login, registration, token storage, and auth ViewModels
│   │   ├── data/                # Auth API repository & network calls
│   │   ├── models/              # User and AuthToken models
│   │   └── presentation/        # Login and Register UI screens
│   ├── community/               # Community feed, posts, and interactive discussions
│   │   ├── data/                # Community API repository
│   │   ├── models/              # CommunityPost, Comment, and Reaction models
│   │   └── presentation/        # Feed screen, post cards, and comment sheets
│   ├── home/                    # Resident & responder dashboards and SOS button
│   │   └── presentation/        # Home screen and SOS trigger widgets
│   ├── reports/                 # Incident and safety reporting workflow
│   │   ├── data/                # SafetyReportRepository
│   │   ├── models/              # SafetyReport domain models
│   │   └── presentation/        # Community safety reports list & submission forms
│   └── volunteer/               # Volunteer emergency response workflows
│       ├── data/                # Volunteer incidents repository
│       ├── models/              # Incident response models
│       └── presentation/        # Incident response dashboard & action sheets
└── main.dart                    # Application entry point
```

---

## 💻 System Requirements & Prerequisites

Ensure the following tools and SDKs are installed on your workstation before setting up:

### 1. Flutter SDK
- **Required Version:** Flutter 3.24.x or higher (Dart SDK `>=3.5.0 <4.0.0`)
- **Download:** [flutter.dev/docs/get-started/install](https://docs.flutter.dev/get-started/install)
- **Environment Variable:** Ensure Flutter's `bin` directory (e.g. `C:\src\flutter\bin` on Windows or `/usr/local/bin` on Unix) is added to your system `PATH`.

### 2. Git
- **Download:** [git-scm.com](https://git-scm.com/)
- Required by Flutter to download packages, manage dependencies, and version control.

### 3. Java Development Kit (JDK)
- **Recommended Version:** OpenJDK 17 or JDK 21
- Included automatically with Android Studio, or downloadable via [Adoptium Temurin](https://adoptium.net/).

### 4. Android Studio & Android SDK (for Android builds)
- **Download:** [developer.android.com/studio](https://developer.android.com/studio)
- During Android Studio setup, install the following components:
  - **Android SDK** (API 34+ recommended)
  - **Android SDK Platform-Tools**
  - **Android SDK Command-line Tools (`cmdline-tools (latest)`)**
  - **Android Virtual Device (AVD)**

### 5. Code Editor & Extensions
- **Visual Studio Code** with:
  - *Flutter* extension (`Dart-Code.flutter`)
  - *Dart* extension (`Dart-Code.dart-code`)
- **OR Android Studio** with the *Flutter* and *Dart* plugins installed.

---

## 🚀 Step-by-Step Setup & Run Guide

### Step 1: Verify Environment with Flutter Doctor

Open your terminal or PowerShell and run:

```bash
flutter doctor -v
```

Ensure all primary components are satisfied:
- [x] **Flutter:** Channel stable / version healthy.
- [x] **Android toolchain:** Android SDK detected and compatible.
- [x] **Android Studio:** Installed and recognized.
- [x] **Connected device:** At least one target device, emulator, or desktop target available.

---

### Step 2: Enable Windows Developer Mode (Windows Users)

Flutter plugins with native Windows components (e.g., `geolocator_windows`) require symlink support. On Windows, creating symlinks without administrator prompts requires **Developer Mode**:

1. Press `Win + R`, type:
   ```cmd
   start ms-settings:developers
   ```
2. Toggle **Developer Mode** to **ON**.

---

### Step 3: Accept Android Licenses

If `flutter doctor` flags unaccepted Android SDK licenses:

```bash
flutter doctor --android-licenses
```

Press `y` and Enter to accept all required license agreements.

---

### Step 4: Install Dependencies

Navigate into the root directory of this repository and fetch the required Flutter packages:

```bash
flutter pub get
```

Expected output:
```text
Resolving dependencies...
Got dependencies!
```

---

### Step 5: Configure Backend API Endpoint

The mobile app communicates with the **NeighbourShield Django REST API**.

Open `lib/app/api_config.dart` and set `baseUrl` for your target environment:

```dart
class ApiConfig {
  /// Base URL for the NeighbourShield Django REST Framework backend.
  static const String baseUrl = 'http://10.0.2.2:8000/api';
}
```

Use the table below to select the correct URL:

| Target Environment | `ApiConfig.baseUrl` | Details |
|---|---|---|
| **Android Emulator** | `http://10.0.2.2:8000/api` | `10.0.2.2` is the Android emulator's alias to host PC's `127.0.0.1` |
| **Physical Phone (Wi-Fi)** | `http://<YOUR_PC_LAN_IP>:8000/api` | e.g. `http://192.168.1.100:8000/api`. Phone and PC must be on the same Wi-Fi |
| **iOS Simulator** | `http://127.0.0.1:8000/api` | Can access host loopback directly |
| **Windows Desktop / Web** | `http://127.0.0.1:8000/api` | Direct local machine loopback |

> **Find your PC's LAN IP:**
> - **Windows:** Open PowerShell and run `ipconfig`. Look for your Wi-Fi or Ethernet adapter's **IPv4 Address** (e.g., `192.168.x.x`).
> - **macOS / Linux:** Run `ifconfig` or `ip a`.

---

### Step 6: Launch an Emulator or Connect a Physical Device

#### Option A: Using an Android Emulator
1. List available virtual devices:
   ```bash
   flutter emulators
   ```
2. Launch your preferred emulator:
   ```bash
   flutter emulators --launch <EMULATOR_NAME>
   ```
   *(Or launch the device directly from Android Studio's **Device Manager**).*

#### Option B: Using a Physical Android Device
1. On your phone, navigate to **Settings > About Phone** and tap **Build Number** 7 times to enable **Developer Options**.
2. Go to **Settings > Developer Options** and enable **USB Debugging**.
3. Connect your phone to your PC via USB cable and tap **Allow USB Debugging** on the phone screen.

#### Option C: Verify Connected Devices
Verify that Flutter recognizes your device or emulator:

```bash
flutter devices
```

---

### Step 7: Run the Application

Once your target device or emulator is active, launch the app:

```bash
flutter run
```

If multiple devices are connected, target a specific device using `-d`:

```bash
flutter run -d <DEVICE_ID_OR_NAME>
# Example:
flutter run -d android
```

#### Hot Reload & Terminal Controls:
- Press `r` in the terminal to trigger **Hot Reload** (instant state-preserving UI update).
- Press `R` to trigger **Hot Restart** (full app restart).
- Press `q` to detach and exit.

---

### Step 8: Run Code Quality Checks & Tests

Always run code analysis and automated tests before pushing changes:

```bash
# 1. Run static code analysis
flutter analyze

# 2. Run automated unit and widget tests
flutter test
```

Expected output:
```text
No issues found!
All tests passed!
```

---

## 🌐 Backend (Django) Integration Setup

For authentication, reporting, and SOS alerts to function, ensure the backend Django REST API is running and reachable:

1. **Allow Local Network Hosts in Django:**
   In your Django project's `settings.py`, ensure `ALLOWED_HOSTS` permits local traffic:
   ```python
   ALLOWED_HOSTS = ['*']  # For local development
   ```

2. **Start the Django Development Server:**
   Bind Django to `0.0.0.0` so it listens to all network interfaces (required for emulators and physical devices):
   ```bash
   python manage.py runserver 0.0.0.0:8000
   ```

3. **Verify API Endpoints:**
   Ensure the endpoints are accessible via browser or Postman:
   - Auth Login: `http://127.0.0.1:8000/api/auth/login/`
   - Auth Register: `http://127.0.0.1:8000/api/auth/register/`
   - Safety Reports / Incidents: `http://127.0.0.1:8000/api/incidents/`
   - Community Feed: `http://127.0.0.1:8000/api/community/posts/`
   - API Reference & Schemas: Located in [`docs/api/openapi.yaml`](file:///c:/Users/User/Downloads/Github/NeighbourShield_MobileApp/docs/api/openapi.yaml) and [`docs/api/entities.md`](file:///c:/Users/User/Downloads/Github/NeighbourShield_MobileApp/docs/api/entities.md).

---

## 🔒 Device Permissions Setup

The app requires GPS location to transmit accurate coordinates during emergency SOS reports, and network access to interact with the backend API.

### Android (`android/app/src/main/AndroidManifest.xml`)
- `android.permission.ACCESS_FINE_LOCATION` — High-accuracy GPS location
- `android.permission.ACCESS_COARSE_LOCATION` — Network-based location
- `android.permission.INTERNET` — API and network connectivity
- `android:usesCleartextTraffic="true"` — Allows local HTTP traffic during development

### iOS (`ios/Runner/Info.plist`)
- `NSLocationWhenInUseUsageDescription` — Required when accessing GPS coordinates for emergency SOS dispatch
- `NSLocationAlwaysUsageDescription` — Background location updates if responder tracking is enabled

---

## 🧰 Useful Flutter Commands

| Command | Description |
|---|---|
| `flutter doctor -v` | Comprehensive diagnostics of Flutter and SDK toolchains |
| `flutter pub get` | Download and install required dependencies |
| `flutter pub upgrade` | Upgrade packages to highest compatible versions |
| `flutter devices` | List all available physical devices and emulators |
| `flutter emulators` | List configured Android/iOS virtual devices |
| `flutter emulators --launch <name>` | Launch a specific virtual device |
| `flutter run` | Run the application in debug mode |
| `flutter clean` | Clear build cache, temp files, and generated artifacts |
| `flutter analyze` | Run static lint analysis |
| `flutter test` | Execute the unit and widget test suite |
| `flutter build apk` | Build release Android APK (`build/app/outputs/flutter-apk/app-release.apk`) |

---

## ❓ Troubleshooting & Common Issues

### 1. `Building with plugins requires symlink support`
- **Cause:** Windows Developer Mode is disabled.
- **Fix:** Press `Win + R`, run `start ms-settings:developers`, toggle **Developer Mode** to **ON**, and re-run `flutter pub get`.

### 2. `ClientException: Failed to connect to ...` or `SocketException: Connection refused`
- **Cause:** The mobile app cannot reach the Django backend at `ApiConfig.baseUrl`.
- **Fix:**
  - **Android Emulator:** Do **not** use `127.0.0.1` or `localhost`. Set `baseUrl = 'http://10.0.2.2:8000/api'` in `lib/app/api_config.dart`.
  - **Physical Device:** Ensure both PC and phone are on the same Wi-Fi network, set `baseUrl` to your PC's LAN IP (e.g. `http://192.168.1.100:8000/api`), and verify Django was started with `python manage.py runserver 0.0.0.0:8000`.
  - **Firewall:** Verify that Windows Firewall / antivirus allows incoming TCP connections on port 8000.

### 3. `Location permissions are denied` or SOS button fails to retrieve coordinates
- **Cause:** Location services or permissions have not been granted on the device.
- **Fix:**
  - On the device or emulator, open **Settings > Apps > Neighbour Shield > Permissions** and grant **Location (Allow all the time / While using the app)**.
  - In Android Emulator settings, ensure Location/GPS is toggled **ON** and coordinates are configured in Emulator Extended Controls.

### 4. `Some Android licenses not accepted`
- **Cause:** Android SDK licenses must be signed after installation or updates.
- **Fix:** Run:
  ```bash
  flutter doctor --android-licenses
  ```
  Type `y` and press Enter to accept all prompts.

### 5. `Build failed with Gradle exception / Cache corruption`
- **Cause:** Stale Gradle caches or conflicting dependency locks.
- **Fix:**
  ```bash
  flutter clean
  flutter pub get
  flutter run
  ```
