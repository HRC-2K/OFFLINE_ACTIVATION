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
echo        ULTIMATE FIREWALL ACTIVATION MANAGER
echo ===================================================
echo.
echo  [1] Block Steam 
echo  [2] Block Ubisoft 
echo  [3] Block Epic Games 
echo  [4] Block Rockstar Launcher 
echo  [5] Block Custom Game Directory (Manual Folder Prompt)
echo  [6] Clear Firewall Rules (Unblock Options)
echo  [7] Exit
echo.
echo ===================================================
set /p "CHOICE=Select an option (1-7): "

if "%CHOICE%"=="1" goto BLOCK_STEAM
if "%CHOICE%"=="2" goto BLOCK_UBI
if "%CHOICE%"=="3" goto BLOCK_EPIC
if "%CHOICE%"=="4" goto BLOCK_ROCKSTAR
if "%CHOICE%"=="5" goto BLOCK_CUSTOM
if "%CHOICE%"=="6" goto CLEAR_MENU
if "%CHOICE%"=="7" exit
goto MAIN_MENU

:: ===================================================
:: BLOCKING LOGIC
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
echo          CUSTOM GAME DIRECTORY BLOCKER (FAB MODE)
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
:: UNBLOCKING LOGIC
:: ===================================================

:CLEAR_MENU
cls
echo ===================================================
echo               UNBLOCK / CLEAR MENU
echo ===================================================
echo.
echo  [1] Unblock Steam          [4] Unblock Rockstar
echo  [2] Unblock Ubisoft        [5] Unblock Custom Folder Rules
echo  [3] Unblock Epic Games     [6] UNBLOCK ALL CLIENTS
echo  [7] Back to Main Menu
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
