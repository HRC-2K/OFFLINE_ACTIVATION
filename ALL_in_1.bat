@echo off
setlocal enabledelayedexpansion

:: ===================================================
:: AUTOMATIC ADMINISTRATOR ELEVATION (UAC PROMPT)
:: ===================================================
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting Administrator privileges...
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /b
)

:: Explicit drive order: Checks C: first, then covers everything else alphabetically
set "DRIVES=C A B D E F G H I J K L M N O P Q R S T U V W X Y Z"

:MAIN_MENU
cls
echo ===================================================
echo     ULTIMATE FIREWALL AND EA OFFLINE MANAGER
echo ===================================================
echo.
echo  [1] Block Steam 
echo  [2] Block Ubisoft 
echo  [3] Block Epic Games 
echo  [4] Block Rockstar Launcher 
echo  [5] Block EA (Adapter Offline Method)
echo  [6] Block Custom Game Directory (Manual Folder Prompt)
echo  [7] Clear Firewall Rules (Unblock Options)
echo  [8] Exit
echo.
echo ===================================================
set /p "CHOICE=Select an option (1-8): "

if "%CHOICE%"=="1" goto BLOCK_STEAM
if "%CHOICE%"=="2" goto BLOCK_UBI
if "%CHOICE%"=="3" goto BLOCK_EPIC
if "%CHOICE%"=="4" goto BLOCK_ROCKSTAR
if "%CHOICE%"=="5" goto EA_ADAPTER_MENU
if "%CHOICE%"=="6" goto BLOCK_CUSTOM
if "%CHOICE%"=="7" goto CLEAR_MENU
if "%CHOICE%"=="8" exit
goto MAIN_MENU


:: ===================================================
:: FIREWALL BLOCKING LOGIC
:: ===================================================

:BLOCK_STEAM
cls
echo Scanning drives for Steam (Checking C: first)...
set "STEAM_PATH="
set "STEAM_COMMON="

for %%d in (%DRIVES%) do (
    if not defined STEAM_PATH (
        if exist "%%d:\Program Files (x86)\Steam" (
            set "STEAM_PATH=%%d:\Program Files (x86)\Steam"
            set "STEAM_BIN=%%d:\Program Files (x86)\Steam\bin"
        )
    )
    if not defined STEAM_COMMON (
        if exist "%%d:\Program Files (x86)\Common Files\Steam" (
            set "STEAM_COMMON=%%d:\Program Files (x86)\Common Files\Steam"
        )
    )
)

if not defined STEAM_PATH (
    echo [WARNING] Steam launcher files could not be found automatically.
    set /p "STEAM_PATH=Enter the correct Steam folder path (e.g., J:\Steam): "
    set "STEAM_BIN=!STEAM_PATH!\bin"
)
if not defined STEAM_COMMON set "STEAM_COMMON=C:\Program Files (x86)\Common Files\Steam"

echo.
echo Processing Steam folders... Please wait.
if exist "%STEAM_PATH%" (
    echo Blocking Main Directory and Games...
    for /r "%STEAM_PATH%" %%i in (*.exe) do (
        netsh advfirewall firewall add rule name="Offline_Steam_Block" dir=out action=block program="%%i" enable=yes >nul 2>&1
        netsh advfirewall firewall add rule name="Offline_Steam_Block" dir=in action=block program="%%i" enable=yes >nul 2>&1
    )
)
if exist "%STEAM_BIN%" (
    for /r "%STEAM_BIN%" %%i in (*.exe) do (
        netsh advfirewall firewall add rule name="Offline_Steam_Block" dir=out action=block program="%%i" enable=yes >nul 2>&1
        netsh advfirewall firewall add rule name="Offline_Steam_Block" dir=in action=block program="%%i" enable=yes >nul 2>&1
    )
)
if exist "%STEAM_COMMON%" (
    for /r "%STEAM_COMMON%" %%i in (*.exe) do (
        netsh advfirewall firewall add rule name="Offline_Steam_Block" dir=out action=block program="%%i" enable=yes >nul 2>&1
        netsh advfirewall firewall add rule name="Offline_Steam_Block" dir=in action=block program="%%i" enable=yes >nul 2>&1
    )
)
echo [SUCCESS] Steam inbound and outbound rules successfully applied!
pause
goto MAIN_MENU


:BLOCK_UBI
cls
echo Scanning drives for Ubisoft (Checking C: first)...
set "UBI_PATH="
for %%d in (%DRIVES%) do (
    if not defined UBI_PATH (
        if exist "%%d:\Program Files (x86)\Ubisoft" (
            set "UBI_PATH=%%d:\Program Files (x86)\Ubisoft"
        )
    )
)

if not defined UBI_PATH (
    echo [WARNING] Ubisoft launcher files could not be found automatically.
    set /p "UBI_PATH=Enter the correct Ubisoft folder path: "
)

echo.
echo Processing Ubisoft folders... Please wait.
for /r "%UBI_PATH%" %%i in (*.exe) do (
    netsh advfirewall firewall add rule name="Offline_Ubi_Block" dir=out action=block program="%%i" enable=yes >nul 2>&1
    netsh advfirewall firewall add rule name="Offline_Ubi_Block" dir=in action=block program="%%i" enable=yes >nul 2>&1
)
echo [SUCCESS] Ubisoft inbound and outbound rules successfully applied!
pause
goto MAIN_MENU


:BLOCK_EPIC
cls
echo Scanning drives for Epic Games Launcher...
set "EPIC_PATH="
for %%d in (%DRIVES%) do (
    if not defined EPIC_PATH (
        if exist "%%d:\Program Files (x86)\Epic Games" (
            set "EPIC_PATH=%%d:\Program Files (x86)\Epic Games"
        )
    )
)

if not defined EPIC_PATH (
    echo [WARNING] Epic Games Launcher could not be found automatically.
    set /p "EPIC_PATH=Enter the correct Epic Games Launcher folder path: "
)

echo.
echo Processing Epic Games Launcher folders... Please wait.
if exist "%EPIC_PATH%" (
    for /r "%EPIC_PATH%" %%i in (*.exe) do (
        netsh advfirewall firewall add rule name="Offline_Epic_Block" dir=out action=block program="%%i" enable=yes >nul 2>&1
        netsh advfirewall firewall add rule name="Offline_Epic_Block" dir=in action=block program="%%i" enable=yes >nul 2>&1
    )
)

if exist "%LOCALAPPDATA%\EpicGamesLauncher" (
    echo Processing WebHelper files...
    for /r "%LOCALAPPDATA%\EpicGamesLauncher" %%i in (*.exe) do (
        netsh advfirewall firewall add rule name="Offline_Epic_Block" dir=out action=block program="%%i" enable=yes >nul 2>&1
        netsh advfirewall firewall add rule name="Offline_Epic_Block" dir=in action=block program="%%i" enable=yes >nul 2>&1
    )
)

:: Explicit verification for Epic Game installation files
set "EPIC_GAME_DIR=C:\Program Files\Epic Games"
if exist "C:\Program Files\Epic Games" (
    echo Found default Epic Games directory at C:\Program Files\Epic Games
    goto DO_EPIC_GAME_BLOCK
)

:EPIC_PROMPT
echo.
echo [NOTICE] Default Epic Games directory not found on C:\
set /p "EPIC_GAME_DIR=Please enter or paste your custom Game download folder path (e.g. J:\Games\EpicGames): "

:DO_EPIC_GAME_BLOCK
if exist "%EPIC_GAME_DIR%" (
    echo.
    echo Processing Game Files directory inside: %EPIC_GAME_DIR%... Please wait.
    for /r "%EPIC_GAME_DIR%" %%i in (*.exe) do (
        netsh advfirewall firewall add rule name="Offline_Epic_Block" dir=out action=block program="%%i" enable=yes >nul 2>&1
        netsh advfirewall firewall add rule name="Offline_Epic_Block" dir=in action=block program="%%i" enable=yes >nul 2>&1
    )
    echo [SUCCESS] Epic Games Launcher and game directories successfully isolated!
) else (
    echo [ERROR] The path you typed does not exist.
    goto EPIC_PROMPT
)
pause
goto MAIN_MENU


:BLOCK_ROCKSTAR
cls
echo Scanning drives for Rockstar Launcher...
set "ROCKSTAR_MAIN="
set "ROCKSTAR_SC64="
set "ROCKSTAR_SC32="

for %%d in (%DRIVES%) do (
    if not defined ROCKSTAR_MAIN (
        if exist "%%d:\Program Files\Rockstar Games\Launcher" (
            set "ROCKSTAR_MAIN=%%d:\Program Files\Rockstar Games\Launcher"
        )
    )
    if not defined ROCKSTAR_SC64 (
        if exist "%%d:\Program Files\Rockstar Games\Social Club" (
            set "ROCKSTAR_SC64=%%d:\Program Files\Rockstar Games\Social Club"
        )
    )
    if not defined ROCKSTAR_SC32 (
        if exist "%%d:\Program Files (x86)\Rockstar Games\Social Club" (
            set "ROCKSTAR_SC32=%%d:\Program Files (x86)\Rockstar Games\Social Club"
        )
    )
)

if not defined ROCKSTAR_MAIN (
    echo [WARNING] Rockstar Launcher could not be found automatically.
    set /p "ROCKSTAR_MAIN=Enter your main Rockstar Games\Launcher folder path: "
)

echo.
echo Processing Rockstar folders... Please wait.
if exist "%ROCKSTAR_MAIN%" (
    for /r "%ROCKSTAR_MAIN%" %%i in (*.exe) do (
        netsh advfirewall firewall add rule name="Offline_Rockstar_Block" dir=out action=block program="%%i" enable=yes >nul 2>&1
        netsh advfirewall firewall add rule name="Offline_Rockstar_Block" dir=in action=block program="%%i" enable=yes >nul 2>&1
    )
)
if exist "%ROCKSTAR_SC64%" (
    for /r "%ROCKSTAR_SC64%" %%i in (*.exe) do (
        netsh advfirewall firewall add rule name="Offline_Rockstar_Block" dir=out action=block program="%%i" enable=yes >nul 2>&1
        netsh advfirewall firewall add rule name="Offline_Rockstar_Block" dir=in action=block program="%%i" enable=yes >nul 2>&1
    )
)
if exist "%ROCKSTAR_SC32%" (
    for /r "%ROCKSTAR_SC32%" %%i in (*.exe) do (
        netsh advfirewall firewall add rule name="Offline_Rockstar_Block" dir=out action=block program="%%i" enable=yes >nul 2>&1
        netsh advfirewall firewall add rule name="Offline_Rockstar_Block" dir=in action=block program="%%i" enable=yes >nul 2>&1
    )
)
if exist "%LOCALAPPDATA%\Rockstar Games" (
    for /r "%LOCALAPPDATA%\Rockstar Games" %%i in (*.exe) do (
        netsh advfirewall firewall add rule name="Offline_Rockstar_Block" dir=out action=block program="%%i" enable=yes >nul 2>&1
        netsh advfirewall firewall add rule name="Offline_Rockstar_Block" dir=in action=block program="%%i" enable=yes >nul 2>&1
    )
)
echo [SUCCESS] Rockstar folders successfully isolated!
pause
goto MAIN_MENU


:BLOCK_CUSTOM
cls
echo ===================================================
echo          CUSTOM GAME DIRECTORY BLOCKER
echo ===================================================
echo.
:CUSTOM_PROMPT
set /p "CUSTOM_DIR=Enter or paste the exact Game folder path (e.g., J:\Games\GTA V): "

if exist "%CUSTOM_DIR%" (
    echo.
    echo Processing Custom Directory... Please wait.
    for /r "%CUSTOM_DIR%" %%i in (*.exe) do (
        netsh advfirewall firewall add rule name="Offline_Custom_Block" dir=out action=block program="%%i" enable=yes >nul 2>&1
        netsh advfirewall firewall add rule name="Offline_Custom_Block" dir=in action=block program="%%i" enable=yes >nul 2>&1
    )
    echo.
    echo [SUCCESS] All executables inside "%CUSTOM_DIR%" successfully blocked!
) else (
    echo.
    echo [ERROR] The folder path you typed does not exist. Please try again.
    goto CUSTOM_PROMPT
)
pause
goto MAIN_MENU


:: ===================================================
:: EA ADAPTER OFFLINE SUB-MENU & SYSTEM (Merged)
:: ===================================================

:EA_ADAPTER_MENU
cls
echo ===================================================
echo             EA APP AUTOMATED OFFLINE TOOL
echo ===================================================
echo  1. Launch EA + Game in Strict Offline Loop
echo  2. Clear / Reset (Force Kill Running Instances)
echo  3. Back to Main Menu
echo ===================================================
echo.
set /p adapter_choice="Choose an option (1-3): "

if "%adapter_choice%"=="1" goto LAUNCH_OFFLINE
if "%adapter_choice%"=="2" goto FORCE_CLEANUP
if "%adapter_choice%"=="3" goto MAIN_MENU
goto EA_ADAPTER_MENU


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
    goto EA_ADAPTER_MENU
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
    goto EA_ADAPTER_MENU
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
echo 3. Return to this window ONLY AFTER your game has fully booted up.
echo.
pause

echo.
echo 6. Game running! Restoring PC internet access (Adapters ON)...
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
goto EA_ADAPTER_MENU


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
goto EA_ADAPTER_MENU

:: ===================================================
:: FIREWALL UNBLOCKING LOGIC
:: ===================================================

:CLEAR_MENU
cls
echo ===================================================
echo               UNBLOCK / CLEAR MENU
echo ===================================================
echo.
echo  [1] Unblock Steam          [5] Unblock Custom Folder Rules
echo  [2] Unblock Ubisoft        [6] UNBLOCK ALL CLIENTS
echo  [3] Unblock Epic Games     [7] Back to Main Menu
echo  [4] Unblock Rockstar
echo.
echo ===================================================
set /p "CLEAR_CHOICE=Select an option (1-7): "

if "%CLEAR_CHOICE%"=="1" netsh advfirewall firewall delete rule name="Offline_Steam_Block" >nul 2>&1 & echo Steam restored! & pause
if "%CLEAR_CHOICE%"=="2" netsh advfirewall firewall delete rule name="Offline_Ubi_Block" >nul 2>&1 & echo Ubisoft restored! & pause
if "%CLEAR_CHOICE%"=="3" netsh advfirewall firewall delete rule name="Offline_Epic_Block" >nul 2>&1 & echo Epic restored! & pause
if "%CLEAR_CHOICE%"=="4" netsh advfirewall firewall delete rule name="Offline_Rockstar_Block" >nul 2>&1 & echo Rockstar restored! & pause
if "%CLEAR_CHOICE%"=="5" netsh advfirewall firewall delete rule name="Offline_Custom_Block" >nul 2>&1 & echo Custom rules cleared! & pause
if "%CLEAR_CHOICE%"=="6" goto CLEAR_ALL
goto MAIN_MENU

:CLEAR_ALL
echo.
echo Removing all created firewall blocks...
netsh advfirewall firewall delete rule name="Offline_Steam_Block" >nul 2>&1
netsh advfirewall firewall delete rule name="Offline_Ubi_Block" >nul 2>&1
netsh advfirewall firewall delete rule name="Offline_Epic_Block" >nul 2>&1
netsh advfirewall firewall delete rule name="Offline_Rockstar_Block" >nul 2>&1
netsh advfirewall firewall delete rule name="Offline_Custom_Block" >nul 2>&1
netsh advfirewall firewall delete rule name="Offline_Biz_Block" >nul 2>&1

echo [SUCCESS] All clients and custom rules unblocked. Internet access completely restored!
pause
goto MAIN_MENU
