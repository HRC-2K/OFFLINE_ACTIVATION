@echo off
setlocal enabledelayedexpansion

:: ==============================================================================
:: 1. ENFORCE ADMINISTRATOR PRIVILEGES
:: ==============================================================================
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting Administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: Set download folder on Desktop
set "TargetFolder=%userprofile%\Desktop\App_Installers"
if not exist "%TargetFolder%" mkdir "%TargetFolder%"

:MENU
cls
echo ==============================================================================
echo             FULLY SILENT SMART UPGRADE / INSTALLATION MENU
echo ==============================================================================
echo  [1] UltraViewer 6.6
echo  [2] Cloudflare 1.1.1.1 WARP
echo  [3] Firewall App Blocker (Extracts Only)
echo  [4] Steam Launcher
echo  [5] Ubisoft Connect Launcher
echo  [6] Epic Games Launcher
echo  [7] Rockstar Games Launcher 
echo  [8] EA Desktop App 
echo  [9] TcNo Account Switcher
echo  [A] Upgrade / Install ALL Apps
echo  [X] Exit
echo ==============================================================================
echo  Files will be saved to: %TargetFolder%
echo ==============================================================================
echo.

set /p choice="Enter numbers separated by spaces (e.g., 1 4 6): "

if /i "%choice%"=="X" exit /b
if /i "%choice%"=="A" set choice=1 2 3 4 5 6 7 8 9

echo.
echo Starting automated smart upgrade process...
echo ==============================================================================

:: Loop through choices
for %%i in (%choice%) do (
    if "%%i"=="1" call :ProcessApp "https://www.ultraviewer.net/en/UltraViewer_setup_6.6_en.exe" "UltraViewer_setup_6.6_en.exe" "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART" "UltraViewer.exe"
    if "%%i"=="2" call :ProcessApp "https://1111-releases.cloudflareclient.com/win/latest" "Cloudflare_1.1.1.1_Setup.exe" "/quiet /norestart" "CloudflareWARP.exe"
    if "%%i"=="3" call :ProcessApp "https://www.sordum.org/files/downloads.php?firewall-app-blocker" "FirewallAppBlocker.zip" "ZIP" "Fab.exe"
    if "%%i"=="4" call :ProcessApp "https://cdn.akamai.steamstatic.com/client/installer/SteamSetup.exe" "SteamSetup.exe" "/S" "steam.exe"
    if "%%i"=="5" call :ProcessApp "https://ubi.li/4vxt9" "UbisoftConnectInstaller.exe" "/S" "upc.exe"
    if "%%i"=="6" call :ProcessApp "https://launcher-public-service-prod06.ol.epicgames.com/launcher/api/installer/download/EpicGamesLauncherInstaller.exe" "EpicGamesLauncherInstaller.exe" "/qn /norestart" "EpicGamesLauncher.exe"
    if "%%i"=="7" call :ProcessApp "https://gamedownloads.rockstargames.com/public/installer/Rockstar-Games-Launcher.exe" "Rockstar-Games-Launcher.exe" "/S /v/qn" "Launcher.exe"
    if "%%i"=="8" call :ProcessApp "https://origin-a.akamaihd.net/EA-Desktop-Client-Download/installer-releases/EAappInstaller.exe" "EAappInstaller.exe" "/q" "EADesktop.exe"
    if "%%i"=="9" call :ProcessApp "https://github.com/TCNOco/TcNo-Acc-Switcher/releases/download/2025-11-20_03/TcNo.Account.Switcher.-.Installer_2025-11-20_03.exe" "TcNo.Account.Switcher.exe" "/S" "TcNo Account Switcher.exe"
)

echo ==============================================================================
echo All selected upgrades/installations completed!
echo.
pause
goto MENU

:: Core processing function (Kill Process -> Download -> Silent Upgrade)
:ProcessApp
set "URL=%~1"
set "FileName=%~2"
set "InstallArgs=%~3"
set "ProcessName=%~4"
set "FilePath=%TargetFolder%\%FileName%"

echo.
echo [PROCESSING]: %FileName%
echo [SOURCE]: %URL%
echo ------------------------------------------------------------------------------

:: 1. SMART PROCESS KILLER
:: Tries to gently close or force close the app if running to prevent file locks
tasklist /FI "IMAGENAME eq %ProcessName%" 2>NUL | find /I /N "%ProcessName%">NUL
if %errorlevel% equ 0 (
    echo [INFO]: %ProcessName% is currently running. Terminating to allow upgrade...
    taskkill /f /im "%ProcessName%" >nul 2>&1
    timeout /t 2 >nul
)

:: 2. DOWNLOAD
curl -L -# -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" -o "%FilePath%" "%URL%"
if %errorlevel% neq 0 (
    echo [STATUS]: ERROR - Download Failed. Skipping upgrade.
    echo ------------------------------------------------------------------------------
    goto :eof
)

:: 3. SILENT UPGRADE DEPLOYMENT
echo Download finished. Upgrading silently in background...

if "%InstallArgs%"=="ZIP" (
    powershell -Command "Expand-Archive -Path '%FilePath%' -DestinationPath '%TargetFolder%\FirewallAppBlocker' -Force"
    echo [STATUS]: SUCCESS - Extracted/Overwritten to target folder.
) else (
    start /wait "" "%FilePath%" %InstallArgs%
    echo [STATUS]: SUCCESS - Silent install/upgrade completed.
)

echo ------------------------------------------------------------------------------
goto :eof