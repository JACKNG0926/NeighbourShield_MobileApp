# NeighbourShield Mobile App — Complete Setup & Run Guide

A step-by-step setup and installation guide to initialize, configure, and run the **NeighbourShield** Flutter mobile application on Android emulators, physical devices, iOS, and desktop.

---

## Table of Contents
1. [Tech Stack & Architecture](#tech-stack--architecture)
2. [What to Install (Prerequisites)](#what-to-install-prerequisites)
3. [Step-by-Step Initialization & Setup](#step-by-step-initialization--setup)
   - [Step 1: Verify Prerequisites with Flutter Doctor](#step-1-verify-prerequisites-with-flutter-doctor)
   - [Step 2: Enable Windows Developer Mode (Windows Users)](#step-2-enable-windows-developer-mode-windows-users)
   - [Step 3: Accept Android Licenses](#step-3-accept-android-licenses)
   - [Step 4: Install Dependencies](#step-4-install-dependencies)
   - [Step 5: Configure Backend API Endpoint](#step-5-configure-backend-api-endpoint)
   - [Step 6: Launch an Emulator or Connect a Device](#step-6-launch-an-emulator-or-connect-a-device)
   - [Step 7: Run the Application](#step-7-run-the-application)
   - [Step 8: Run Verification & Tests](#step-8-run-verification--tests)
4. [Backend (Django) Integration Setup](#backend-django-integration-setup)
5. [Device Permissions Setup](#device-permissions-setup)
6. [Useful Flutter Commands](#useful-flutter-commands)
7. [Troubleshooting & Common Issues](#troubleshooting--common-issues)

---

## Tech Stack & Architecture

- **Framework:** [Flutter](https://flutter.dev/) (Dart SDK `^3.5.0` / Dart `3.9.x+`)
- **Architecture Pattern:** MVVM (Model - View - ViewModel)
- **Key Dependencies:**
  - `http` — REST API communication with the Django backend
  - `shared_preferences` — Secure local storage for auth tokens and user session
  - `geolocator` — GPS coordinates retrieval for the SOS emergency trigger
  - `cupertino_icons` — Modern iOS/Material icon sets
- **Backend:** Django REST Framework (DRF) running API services (Authentication & Incident Reporting)

---

## What to Install (Prerequisites)

Ensure the following tools and SDKs are installed on your workstation:

### 1. Flutter SDK
- **Required Version:** Flutter 3.35.x or higher (Dart 3.5.0+)
- **Download:** [flutter.dev/docs/get-started/install](https://docs.flutter.dev/get-started/install)
- **Environment Variable:** Ensure Flutter's `bin` directory (e.g. `C:\src\flutter\bin`) is added to your system `PATH`.

### 2. Git
- **Download:** [git-scm.com](https://git-scm.com/)
- Required by Flutter to fetch dependencies and manage packages.

### 3. Java Development Kit (JDK)
- **Recommended Version:** OpenJDK 17 or JDK 21
- Usually bundled automatically with Android Studio, or downloadable via [Adoptium Temurin](https://adoptium.net/).

### 4. Android Studio & Android SDK
- **Download:** [developer.android.com/studio](https://developer.android.com/studio)
- During installation, select:
  - **Android SDK**
  - **Android SDK Platform-Tools**
  - **Android SDK Command-line Tools (`cmdline-tools (latest)`)**
  - **Android Virtual Device (AVD)**

### 5. Code Editor & Extensions
- **VS Code** with:
  - *Flutter* extension (`Dart-Code.flutter`)
  - *Dart* extension (`Dart-Code.dart-code`)
- **OR Android Studio** with the *Flutter* and *Dart* plugins installed.

---

## Step-by-Step Initialization & Setup

### Step 1: Verify Prerequisites with Flutter Doctor

Open PowerShell or your terminal and run:

```bash
flutter doctor -v
```

Ensure that:
- [x] **Flutter** is installed and reported healthy.
- [x] **Android toolchain** can locate your Android SDK.
- [x] **Android Studio** is recognized.

---

### Step 2: Enable Windows Developer Mode (Windows Users)

Flutter uses symlinks for native platform plugins (such as `geolocator_windows`). On Windows, creating symlinks without administrator prompts requires **Developer Mode** enabled:

1. Press `Win + R`, type:
   ```cmd
   start ms-settings:developers
   ```
2. Toggle **Developer Mode** to **ON**.

---

### Step 3: Accept Android Licenses

If `flutter doctor` displays an exclamation mark next to Android licenses:

```bash
flutter doctor --android-licenses
```

Press `y` and Enter to accept each license agreement until completed.

---

### Step 4: Install Dependencies

Navigate into the root of this project and fetch all required packages:

```bash
cd c:\Users\User\Downloads\Github\NeighbourShield_MobileApp
flutter pub get
```

Expected output:
```text
Resolving dependencies...
Got dependencies!
```

---

### Step 5: Configure Backend API Endpoint

The mobile app connects to the **NeighbourShield Django REST API**. 

Open `lib/app/api_config.dart`:

```dart
class ApiConfig {
  // Update this to match your environment:
  static const String baseUrl = 'http://10.0.2.2:8000/api';
}
```

Choose the appropriate URL for your setup:

| Environment | Base URL | Note |
|---|---|---|
| **Android Emulator** | `http://10.0.2.2:8000/api` | `10.0.2.2` routes directly to your host PC's `localhost` |
| **Physical Phone (Wi-Fi)** | `http://<YOUR_PC_LAN_IP>:8000/api` | Example: `http://192.168.1.15:8000/api` (both PC and phone must be on the same Wi-Fi) |
| **iOS Simulator** | `http://127.0.0.1:8000/api` | Can access host loopback directly |
| **Windows Desktop App** | `http://127.0.0.1:8000/api` | Direct local connection |

> **Find your PC's LAN IP:**
> - Windows: Open PowerShell and run `ipconfig`. Look for IPv4 Address (e.g. `192.168.0.x`).
> - macOS/Linux: Run `ifconfig` or `ip a`.

---

### Step 6: Launch an Emulator or Connect a Device

#### Option A: Using an Android Emulator
1. List available emulators:
   ```bash
   flutter emulators
   ```
2. Launch your emulator (e.g. `Medium_Phone`):
   ```bash
   flutter emulators --launch Medium_Phone
   ```
   *(Or launch the device from Android Studio's **Device Manager**).*

#### Option B: Using a Physical Android Device
1. On your phone, go to **Settings > About Phone** and tap **Build Number** 7 times to enable **Developer Options**.
2. Go to **Settings > Developer Options** and enable **USB Debugging**.
3. Plug your phone into your PC via USB and allow USB debugging when prompted.

#### Option C: Check Connected Devices
Verify that Flutter recognizes your device or emulator:

```bash
flutter devices
```

---

### Step 7: Run the Application

Once your target device or emulator is active, start the app:

```bash
flutter run
```

If multiple devices are connected, specify the target with `-d`:

```bash
flutter run -d Medium_Phone
# or
flutter run -d android
```

#### Hot Reload & Controls:
- Press `r` in the terminal to **Hot Reload** (instant code changes).
- Press `R` in the terminal to **Hot Restart** (restart state and UI).
- Press `q` to detach and stop the application.

---

### Step 8: Run Verification & Tests

To ensure the project has no static analysis or testing regressions:

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

## Backend (Django) Integration Setup

For login, registration, and emergency SOS alerts to work, the backend must be running and accessible over your local network:

1. In your Django backend directory, ensure `ALLOWED_HOSTS` in `settings.py` includes your IP or wildcard:
   ```python
   ALLOWED_HOSTS = ['*']  # For local development
   ```
2. Start the Django development server binding to `0.0.0.0`:
   ```bash
   python manage.py runserver 0.0.0.0:8000
   ```
3. Test endpoints from a browser or Postman:
   - `http://127.0.0.1:8000/api/auth/login/`
   - `http://127.0.0.1:8000/api/auth/register/`
   - `http://127.0.0.1:8000/api/incidents/`

---

## Device Permissions Setup

The app uses GPS coordinates to trigger SOS alerts and network access to talk to the backend. These permissions are configured in the codebase:

### Android (`android/app/src/main/AndroidManifest.xml`)
- `android.permission.ACCESS_FINE_LOCATION`
- `android.permission.ACCESS_COARSE_LOCATION`
- `android.permission.INTERNET`
- `android:usesCleartextTraffic="true"` (allows non-HTTPS HTTP traffic for local network testing)

### iOS (`ios/Runner/Info.plist`)
- `NSLocationWhenInUseUsageDescription`: Needed when requesting GPS for SOS report.
- `NSLocationAlwaysUsageDescription`: Background location support if needed.

---

## Useful Flutter Commands

| Command | Description |
|---|---|
| `flutter doctor -v` | Detailed diagnostics of your environment |
| `flutter pub get` | Download and install packages |
| `flutter pub upgrade` | Upgrade packages to latest compatible versions |
| `flutter devices` | List active connected devices |
| `flutter emulators` | List available virtual devices |
| `flutter clean` | Clear build caches and temp artifacts |
| `flutter analyze` | Lint and validate code quality |
| `flutter test` | Run test suite |
| `flutter build apk` | Build release Android APK (`build/app/outputs/flutter-apk/app-release.apk`) |

---

## Troubleshooting & Common Issues

### 1. `Building with plugins requires symlink support`
- **Cause:** Windows Developer Mode is disabled.
- **Fix:** Run `start ms-settings:developers` in PowerShell and toggle **Developer Mode** to **ON**. Then rerun `flutter pub get`.

### 2. `ClientException: Failed to connect to / SocketException: OS Error: Connection refused`
- **Cause:** The mobile app cannot reach the Django backend at `baseUrl`.
- **Fix:**
  - If using **Android Emulator**, ensure `ApiConfig.baseUrl` in `lib/app/api_config.dart` uses `http://10.0.2.2:8000/api` (not `127.0.0.1` or `localhost`).
  - If using a **Physical Phone**, ensure `baseUrl` uses your PC's Wi-Fi IP (e.g. `http://192.168.0.x:8000/api`) and Django is running with `python manage.py runserver 0.0.0.0:8000`.
  - Check Windows Firewall: allow incoming connections on port 8000.

### 3. `Location permissions are denied` or SOS button fails
- **Cause:** GPS was not allowed on the device.
- **Fix:** In the Android Emulator or physical phone, open **Settings > Apps > Neighbour Shield > Permissions** and grant **Location** permission. Also verify device Location/GPS is toggled ON.

### 4. `Some Android licenses not accepted`
- **Fix:** Run:
  ```bash
  flutter doctor --android-licenses
  ```
  Type `y` to accept all prompts.

### 5. `Build failed with Gradle exception / Cache issues`
- **Fix:**
  ```bash
  flutter clean
  flutter pub get
  flutter run
  ```
