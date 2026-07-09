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
echo                FULLY SILENT DOWNLOADER + INSTALLER MENU
echo ==============================================================================
echo  [1] UltraViewer
echo  [2] Cloudflare 1.1.1.1 WARP
echo  [3] Firewall App Blocker (Extracts Only)
echo  [4] Steam 
echo  [5] Ubisoft Connect 
echo  [6] Epic Games 
echo  [7] Rockstar Games  
echo  [8] EA App
echo  [9] TcNo Account Switcher
echo  [A] Download and Silently Install ALL Apps
echo  [X] Exit
echo ==============================================================================
echo  Files will be saved to: %TargetFolder%
echo ==============================================================================
echo.

set /p choice="Enter numbers separated by spaces (e.g., 1 4 6): "

if /i "%choice%"=="X" exit /b
if /i "%choice%"=="A" set choice=1 2 3 4 5 6 7 8 9

echo.
echo Starting 100%% silent downloads and installations...
echo ==============================================================================

:: Loop through choices
for %%i in (%choice%) do (
    if "%%i"=="1" call :ProcessApp "https://www.ultraviewer.net/en/UltraViewer_setup_6.6_en.exe" "UltraViewer_setup_6.6_en.exe" "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART"
    if "%%i"=="2" call :ProcessApp "https://1111-releases.cloudflareclient.com/win/latest" "Cloudflare_1.1.1.1_Setup.exe" "/quiet /norestart"
    if "%%i"=="3" call :ProcessApp "https://www.sordum.org/files/downloads.php?firewall-app-blocker" "FirewallAppBlocker.zip" "ZIP"
    if "%%i"=="4" call :ProcessApp "https://cdn.akamai.steamstatic.com/client/installer/SteamSetup.exe" "SteamSetup.exe" "/S"
    if "%%i"=="5" call :ProcessApp "https://ubi.li/4vxt9" "UbisoftConnectInstaller.exe" "/S"
    if "%%i"=="6" call :ProcessApp "https://launcher-public-service-prod06.ol.epicgames.com/launcher/api/installer/download/EpicGamesLauncherInstaller.exe" "EpicGamesLauncherInstaller.exe" "/qn /norestart"
    if "%%i"=="7" call :ProcessApp "https://gamedownloads.rockstargames.com/public/installer/Rockstar-Games-Launcher.exe" "Rockstar-Games-Launcher.exe" "/S /v/qn"
    if "%%i"=="8" call :ProcessApp "https://origin-a.akamaihd.net/EA-Desktop-Client-Download/installer-releases/EAappInstaller.exe" "EAappInstaller.exe" "/q"
    if "%%i"=="9" call :ProcessApp "https://github.com/TCNOco/TcNo-Acc-Switcher/releases/download/2025-11-20_03/TcNo.Account.Switcher.-.Installer_2025-11-20_03.exe" "TcNo.Account.Switcher.exe" "/S"
)

echo ==============================================================================
echo All selected scripts ran successfully.
echo.
pause
goto MENU

:: Core processing function
:ProcessApp
set "URL=%~1"
set "FileName=%~2"
set "InstallArgs=%~3"
set "FilePath=%TargetFolder%\%FileName%"

echo.
echo [PROCESSING]: %FileName%
echo [SOURCE]: %URL%
echo ------------------------------------------------------------------------------

:: 1. DOWNLOAD
curl -L -# -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" -o "%FilePath%" "%URL%"
if %errorlevel% neq 0 (
    echo [STATUS]: ERROR - Download Failed. Skipping install.
    echo ------------------------------------------------------------------------------
    goto :eof
)

:: 2. SILENT INSTALL
echo Downloading finished. Installing silently in background...

if "%InstallArgs%"=="ZIP" (
    powershell -Command "Expand-Archive -Path '%FilePath%' -DestinationPath '%TargetFolder%\FirewallAppBlocker' -Force"
    echo [STATUS]: SUCCESS - Extracted to folder.
) else (
    start /wait "" "%FilePath%" %InstallArgs%
    echo [STATUS]: SUCCESS - Silent install completed.
)

echo ------------------------------------------------------------------------------
goto :eof