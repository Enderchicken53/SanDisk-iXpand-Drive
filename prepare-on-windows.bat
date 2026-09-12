@echo off
setlocal
echo This script prepares a SanDisk iXpand Drive source checkout for the macOS build.
echo.
where git >nul 2>nul
if errorlevel 1 (
  echo Git is not installed or not on PATH.
  exit /b 1
)
if not exist SanDisk-iXpand-Drive (
  git clone https://github.com/SanDisk-Open-Source/SanDisk-iXpand-Drive.git SanDisk-iXpand-Drive
)
copy /Y experimental-build.sh SanDisk-iXpand-Drive\experimental-build.sh
echo.
echo Prepared: SanDisk-iXpand-Drive
echo The actual compile step must run on macOS/Xcode.
