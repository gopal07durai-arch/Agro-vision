# AgroVision AI — Flutter Android App

Smart Crop Disease Detection Platform — Mobile App

---

## Quick Start (Step-by-Step)

### Step 1 — Install Flutter SDK

Flutter is NOT currently installed. Follow these steps:

1. Go to: https://docs.flutter.dev/get-started/install/windows/mobile
2. Download the Flutter SDK ZIP for Windows
3. Extract to: `C:\flutter`
4. Add to your System PATH: `C:\flutter\bin`
5. Open a **new** PowerShell terminal and run:
   ```
   flutter doctor
   ```

### Step 2 — Install Android Studio

1. Download Android Studio: https://developer.android.com/studio
2. Install with default settings (includes Android SDK)
3. Run: `flutter doctor --android-licenses` to accept licenses

### Step 3 — Add Flutter to PATH (IMPORTANT)

If you're getting "flutter not recognized":
- Windows: Go to **System Properties → Environment Variables → Path → New** → Add `C:\flutter\bin`
- Then open a **new** terminal (restart the terminal)
- Verify: `flutter --version`

### Step 4 — Navigate to the Flutter app folder

```powershell
cd "c:\Users\gopal\OneDrive\Desktop\trail 2\agrovision_app"
```

### Step 5 — Run the setup script

```powershell
.\flutter_setup.ps1
```

This will:
- Verify Flutter installation
- Run `flutter pub get` to install packages
- Check your `.env` configuration
- List connected devices
- Optionally build the APK

---

## Configuration

### API URL (CRITICAL for real device)

Edit `agrovision_app/.env`:

```env
# For Android Emulator:
API_BASE_URL=http://10.0.2.2:8000

# For Real Android Phone (same WiFi as your PC):
API_BASE_URL=http://192.168.x.x:8000
```

To find your PC's local IP:
```powershell
ipconfig | Select-String "IPv4"
```

### Backend (must be running)

The Flutter app connects to the **existing FastAPI backend**. Start it before testing:

```powershell
cd "c:\Users\gopal\OneDrive\Desktop\trail 2\backend"
python main.py
```

---

## Running the App

```powershell
cd "c:\Users\gopal\OneDrive\Desktop\trail 2\agrovision_app"

# List devices
flutter devices

# Run on connected device
flutter run

# Build APK
flutter build apk --debug

# Install on device
flutter install
```

---

## Project Structure

```
agrovision_app/
├── .env                          # API URL + Supabase keys
├── pubspec.yaml                  # Dependencies
├── flutter_setup.ps1             # Setup script
│
├── lib/
│   ├── main.dart                 # Entry point
│   ├── app.dart                  # MaterialApp with theme
│   │
│   ├── core/
│   │   ├── theme/app_theme.dart  # Material 3 emerald theme
│   │   ├── constants/app_config.dart # API URLs, thresholds
│   │   ├── providers/app_provider.dart # Dark mode, language, session
│   │   └── l10n/app_localizations.dart # 5-language strings
│   │
│   ├── models/
│   │   ├── prediction_result.dart # Maps FastAPI JSON response
│   │   ├── api_error.dart         # Typed error handling
│   │   └── history_entry.dart     # Supabase history rows
│   │
│   ├── services/
│   │   ├── api_service.dart       # FastAPI /api/v1/predict calls
│   │   ├── supabase_service.dart  # History + ratings
│   │   ├── image_service.dart     # Camera + gallery + compression
│   │   └── detection_service.dart # Full detection pipeline
│   │
│   ├── screens/
│   │   ├── splash/splash_screen.dart    # Animated launch screen
│   │   ├── home/home_screen.dart        # Hero + navigation
│   │   ├── scan/scan_screen.dart        # Camera + gallery + analyze
│   │   ├── result/result_screen.dart    # Results + fertilizer
│   │   ├── history/history_screen.dart  # Scan history
│   │   ├── about/about_screen.dart      # App info
│   │   └── settings/settings_screen.dart # Language + dark mode
│   │
│   └── widgets/
│       ├── confidence_gauge.dart   # Animated circular gauge
│       ├── floating_leaf.dart      # Background leaf animation
│       └── star_rating.dart        # Star feedback widget
│
└── android/
    └── app/src/main/
        └── AndroidManifest.xml     # Permissions: camera, internet, storage
```

---

## Features

| Feature | Status |
|---|---|
| Splash screen with animation | ✅ |
| Home screen with floating leaves | ✅ |
| Camera capture | ✅ |
| Gallery upload | ✅ |
| Image compression | ✅ |
| FastAPI backend integration | ✅ |
| Real AI crop detection (no hardcoded values) | ✅ |
| Disease detection from image | ✅ |
| Confidence gauges (animated) | ✅ |
| Fertilizer recommendations | ✅ |
| Error screens (notLeaf, lowQuality, etc.) | ✅ |
| Supabase history save/load | ✅ |
| Star rating | ✅ |
| 5-language localization (EN/TA/HI/TE/ML) | ✅ |
| Dark/light mode | ✅ |
| Offline detection | ✅ (connectivity_plus) |
| Bottom navigation | ✅ |

---

## Security

- ✅ Supabase **anon key** only — safe for client apps
- ✅ API keys loaded from `.env` file (not hardcoded)
- ✅ `.env` should be in `.gitignore`
- ✅ No service-role key exposed

---

## Troubleshooting

| Problem | Solution |
|---|---|
| `flutter` not found | Add `C:\flutter\bin` to System PATH, restart terminal |
| `flutter pub get` fails | Check internet connection and pubspec.yaml |
| API connection fails | Check `API_BASE_URL` in `.env` and start backend |
| Camera not opening | Grant camera permission in Android Settings |
| "10.0.2.2 not working" on real device | Use your PC's LAN IP instead |
| Build fails | Run `flutter doctor` and fix all issues shown |
