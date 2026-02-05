# Zwilliglabs for Android 13 (NSAFE Compatible)

A complete Flutter application for Android 13 (API 33) that integrates RFID card scanning with WebView functionality, designed for NSAFE devices.

## Features

- ✅ WebView login page integration
- ✅ NFC/RFID card scanning
- ✅ Card-based authentication API
- ✅ Order list WebView display
- ✅ Android 13 (API 33) compatible
- ✅ NSAFE device compatible
- ✅ Local network HTTP support

## Prerequisites

1. **Flutter SDK** (latest stable version)
   - Download from: https://flutter.dev/docs/get-started/install
   - Verify installation: `flutter doctor`

2. **Android Studio** (recommended)
   - Android SDK 33
   - Android SDK Build-Tools
   - Android SDK Platform-Tools

3. **Physical Device or Emulator**
   - Android 13 (API 33) device
   - NFC-enabled device for RFID testing

## Setup Instructions

### Step 1: Verify Flutter Installation

```bash
flutter doctor
```

Ensure all required components are installed and configured.

### Step 2: Get Dependencies

Navigate to the project root directory and run:

```bash
flutter pub get
```

This will download all required packages specified in `pubspec.yaml`.

### Step 3: Android Configuration

The Android configuration files are already set up:
- `android/app/build.gradle` - App-level Gradle configuration
- `android/build.gradle` - Project-level Gradle configuration
- `android/app/src/main/AndroidManifest.xml` - App manifest with permissions
- `android/app/src/main/res/xml/network_security_config.xml` - Network security config

### Step 4: Update Application ID (Optional)

If you want to change the application ID, edit:
- `android/app/build.gradle` - Change `applicationId` in `defaultConfig`
- `android/app/src/main/AndroidManifest.xml` - Update package references if needed

### Step 5: Run the App

#### For Development/Debug:

```bash
flutter run
```

#### For Release APK (NSAFE Compatible):

```bash
flutter build apk --release --no-tree-shake-icons
```

The APK will be generated at:
`build/app/outputs/flutter-apk/app-release.apk`

### Step 6: Install on Device

1. Transfer the APK to your Android device
2. Enable "Install from Unknown Sources" if needed
3. Install the APK

## Project Structure

```
lib/
 ├── main.dart                    # App entry point
 ├── screens/
 │    ├── login_webview.dart     # Login WebView screen
 │    ├── rfid_scan_screen.dart  # RFID scanning screen
 │    └── home_webview.dart      # Home/Order list WebView screen
 ├── services/
 │    ├── api_service.dart        # API communication service
 │    └── nfc_service.dart       # NFC/RFID service
 └── utils/
      └── constants.dart         # App constants
```

## App Flow

1. **Launch** → Opens WebView with login page (`https://boldrocchi.zwillinglabs.com/login`)
2. **RFID Scan** → Tap the credit card icon in the app bar to scan RFID card
3. **Card Login** → App reads card UID and calls login API (`http://192.168.0.114:3000/api/card/login`)
4. **Home Screen** → On successful login, navigates to order list WebView (`http://192.168.0.114:3000/orderlist`)

## Configuration

### API Endpoints

Edit `lib/utils/constants.dart` to change:
- Login URL
- Card Login API URL
- Order List URL

### Network Security

The app allows cleartext HTTP traffic for local network IPs (192.168.x.x) as configured in `network_security_config.xml`.

## Dependencies

- `webview_flutter: ^4.4.2` - WebView functionality
- `http: ^1.1.0` - HTTP requests
- `nfc_manager: ^3.3.0` - NFC/RFID card reading
- `shared_preferences: ^2.2.2` - Local storage
- `permission_handler: ^11.1.0` - Permission handling

## Android Requirements

- **minSdkVersion**: 23 (Android 6.0)
- **targetSdkVersion**: 33 (Android 13)
- **compileSdkVersion**: 33
- **Kotlin**: 1.9.22

## Permissions

- `INTERNET` - For WebView and API calls
- `NFC` - For RFID card scanning
- `POST_NOTIFICATIONS` - Required for Android 13+

## Troubleshooting

### NFC Not Working
- Ensure NFC is enabled on the device
- Check if the device supports NFC
- Verify NFC permissions in device settings

### WebView Not Loading
- Check internet connection
- Verify URLs are correct in `constants.dart`
- Check network security configuration

### Build Errors
- Run `flutter clean` and `flutter pub get`
- Ensure Android SDK 33 is installed
- Verify Gradle and Kotlin versions

### APK Installation Failed
- Enable "Install from Unknown Sources"
- Check if device meets minimum SDK requirements
- Verify APK signature

## Building for Release

To create a release APK optimized for NSAFE devices:

```bash
flutter clean
flutter pub get
flutter build apk --release --no-tree-shake-icons
```

## Notes

- The app uses foreground NFC dispatch for card scanning
- WebView JavaScript is enabled for full functionality
- Local network HTTP is allowed for development/testing
- The app stores authentication tokens locally using SharedPreferences

## Support

For issues or questions, check:
- Flutter documentation: https://flutter.dev/docs
- Android documentation: https://developer.android.com

---

**Version**: 1.0.0  
**Last Updated**: 2024

# rfid_scanner_for_zwillings
