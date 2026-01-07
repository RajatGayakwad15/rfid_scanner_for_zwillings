# Build APK - Exact Commands

## Step-by-Step Commands to Build APK

### 1. Open Terminal/Command Prompt
Navigate to your project directory:
```bash
cd D:\13
```

### 2. Clean Previous Builds (Recommended)
```bash
flutter clean
```

### 3. Get Dependencies
```bash
flutter pub get
```

### 4. Build Release APK
```bash
flutter build apk --release --no-tree-shake-icons
```

### 5. Find Your APK
After build completes, your APK will be at:
```
D:\13\build\app\outputs\flutter-apk\app-release.apk
```

---

## Complete Command Sequence (Copy & Paste)

```bash
cd D:\13
flutter clean
flutter pub get
flutter build apk --release --no-tree-shake-icons
```

---

## If You Get Errors

### Error: Flutter not found
**Solution**: Make sure Flutter is in your PATH or use full path:
```bash
C:\flutter_windows_3.38.5-stable\flutter\bin\flutter build apk --release --no-tree-shake-icons
```

### Error: Gradle build failed
**Solution**: Try these commands:
```bash
cd android
gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk --release --no-tree-shake-icons
```

### Error: Dependencies issue
**Solution**:
```bash
flutter pub cache repair
flutter pub get
flutter build apk --release --no-tree-shake-icons
```

---

## Quick Build (If Already Set Up)

If you've already run `flutter pub get` before, you can just run:
```bash
flutter build apk --release --no-tree-shake-icons
```

---

## Verify Build Success

After running the build command, you should see:
```
✓ Built build\app\outputs\flutter-apk\app-release.apk
```

Then your APK is ready at:
```
D:\13\build\app\outputs\flutter-apk\app-release.apk
```

