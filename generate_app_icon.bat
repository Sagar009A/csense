@echo off
REM Generate Android + iOS app icons from assets/logo.png
REM Run this from project root. Then rebuild the app.
echo Generating app icon from assets/logo.png...
call flutter pub get
call dart run flutter_launcher_icons
echo Done. Rebuild the app (flutter run or build) to see the new icon.
pause
