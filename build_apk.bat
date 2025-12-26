@echo off
echo ===========================================
echo   SCADA Mobile App - Build Helper
echo ===========================================
echo.
echo Setting JAVA_HOME to JDK 17...
set JAVA_HOME=C:\Program Files\Java\jdk-17
set PATH=%JAVA_HOME%\bin;%PATH%

echo.
echo Verifying Java Version...
java -version

echo.
echo Cleaning previous builds...
call flutter clean

echo.
echo Building Release APK...
echo This may take a few minutes. Please wait.
call flutter build apk --release

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ===========================================
    echo   BUILD SUCCESSFUL!
    echo ===========================================
    echo APK Location: build\app\outputs\flutter-apk\app-release.apk
    explorer build\app\outputs\flutter-apk
) else (
    echo.
    echo ===========================================
    echo   BUILD FAILED
    echo ===========================================
    echo Please check if JDK 17 is installed at: C:\Program Files\Java\jdk-17
)

pause
