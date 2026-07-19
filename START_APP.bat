@echo off
title LPU Campus Navigation - Startup
color 0A
echo.
echo  ==========================================
echo   LPU Campus Navigation System - Launcher
echo  ==========================================
echo.

:: -----------------------------------------------
:: STEP 1: Find Java 21 automatically
:: -----------------------------------------------
echo [1/3] Looking for Java 21...

set "JAVA21_HOME="

:: Check common IntelliJ IDEA JBR locations
for /d %%D in ("C:\Program Files\JetBrains\IntelliJ IDEA*") do (
    if exist "%%D\jbr\bin\java.exe" (
        set "JAVA21_HOME=%%D\jbr"
    )
)

:: Check Eclipse Adoptium / Temurin
for /d %%D in ("C:\Program Files\Eclipse Adoptium\jdk-21*") do (
    if exist "%%D\bin\java.exe" set "JAVA21_HOME=%%D"
)

:: Check Oracle JDK 21
for /d %%D in ("C:\Program Files\Java\jdk-21*") do (
    if exist "%%D\bin\java.exe" set "JAVA21_HOME=%%D"
)

:: Check Microsoft OpenJDK 21
for /d %%D in ("C:\Program Files\Microsoft\jdk-21*") do (
    if exist "%%D\bin\java.exe" set "JAVA21_HOME=%%D"
)

:: Check user-local .jdks (IntelliJ auto-downloads here)
for /d %%D in ("%USERPROFILE%\.jdks\*21*") do (
    if exist "%%D\bin\java.exe" set "JAVA21_HOME=%%D"
)

if not defined JAVA21_HOME (
    echo.
    echo  [ERROR] Java 21 not found on this machine!
    echo.
    echo  Please install Java 21 from:
    echo    https://adoptium.net  (Eclipse Temurin - Recommended)
    echo.
    echo  After installing, re-run this script.
    echo.
    pause
    exit /b 1
)

echo  Found Java 21 at: %JAVA21_HOME%
set "JAVA_HOME=%JAVA21_HOME%"
set "PATH=%JAVA21_HOME%\bin;%PATH%"
echo.

:: -----------------------------------------------
:: STEP 2: Check Flutter is installed
:: -----------------------------------------------
echo [2/3] Checking Flutter...
where flutter >nul 2>&1
if errorlevel 1 (
    echo.
    echo  [ERROR] Flutter not found in PATH!
    echo.
    echo  Please install Flutter from: https://flutter.dev/docs/get-started/install
    echo.
    pause
    exit /b 1
)
echo  Flutter found!
echo.

:: -----------------------------------------------
:: STEP 3: Start Backend in a new window
:: -----------------------------------------------
echo [3/3] Starting servers...
start "LPU Backend" cmd /k "set JAVA_HOME=%JAVA21_HOME% && set PATH=%JAVA21_HOME%\bin;%PATH% && cd /d "%~dp0backend" && gradlew.bat bootRun"

echo  Waiting 20 seconds for backend to boot...
timeout /t 20 /nobreak >nul

:: -----------------------------------------------
:: STEP 4: Start Frontend in a new window
:: -----------------------------------------------
start "LPU Frontend" cmd /k "cd /d "%~dp0frontend" && flutter pub get && flutter run -d web-server --web-port 8000"

echo  Waiting 35 seconds for Flutter to compile...
timeout /t 35 /nobreak >nul

:: -----------------------------------------------
:: STEP 5: Open browser
:: -----------------------------------------------
start "" "http://localhost:8000"

echo.
echo  ==========================================
echo   App is running!
echo   Frontend:  http://localhost:8000
echo   Backend:   http://localhost:8080
echo  ==========================================
echo.
echo  Keep the two black server windows OPEN.
echo.
pause
