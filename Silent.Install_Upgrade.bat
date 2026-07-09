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
echo  [1] UltraViewer 
echo  [2] Cloudflare 1.1.1.1 WARP
echo  [3] Firewall App Blocker (Extracts Only)
echo  [4] Steam 
echo  [5] Ubisoft Connect 
echo  [6] Epic Games 
echo  [7] Rockstar Games (Manual Install)
echo  [8] EA App 
echo  [9] TcNo Account Switcher
echo  [10] Bulk Crap Uninstaller
echo  [11] Run All-in-1 Script
echo  [12] Run EA Adapter Offline Script
echo  [13] Run Steam/Ubi/Epic/Rockstar Script
echo  [14] Update Silent Install Master Script
echo  [A] Upgrade / Install ALL Items
echo  [X] Exit
echo ==============================================================================
echo  Files will be saved to: %TargetFolder%
echo ==============================================================================
echo.

set /p choice="Enter numbers separated by spaces (e.g., 1 4 10): "

if /i "%choice%"=="X" exit /b
if /i "%choice%"=="A" set choice=1 2 3 4 5 6 7 8 9 10 11 12 13 14

echo.
echo Starting automated smart upgrade process...
echo ==============================================================================

:: Loop through choices
for %%i in (%choice%) do (
    if "%%i"=="1" call :ProcessApp "https://www.ultraviewer.net/en/UltraViewer_setup_6.6_en.exe" "UltraViewer_setup_6.6_en.exe" "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART" "UltraViewer.exe"
    if "%%i"=="2" call :ProcessApp "https://downloads.cloudflareclient.com/v1/download/windows/ga" "Cloudflare_1.1.1.1_Setup.msi" "/quiet /norestart ONBOARDING=false" "CloudflareWARP.exe"
    if "%%i"=="3" call :ProcessApp "https://www.sordum.org/files/downloads.php?firewall-app-blocker" "FirewallAppBlocker.zip" "ZIP" "Fab.exe"
    if "%%i"=="4" call :ProcessApp "https://cdn.akamai.steamstatic.com/client/installer/SteamSetup.exe" "SteamSetup.exe" "/S" "steam.exe"
    if "%%i"=="5" call :ProcessApp "https://ubi.li/4vxt9" "UbisoftConnectInstaller.exe" "/S" "upc.exe"
    if "%%i"=="6" call :ProcessApp "https://launcher-public-service-prod06.ol.epicgames.com/launcher/api/installer/download/EpicGamesLauncherInstaller.exe" "EpicGamesLauncherInstaller.exe" "/qn /norestart" "EpicGamesLauncher.exe"
    if "%%i"=="7" call :ProcessApp "https://gamedownloads.rockstargames.com/public/installer/Rockstar-Games-Launcher.exe" "Rockstar-Games-Launcher.exe" "/s /v\"/qn\"" "Launcher.exe"
	if "%%i"=="8" call :ProcessApp "https://origin-a.akamaihd.net/EA-Desktop-Client-Download/installer-releases/EAappInstaller.exe" "EAappInstaller.exe" "/q" "EADesktop.exe"
	if "%%i"=="9" call :ProcessApp "https://github.com/TCNOco/TcNo-Acc-Switcher/releases/download/2025-11-20_03/TcNo.Account.Switcher.-.Installer_2025-11-20_03.exe" "TcNo.Account.Switcher.exe" "/S" "TcNo Account Switcher.exe"
    if "%%i"=="10" call :ProcessApp "https://github.com/BCUninstaller/Bulk-Crap-Uninstaller/releases/download/v6.2/BCUninstaller_6.2.0_setup.exe" "BCUninstaller_6.2.0_setup.exe" "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART" "BCUninstaller.exe"
    if "%%i"=="11" call :ProcessApp "https://github.com/HRC-2K/OFFLINE_ACTIVATION/releases/download/OA/ALL_in_1.bat" "ALL_in_1.bat" "BAT" "none"
    if "%%i"=="12" call :ProcessApp "https://github.com/HRC-2K/OFFLINE_ACTIVATION/releases/download/OA/EA_Adapter_Offline_Method.bat" "EA_Adapter_Offline_Method.bat" "BAT" "none"
    if "%%i"=="13" call :ProcessApp "https://github.com/HRC-2K/OFFLINE_ACTIVATION/releases/download/OA/Steam_Ubi_Epic_RStar.bat" "Steam_Ubi_Epic_RStar.bat" "BAT" "none"
	if "%%i"=="14" call :ProcessApp "https://github.com/HRC-2K/OFFLINE_ACTIVATION/releases/download/OA/Silent.Install_Upgrade.bat" "Silent.Install_Upgrade.bat" "BAT" "none"
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
if not "%ProcessName%"=="none" (
    tasklist /FI "IMAGENAME eq %ProcessName%" 2>NUL | find /I /N "%ProcessName%">NUL
    if %errorlevel% equ 0 (
        echo [INFO]: %ProcessName% is currently running. Terminating to allow upgrade...
        taskkill /f /im "%ProcessName%" >nul 2>&1
        timeout /t 2 >nul
    )
)

:: 2. DOWNLOAD
curl -L -# -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" -o "%FilePath%" "%URL%"
if %errorlevel% neq 0 (
    echo [STATUS]: ERROR - Download Failed. Skipping upgrade.
    echo ------------------------------------------------------------------------------
    goto :eof
)

:: 3. DEPLOYMENT SWITCHES
echo Download finished. Processing file...

if "%InstallArgs%"=="ZIP" (
    powershell -Command "Expand-Archive -Path '%FilePath%' -DestinationPath '%TargetFolder%\FirewallAppBlocker' -Force"
    echo [STATUS]: SUCCESS - Extracted to target folder.
) else if "%InstallArgs%"=="BAT" (
    echo Running batch script in a new terminal environment...
    start /wait cmd.exe /c "%FilePath%"
    echo [STATUS]: SUCCESS - Batch script executed.
) else if /i "%FileName:~-4%"==".msi" (
    start /wait msiExec.exe /i "%FilePath%" %InstallArgs%
    echo [STATUS]: SUCCESS - Silent MSI install completed.
) else if /i "%FileName:~-4%"==".exe" (
    start /wait "" "%FilePath%" %InstallArgs%
    echo [STATUS]: SUCCESS - Silent executable install completed.
)

:: 4. AUTOMATIC CLEANUP (Deletes the downloaded file ONLY after it completely exits)
if exist "%FilePath%" (
    echo [CLEANUP]: Removing downloaded installer package...
    del /f /q "%FilePath%" >nul 2>&1
)

echo ------------------------------------------------------------------------------
goto :eof
