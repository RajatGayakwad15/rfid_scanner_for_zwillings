# Build Commands for NSAFE Android 13 APK

## Quick Reference

### Development Build
```bash
flutter pub get
flutter run
```

### Release APK Build (NSAFE Compatible)
```bash
flutter clean
flutter pub get
flutter build apk --release --no-tree-shake-icons
```

### APK Location
After building, find your APK at:
```
build/app/outputs/flutter-apk/app-release.apk
```

---

## Detailed Commands

### 1. Initial Setup (First Time Only)
```bash
# Navigate to project directory
cd D:\13

# Get all dependencies
flutter pub get

# Verify Flutter setup
flutter doctor
```

### 2. Development/Debug Build
```bash
# Clean previous builds (optional)
flutter clean

# Get dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# Or specify device
flutter run -d <device-id>
```

### 3. Release APK Build
```bash
# Clean build artifacts
flutter clean

# Get dependencies
flutter pub get

# Build release APK (NSAFE compatible)
flutter build apk --release --no-tree-shake-icons
```

### 4. Split APKs (Optional - for smaller size)
```bash
# Build split APKs
flutter build apk --release --split-per-abi --no-tree-shake-icons
```

This creates separate APKs for:
- `app-armeabi-v7a-release.apk` (32-bit ARM)
- `app-arm64-v8a-release.apk` (64-bit ARM)
- `app-x86_64-release.apk` (x86_64)

### 5. App Bundle (For Play Store)
```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

---

## Useful Commands

### Check Connected Devices
```bash
flutter devices
```

### Check Flutter Version
```bash
flutter --version
```

### Clean Build
```bash
flutter clean
```

### Get Dependencies
```bash
flutter pub get
```

### Analyze Code
```bash
flutter analyze
```

### Run Tests
```bash
flutter test
```

### Check for Updates
```bash
flutter upgrade
```

---

## Troubleshooting Build Issues

### If Build Fails
```bash
# 1. Clean everything
flutter clean

# 2. Get dependencies again
flutter pub get

# 3. Clean Android build
cd android
./gradlew clean
cd ..

# 4. Try building again
flutter build apk --release --no-tree-shake-icons
```

### If Gradle Fails
```bash
cd android
./gradlew clean
./gradlew build
cd ..
```

### If Dependencies Issue
```bash
flutter pub cache repair
flutter pub get
```

---

## Build Flags Explained

- `--release`: Build in release mode (optimized, no debug info)
- `--no-tree-shake-icons`: Keep all app icons (required for NSAFE compatibility)
- `--split-per-abi`: Create separate APKs for each CPU architecture
- `-d <device-id>`: Specify target device

---

## APK Installation

### Via ADB
```bash
flutter install
```

### Manual Installation
1. Transfer APK to device
2. Enable "Install from Unknown Sources"
3. Open APK file
4. Tap "Install"

---

## File Sizes (Approximate)

- **Single APK**: ~25-30 MB
- **Split APK (ARM64)**: ~15-20 MB
- **App Bundle**: ~20-25 MB (Play Store optimizes)

---

## Notes

1. **First Build**: Takes 5-10 minutes (downloads dependencies)
2. **Subsequent Builds**: 1-3 minutes
3. **Release Build**: Always use `--release` flag for production
4. **NSAFE Compatibility**: Use `--no-tree-shake-icons` flag
5. **Testing**: Test on physical device before distribution

---

**Ready to build!** Use the commands above to create your NSAFE-compatible Android 13 APK.

