@echo off
REM Get SHA-1 and SHA-256 for RELEASE keystore (Firebase / Google Play / API)
REM Run this from android folder. Uses key.properties for path and alias.

setlocal
cd /d "%~dp0"

REM Use Java from Android Studio JBR if JAVA_HOME not set
if not defined JAVA_HOME (
  if exist "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" (
    set "KEYTOOL=C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe"
  ) else if exist "%LOCALAPPDATA%\Android\Sdk\jre\bin\keytool.exe" (
    set "KEYTOOL=%LOCALAPPDATA%\Android\Sdk\jre\bin\keytool.exe"
  ) else (
    set "KEYTOOL=keytool"
  )
) else (
  set "KEYTOOL=%JAVA_HOME%\bin\keytool.exe"
)

echo.
echo === Release keystore SHA-1 and SHA-256 ===
echo.

if not exist "key.properties" (
  echo key.properties not found. Create it from key.properties.example
  echo Then run: keytool -list -v -keystore YOUR_KEYSTORE_PATH -alias YOUR_ALIAS
  echo You will be prompted for store password and key password.
  pause
  exit /b 1
)

REM Read key.properties (storeFile is relative to android/)
for /f "usebackq tokens=1,2 delims==" %%a in ("key.properties") do (
  if "%%a"=="storeFile" set "STORE_FILE=%%b"
  if "%%a"=="keyAlias" set "KEY_ALIAS=%%b"
)
set "STORE_FILE=%STORE_FILE: =%"
set "KEY_ALIAS=%KEY_ALIAS: =%"

if "%STORE_FILE%"=="" set "STORE_FILE=upload-keystore.jks"
if "%KEY_ALIAS%"=="" set "KEY_ALIAS=upload"

REM Resolve path: if storeFile has ../ then from project root
if "%STORE_FILE:~0,3%"=="../" (
  set "KEYSTORE_PATH=%~dp0..\%STORE_FILE:~3%"
) else (
  set "KEYSTORE_PATH=%~dp0%STORE_FILE%"
)

if not exist "%KEYSTORE_PATH%" (
  echo Keystore not found: %KEYSTORE_PATH%
  echo Edit key.properties: storeFile=your-keystore.jks
  pause
  exit /b 1
)

echo Keystore: %KEYSTORE_PATH%
echo Alias: %KEY_ALIAS%
echo.
echo Enter keystore password when prompted.
echo.

"%KEYTOOL%" -list -v -keystore "%KEYSTORE_PATH%" -alias "%KEY_ALIAS%"

echo.
echo Copy the SHA1 and SHA256 lines above for Firebase / Google Sign-In / Play Console.
pause
