# Complete Setup Instructions

## Quick Start Guide

Follow these steps to set up and build the Zwillinglabs  for Android 13.

---

## Step 1: Prerequisites Check

### 1.1 Install Flutter
1. Download Flutter SDK from: https://flutter.dev/docs/get-started/install
2. Extract to a location (e.g., `C:\flutter` or `D:\flutter`)
3. Add Flutter to your PATH environment variable

### 1.2 Verify Installation
Open terminal/command prompt and run:
```bash
flutter doctor
```

Install any missing components (Android SDK, Android Studio, etc.)

### 1.3 Install Android Studio
1. Download from: https://developer.android.com/studio
2. Install Android SDK 33 (API 33)
3. Install Android SDK Build-Tools
4. Install Android SDK Platform-Tools

---

## Step 2: Project Setup

### 2.1 Navigate to Project Directory
```bash
cd D:\13
```

### 2.2 Get Flutter Dependencies
```bash
flutter pub get
```

This will download all packages listed in `pubspec.yaml`:
- webview_flutter
- http
- nfc_manager
- shared_preferences
- permission_handler

### 2.3 Verify Project Structure
Ensure you have:
```
lib/
 ├── main.dart
 ├── screens/
 │    ├── login_webview.dart
 │    ├── rfid_scan_screen.dart
 │    └── home_webview.dart
 ├── services/
 │    ├── api_service.dart
 │    └── nfc_service.dart
 └── utils/
      └── constants.dart
```

---

## Step 3: Android Configuration Verification

### 3.1 Check Android Files
Verify these files exist:
- `android/app/build.gradle` ✓
- `android/build.gradle` ✓
- `android/app/src/main/AndroidManifest.xml` ✓
- `android/app/src/main/res/xml/network_security_config.xml` ✓
- `android/app/src/main/kotlin/com/example/rfid_webview_app/MainActivity.kt` ✓

### 3.2 Verify Gradle Configuration
- **minSdkVersion**: 23
- **targetSdkVersion**: 33
- **compileSdkVersion**: 33
- **Kotlin version**: 1.9.22

---

## Step 4: Connect Device or Emulator

### 4.1 Physical Device
1. Enable Developer Options on your Android device
2. Enable USB Debugging
3. Connect via USB
4. Verify connection:
   ```bash
   flutter devices
   ```

### 4.2 Emulator (Alternative)
1. Open Android Studio
2. Create an Android 13 (API 33) emulator
3. Start the emulator
4. Verify connection:
   ```bash
   flutter devices
   ```

---

## Step 5: Run the App

### 5.1 Development/Debug Mode
```bash
flutter run
```

This will:
- Build the app in debug mode
- Install on connected device/emulator
- Launch the app
- Enable hot reload

### 5.2 Check for Errors
If you encounter errors:
1. Run `flutter clean`
2. Run `flutter pub get`
3. Try `flutter run` again

---

## Step 6: Build Release APK (NSAFE Compatible)

### 6.1 Clean Build
```bash
flutter clean
```

### 6.2 Get Dependencies
```bash
flutter pub get
```

### 6.3 Build Release APK
```bash
flutter build apk --release --no-tree-shake-icons
```

### 6.4 Locate APK
The APK will be at:
```
build/app/outputs/flutter-apk/app-release.apk
```

---

## Step 7: Install on NSAFE Device

### 7.1 Transfer APK
1. Copy `app-release.apk` to your Android device
2. Use USB, email, or cloud storage

### 7.2 Enable Unknown Sources
1. Go to Settings → Security
2. Enable "Install from Unknown Sources" or "Install Unknown Apps"
3. Select the app/file manager you'll use to install

### 7.3 Install APK
1. Open the APK file on your device
2. Tap "Install"
3. Wait for installation to complete
4. Tap "Open" or launch from app drawer

---

## Step 8: Test the App

### 8.1 Test WebView Login
1. Launch the app
2. Verify login page loads: `https://boldrocchi.zwillinglabs.com/login`
3. Check if page is interactive

### 8.2 Test RFID Scanning
1. Tap the credit card icon in the app bar
2. Ensure NFC is enabled on device
3. Tap an RFID card to the device
4. Verify card UID is read
5. Check API call to: `http://192.168.0.114:3000/api/card/login`

### 8.3 Test Home Screen
1. After successful RFID login
2. Verify order list loads: `http://192.168.0.114:3000/orderlist`
3. Check WebView functionality

---

## Troubleshooting

### Issue: Flutter not found
**Solution**: Add Flutter to PATH or use full path to `flutter` command

### Issue: Gradle build failed
**Solution**: 
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### Issue: NFC not working
**Solution**:
- Check NFC is enabled in device settings
- Verify device supports NFC
- Check NFC permissions in app settings

### Issue: WebView not loading
**Solution**:
- Check internet connection
- Verify URLs in `lib/utils/constants.dart`
- Check network security config allows HTTP for local IPs

### Issue: APK installation failed
**Solution**:
- Enable "Install from Unknown Sources"
- Check device meets minSdkVersion 23
- Verify APK is not corrupted

### Issue: API call fails
**Solution**:
- Verify device and server are on same network
- Check server is running at `192.168.0.114:3000`
- Verify network security config allows HTTP

---

## Build Commands Summary

### Development
```bash
flutter pub get
flutter run
```

### Release Build
```bash
flutter clean
flutter pub get
flutter build apk --release --no-tree-shake-icons
```

### Check Devices
```bash
flutter devices
```

### Clean Build
```bash
flutter clean
```

---

## Configuration Files

### Change API URLs
Edit: `lib/utils/constants.dart`

### Change App Name
Edit: `android/app/src/main/AndroidManifest.xml` → `android:label`

### Change Package Name
Edit: `android/app/build.gradle` → `applicationId`

---

## Additional Notes

1. **First Build**: May take 5-10 minutes (downloads dependencies)
2. **Subsequent Builds**: Usually 1-3 minutes
3. **APK Size**: Approximately 20-30 MB
4. **NFC Testing**: Requires physical NFC-enabled device
5. **Network**: Ensure device and server are on same local network

---

## Support

For issues:
1. Check Flutter documentation: https://flutter.dev/docs
2. Check Android documentation: https://developer.android.com
3. Review error messages in terminal
4. Check device logs: `flutter logs`

---

**Ready to build!** Follow the steps above to create your NSAFE-compatible Android 13 app.

