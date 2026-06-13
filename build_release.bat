@echo off
REM Build Surya Connect APK and Windows release
REM Requires Flutter SDK in PATH (see SETUP.md)

cd /d "%~dp0"

where flutter >nul 2>&1
if errorlevel 1 (
  echo Flutter not found. Install from https://docs.flutter.dev/get-started/install/windows
  echo Then update android\local.properties with your flutter.sdk path.
  exit /b 1
)

echo Installing dependencies...
call flutter pub get
if errorlevel 1 exit /b 1

echo Generating launcher icons...
call dart run flutter_launcher_icons
if errorlevel 1 exit /b 1

echo Building Android APK...
call flutter build apk --release
if errorlevel 1 exit /b 1

echo Building Windows release...
call flutter config --enable-windows-desktop
call flutter build windows --release
if errorlevel 1 exit /b 1

echo.
echo Build complete!
echo APK: build\app\outputs\flutter-apk\app-release.apk
echo Windows: build\windows\x64\runner\Release\
pause
