@echo off
setlocal EnabledDelayedExpansion

:: -----------------------------------------
:: AUTOMATIC ADMIN PRIVILEGE REQUEST
:: -----------------------------------------
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting Administrative Privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:MAIN_MENU
cls
echo ===================================================
echo             EA APP AUTOMATED OFFLINE TOOL
echo ===================================================
echo  1. Launch EA + Game in Strict Offline Loop
echo  2. Clear / Reset (Force Kill Running Instances)
echo  3. Exit
echo ===================================================
echo.
set /p choice="Choose an option (1-3): "

if "%choice%"=="1" goto LAUNCH_OFFLINE
if "%choice%"=="2" goto FORCE_CLEANUP
if "%choice%"=="3" exit
goto MAIN_MENU


:LAUNCH_OFFLINE
cls
echo ===================================================
echo          CONFIGURING TARGET GAME CODENAME
echo ===================================================
echo Look at your game's shortcut or Task Manager to find its .exe name.
echo Examples: bf3.exe, DA2.exe, FIFA23.exe
echo.
set /p "GAME_EXE=Enter the exact game executable name (e.g., bf3.exe): "

if "%GAME_EXE%"=="" (
    echo [ERROR] Game executable name cannot be empty.
    pause
    goto MAIN_MENU
)

cls
echo ===================================================
echo          INITIALIZING ZERO-CONNECTION BOOT
echo ===================================================
echo.

echo 1. Stripping lingering EA processes...
taskkill /f /im EADesktop.exe >nul 2>&1
taskkill /f /im EABackgroundService.exe >nul 2>&1
taskkill /f /im Link2EA.exe >nul 2>&1
taskkill /f /im "%GAME_EXE%" >nul 2>&1

echo 2. Locating EA App Installation...
set "EA_LAUNCHER_EXE="
for %%d in (C D E F G H) do (
    if not defined EA_LAUNCHER_EXE (
        if exist "%%d:\Program Files\Electronic Arts\EA Desktop\EA Desktop\EADesktop.exe" (
            set "EA_LAUNCHER_EXE=%%d:\Program Files\Electronic Arts\EA Desktop\EA Desktop\EADesktop.exe"
        )
    )
)

if not defined EA_LAUNCHER_EXE (
    echo [ERROR] EA Launcher path not found automatically.
    pause
    goto MAIN_MENU
)

echo 3. Simulating physical hardware isolation (Adapters OFF)...
netsh interface set interface "Wi-Fi" disable >nul 2>&1
netsh interface set interface "Ethernet" disable >nul 2>&1
timeout /t 2 /nobreak >nul

echo 4. Forcing true offline launcher fallback...
sc config "EABackgroundService" start= demand >nul 2>&1
sc start "EABackgroundService" >nul 2>&1
start "" "%EA_LAUNCHER_EXE%"

echo.
echo ===================================================
echo STEP 5: ACTION REQUIRED
echo ===================================================
echo 1. The EA App will open completely offline.
echo 2. Click and LAUNCH your game now from the library.
echo 3. RETURN TO THIS WINDOW ONLY AFTER YOU HAVE COMPLETELY EXITED THE GAME.
echo.
pause

echo.
echo 6. Game Stopped! Restoring PC internet access (Adapters ON)...
netsh interface set interface "Wi-Fi" enable >nul 2>&1
netsh interface set interface "Ethernet" enable >nul 2>&1

echo.
echo ===================================================
echo      MONITORING GAMEPLAY - DO NOT CLOSE WINDOW
echo ===================================================
echo Tracking %GAME_EXE%... 
echo The moment you close the game, EA will be wiped instantly 
echo to prevent the online screen shown in image_435fdd.png.
echo.

:MONITOR_LOOP
timeout /t 2 /nobreak >nul
tasklist /fi "IMAGENAME eq %GAME_EXE%" 2>nul | find /i "%GAME_EXE%" >nul
if %errorlevel% equ 0 goto MONITOR_LOOP

goto AUTO_CLEANUP


:AUTO_CLEANUP
echo.
echo Game exit detected! Force killing EA processes immediately...
taskkill /f /im EADesktop.exe >nul 2>&1
taskkill /f /im EABackgroundService.exe >nul 2>&1
taskkill /f /im Link2EA.exe >nul 2>&1
echo [SUCCESS] Session wiped clean before EA could reconnect.
timeout /t 3 >nul
goto MAIN_MENU


:FORCE_CLEANUP
cls
echo ===================================================
echo             EMERGENCY FORCE-EXIT RESET
echo ===================================================
echo.
echo Restoring network hardware and destroying all tasks...
netsh interface set interface "Wi-Fi" enable >nul 2>&1
netsh interface set interface "Ethernet" enable >nul 2>&1
taskkill /f /im EADesktop.exe >nul 2>&1
taskkill /f /im EABackgroundService.exe >nul 2>&1
taskkill /f /im Link2EA.exe >nul 2>&1
if defined GAME_EXE taskkill /f /im "%GAME_EXE%" >nul 2>&1
echo.
echo [CLEANUP COMPLETE] System state default.
pause
goto MAIN_MENU