# NeighbourShield Mobile App

NeighbourShield is a community safety and emergency alerting Flutter mobile application built with MVVM architecture. It connects with a Django REST API to handle user authentication, resident profiles, and instant SOS emergency alerts with GPS coordinates.

---

## 🚀 Quick Setup Guide

For detailed step-by-step installation instructions, environment setup, and troubleshooting, read the **[Complete Setup Guide](file:///c:/Users/User/Downloads/Github/NeighbourShield_MobileApp/SETUP_GUIDE.md)**.

### Quick Start in 4 Steps:

1. **Verify your environment:**
   ```bash
   flutter doctor
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure API base URL:**
   Open `lib/app/api_config.dart` and set `baseUrl` for your target device:
   - Android Emulator: `http://10.0.2.2:8000/api`
   - Physical Device / Wi-Fi: `http://<YOUR_PC_LAN_IP>:8000/api`

4. **Launch and run:**
   ```bash
   flutter run
   ```

---

## 🛠️ Tech Stack & Features

- **Flutter & Dart:** Cross-platform mobile development (Android & iOS).
- **MVVM Architecture:** Clean separation of UI, ViewModels, and Data Repositories.
- **Authentication:** Token-based authentication with local session persistence via `shared_preferences`.
- **SOS Emergency Alert:** High-accuracy GPS location retrieval using `geolocator` and real-time backend reporting.
- **Theme & UI:** Custom design theme with responsive layout.

---

## 🧪 Testing & Code Quality

```bash
# Run code analysis
flutter analyze

# Run unit and widget tests
flutter test
```
