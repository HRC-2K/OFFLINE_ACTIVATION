# ===================================================
# AUTOMATIC ADMINISTRATOR ELEVATION (UAC PROMPT)
# ===================================================
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)

if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Requesting Administrator privileges..." -ForegroundColor Yellow
    $scriptPath = $MyInvocation.MyCommand.Path
    if ($scriptPath) {
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
    } else {
        $scriptContent = $MyInvocation.MyCommand.ScriptBlock.ToString()
        $bytes = [System.Text.Encoding]::Unicode.GetBytes($scriptContent)
        $encodedCommand = [Convert]::ToBase64String($bytes)
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -EncodedCommand $encodedCommand" -Verb RunAs
    }
    exit
}

# Explicit drive order
$DRIVES = @("C", "A", "B", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z")

function Show-MainMenu {
    Clear-Host
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "    ULTIMATE FIREWALL AND EA OFFLINE MANAGER" -ForegroundColor Yellow
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " [1] Block Steam"
    Write-Host " [2] Block Ubisoft"
    Write-Host " [3] Block Epic Games"
    Write-Host " [4] Block Rockstar Launcher"
    Write-Host " [5] Block EA (Adapter Offline Method)"
    Write-Host " [6] Block Custom Game Directory (Manual Folder Prompt)"
    Write-Host " [7] Clear Firewall Rules (Unblock Options)"
    Write-Host " [8] Return"
    Write-Host ""
    Write-Host "===================================================" -ForegroundColor Cyan
}

# Helper Function: Recursively adds inbound & outbound firewall rules for exes in a folder
function Add-FirewallRulesForPath ($folderPath, $ruleName) {
    if (Test-Path $folderPath) {
        $exeFiles = Get-ChildItem -Path $folderPath -Filter "*.exe" -Recurse -ErrorAction SilentlyContinue
        foreach ($exe in $exeFiles) {
            netsh advfirewall firewall add rule name=$ruleName dir=out action=block program="$($exe.FullName)" enable=yes > $null 2>&1
            netsh advfirewall firewall add rule name=$ruleName dir=in action=block program="$($exe.FullName)" enable=yes > $null 2>&1
        }
    }
}

# ===================================================
# FIREWALL BLOCKING LOGIC
# ===================================================

function Block-Steam {
    Clear-Host
    Write-Host "Scanning drives for Steam (Checking C: first)..." -ForegroundColor Yellow
    $steamPath = $null
    $steamCommon = $null
    $steamBin = $null

    foreach ($d in $DRIVES) {
        if (-not $steamPath -and (Test-Path "$d`:\Program Files (x86)\Steam")) {
            $steamPath = "$d`:\Program Files (x86)\Steam"
            $steamBin = "$d`:\Program Files (x86)\Steam\bin"
        }
        if (-not $steamCommon -and (Test-Path "$d`:\Program Files (x86)\Common Files\Steam")) {
            $steamCommon = "$d`:\Program Files (x86)\Common Files\Steam"
        }
    }

    if (-not $steamPath) {
        Write-Host "[WARNING] Steam launcher files could not be found automatically." -ForegroundColor Red
        $steamPath = Read-Host "Enter the correct Steam folder path (e.g., J:\Steam)"
        $steamBin = Join-Path $steamPath "bin"
    }
    if (-not $steamCommon) { $steamCommon = "C:\Program Files (x86)\Common Files\Steam" }

    Write-Host "`nProcessing Steam folders... Please wait." -ForegroundColor Cyan
    Add-FirewallRulesForPath $steamPath "Offline_Steam_Block"
    Add-FirewallRulesForPath $steamBin "Offline_Steam_Block"
    Add-FirewallRulesForPath $steamCommon "Offline_Steam_Block"

    Write-Host "[SUCCESS] Steam inbound and outbound rules successfully applied!" -ForegroundColor Green
    Read-Host "Press Enter to return to main menu..."
}

function Block-Ubi {
    Clear-Host
    Write-Host "Scanning drives for Ubisoft (Checking C: first)..." -ForegroundColor Yellow
    $ubiPath = $null

    foreach ($d in $DRIVES) {
        if (-not $ubiPath -and (Test-Path "$d`:\Program Files (x86)\Ubisoft")) {
            $ubiPath = "$d`:\Program Files (x86)\Ubisoft"
        }
    }

    if (-not $ubiPath) {
        Write-Host "[WARNING] Ubisoft launcher files could not be found automatically." -ForegroundColor Red
        $ubiPath = Read-Host "Enter the correct Ubisoft folder path"
    }

    Write-Host "`nProcessing Ubisoft folders... Please wait." -ForegroundColor Cyan
    Add-FirewallRulesForPath $ubiPath "Offline_Ubi_Block"

    Write-Host "[SUCCESS] Ubisoft inbound and outbound rules successfully applied!" -ForegroundColor Green
    Read-Host "Press Enter to return to main menu..."
}

function Block-Epic {
    Clear-Host
    Write-Host "Scanning drives for Epic Games Launcher..." -ForegroundColor Yellow
    $epicPath = $null

    foreach ($d in $DRIVES) {
        if (-not $epicPath -and (Test-Path "$d`:\Program Files (x86)\Epic Games")) {
            $epicPath = "$d`:\Program Files (x86)\Epic Games"
        }
    }

    if (-not $epicPath) {
        Write-Host "[WARNING] Epic Games Launcher could not be found automatically." -ForegroundColor Red
        $epicPath = Read-Host "Enter the correct Epic Games Launcher folder path"
    }

    Write-Host "`nProcessing Epic Games Launcher folders... Please wait." -ForegroundColor Cyan
    Add-FirewallRulesForPath $epicPath "Offline_Epic_Block"

    $localEpic = "$env:LOCALAPPDATA\EpicGamesLauncher"
    if (Test-Path $localEpic) {
        Write-Host "Processing WebHelper files..." -ForegroundColor Yellow
        Add-FirewallRulesForPath $localEpic "Offline_Epic_Block"
    }

    $epicGameDir = "C:\Program Files\Epic Games"
    if (Test-Path $epicGameDir) {
        Write-Host "Found default Epic Games directory at C:\Program Files\Epic Games" -ForegroundColor Green
    } else {
        do {
            Write-Host "`n[NOTICE] Default Epic Games directory not found on C:\" -ForegroundColor Yellow
            $epicGameDir = Read-Host "Please enter or paste your custom Game download folder path (e.g. J:\Games\EpicGames)"
            $valid = Test-Path $epicGameDir
            if (-not $valid) { Write-Host "[ERROR] The path you typed does not exist." -ForegroundColor Red }
        } while (-not $valid)
    }

    Write-Host "`nProcessing Game Files directory inside: $epicGameDir... Please wait." -ForegroundColor Cyan
    Add-FirewallRulesForPath $epicGameDir "Offline_Epic_Block"

    Write-Host "[SUCCESS] Epic Games Launcher and game directories successfully isolated!" -ForegroundColor Green
    Read-Host "Press Enter to return to main menu..."
}

function Block-Rockstar {
    Clear-Host
    Write-Host "Scanning drives for Rockstar Launcher..." -ForegroundColor Yellow
    $rockstarMain = $null
    $rockstarSC64 = $null
    $rockstarSC32 = $null

    foreach ($d in $DRIVES) {
        if (-not $rockstarMain -and (Test-Path "$d`:\Program Files\Rockstar Games\Launcher")) {
            $rockstarMain = "$d`:\Program Files\Rockstar Games\Launcher"
        }
        if (-not $rockstarSC64 -and (Test-Path "$d`:\Program Files\Rockstar Games\Social Club")) {
            $rockstarSC64 = "$d`:\Program Files\Rockstar Games\Social Club"
        }
        if (-not $rockstarSC32 -and (Test-Path "$d`:\Program Files (x86)\Rockstar Games\Social Club")) {
            $rockstarSC32 = "$d`:\Program Files (x86)\Rockstar Games\Social Club"
        }
    }

    if (-not $rockstarMain) {
        Write-Host "[WARNING] Rockstar Launcher could not be found automatically." -ForegroundColor Red
        $rockstarMain = Read-Host "Enter your main Rockstar Games\Launcher folder path"
    }

    Write-Host "`nProcessing Rockstar folders... Please wait." -ForegroundColor Cyan
    Add-FirewallRulesForPath $rockstarMain "Offline_Rockstar_Block"
    Add-FirewallRulesForPath $rockstarSC64 "Offline_Rockstar_Block"
    Add-FirewallRulesForPath $rockstarSC32 "Offline_Rockstar_Block"
    Add-FirewallRulesForPath "$env:LOCALAPPDATA\Rockstar Games" "Offline_Rockstar_Block"

    Write-Host "[SUCCESS] Rockstar folders successfully isolated!" -ForegroundColor Green
    Read-Host "Press Enter to return to main menu..."
}

function Block-Custom {
    Clear-Host
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "          CUSTOM GAME DIRECTORY BLOCKER" -ForegroundColor Yellow
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host ""

    do {
        $customDir = Read-Host "Enter or paste the exact Game folder path (e.g., J:\Games\GTA V)"
        $valid = Test-Path $customDir
        if (-not $valid) {
            Write-Host "`n[ERROR] The folder path you typed does not exist. Please try again.`n" -ForegroundColor Red
        }
    } while (-not $valid)

    Write-Host "`nProcessing Custom Directory... Please wait." -ForegroundColor Cyan
    Add-FirewallRulesForPath $customDir "Offline_Custom_Block"

    Write-Host "`n[SUCCESS] All executables inside `"$customDir`" successfully blocked!" -ForegroundColor Green
    Read-Host "Press Enter to return to main menu..."
}

# ===================================================
# EA ADAPTER OFFLINE SUB-MENU & SYSTEM
# ===================================================

function Show-EaAdapterMenu {
    do {
        Clear-Host
        Write-Host "===================================================" -ForegroundColor Cyan
        Write-Host "             EA APP AUTOMATED OFFLINE TOOL" -ForegroundColor Yellow
        Write-Host "===================================================" -ForegroundColor Cyan
        Write-Host "  1. Launch EA + Game in Strict Offline Loop"
        Write-Host "  2. Clear / Reset (Force Kill Running Instances)"
        Write-Host "  3. Back to Main Menu"
        Write-Host "===================================================" -ForegroundColor Cyan
        Write-Host ""
        $adapterChoice = Read-Host "Choose an option (1-3)"

        switch ($adapterChoice) {
            "1" { Invoke-EaLaunchOffline }
            "2" { Invoke-EaForceCleanup }
            "3" { return }
        }
    } while ($true)
}

function Invoke-EaLaunchOffline {
    Clear-Host
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "          CONFIGURING TARGET GAME CODENAME" -ForegroundColor Yellow
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "Look at your game's shortcut or Task Manager to find its .exe name."
    Write-Host "Examples: bf3.exe, DA2.exe, FIFA23.exe`n"
    
    $global:GAME_EXE = Read-Host "Enter the exact game executable name (e.g., bf3.exe)"

    if ([string]::IsNullOrWhiteSpace($global:GAME_EXE)) {
        Write-Host "[ERROR] Game executable name cannot be empty." -ForegroundColor Red
        Read-Host "Press Enter to return..."
        return
    }

    Clear-Host
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "          INITIALIZING ZERO-CONNECTION BOOT" -ForegroundColor Yellow
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "1. Stripping lingering EA processes..." -ForegroundColor Yellow
    $exeNameNoExt = [System.IO.Path]::GetFileNameWithoutExtension($global:GAME_EXE)
    Stop-Process -Name "EADesktop", "EABackgroundService", "Link2EA", $exeNameNoExt -Force -ErrorAction SilentlyContinue

    Write-Host "2. Locating EA App Installation..." -ForegroundColor Yellow
    $eaLauncherExe = $null
    foreach ($d in @("C", "D", "E", "F", "G", "H")) {
        $testPath = "$d`:\Program Files\Electronic Arts\EA Desktop\EA Desktop\EADesktop.exe"
        if (Test-Path $testPath) {
            $eaLauncherExe = $testPath
            break
        }
    }

    if (-not $eaLauncherExe) {
        Write-Host "[ERROR] EA Launcher path not found automatically." -ForegroundColor Red
        Read-Host "Press Enter to return..."
        return
    }

    Write-Host "3. Simulating physical hardware isolation (Adapters OFF)..." -ForegroundColor Yellow
    Disable-NetAdapter -Name "Wi-Fi", "Ethernet" -Confirm:$false -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2

    Write-Host "4. Forcing true offline launcher fallback..." -ForegroundColor Yellow
    Set-Service -Name "EABackgroundService" -StartupType Manual -ErrorAction SilentlyContinue
    Start-Service -Name "EABackgroundService" -ErrorAction SilentlyContinue
    Start-Process -FilePath $eaLauncherExe

    Write-Host "`n===================================================" -ForegroundColor Cyan
    Write-Host "STEP 5: ACTION REQUIRED" -ForegroundColor Yellow
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "1. The EA App will open completely offline."
    Write-Host "2. Click and LAUNCH your game now from the library."
    Write-Host "3. Return to this window ONLY AFTER your game has fully booted up.`n"
    Read-Host "Press Enter AFTER your game is running..."

    Write-Host "`n6. Game running! Restoring PC internet access (Adapters ON)..." -ForegroundColor Green
    Enable-NetAdapter -Name "Wi-Fi", "Ethernet" -Confirm:$false -ErrorAction SilentlyContinue

    Write-Host "`n===================================================" -ForegroundColor Cyan
    Write-Host "      MONITORING GAMEPLAY - DO NOT CLOSE WINDOW" -ForegroundColor Yellow
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "Tracking $global:GAME_EXE..."
    Write-Host "The moment you close the game, EA will be wiped instantly`n"

    # Monitor loop
    while ($true) {
        Start-Sleep -Seconds 2
        $running = Get-Process -Name $exeNameNoExt -ErrorAction SilentlyContinue
        if (-not $running) { break }
    }

    # Auto Cleanup
    Write-Host "`nGame exit detected! Force killing EA processes immediately..." -ForegroundColor Yellow
    Stop-Process -Name "EADesktop", "EABackgroundService", "Link2EA" -Force -ErrorAction SilentlyContinue
    Write-Host "[SUCCESS] Session wiped clean before EA could reconnect." -ForegroundColor Green
    Start-Sleep -Seconds 3
}

function Invoke-EaForceCleanup {
    Clear-Host
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "             EMERGENCY FORCE-EXIT RESET" -ForegroundColor Yellow
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "`nRestoring network hardware and destroying all tasks..." -ForegroundColor Yellow

    Enable-NetAdapter -Name "Wi-Fi", "Ethernet" -Confirm:$false -ErrorAction SilentlyContinue
    Stop-Process -Name "EADesktop", "EABackgroundService", "Link2EA" -Force -ErrorAction SilentlyContinue

    if ($global:GAME_EXE) {
        $exeNameNoExt = [System.IO.Path]::GetFileNameWithoutExtension($global:GAME_EXE)
        Stop-Process -Name $exeNameNoExt -Force -ErrorAction SilentlyContinue
    }

    Write-Host "`n[CLEANUP COMPLETE] System state default." -ForegroundColor Green
    Read-Host "Press Enter to return..."
}

# ===================================================
# FIREWALL UNBLOCKING LOGIC
# ===================================================

function Show-ClearMenu {
    Clear-Host
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "               UNBLOCK / CLEAR MENU" -ForegroundColor Yellow
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] Unblock Steam          [5] Unblock Custom Folder Rules"
    Write-Host "  [2] Unblock Ubisoft        [6] UNBLOCK ALL CLIENTS"
    Write-Host "  [3] Unblock Epic Games     [7] Back to Main Menu"
    Write-Host "  [4] Unblock Rockstar"
    Write-Host ""
    Write-Host "===================================================" -ForegroundColor Cyan
    $clearChoice = Read-Host "Select an option (1-7)"

    switch ($clearChoice) {
        "1" { netsh advfirewall firewall delete rule name="Offline_Steam_Block" > $null 2>&1; Write-Host "Steam restored!" -ForegroundColor Green; Read-Host "Press Enter..." }
        "2" { netsh advfirewall firewall delete rule name="Offline_Ubi_Block" > $null 2>&1; Write-Host "Ubisoft restored!" -ForegroundColor Green; Read-Host "Press Enter..." }
        "3" { netsh advfirewall firewall delete rule name="Offline_Epic_Block" > $null 2>&1; Write-Host "Epic restored!" -ForegroundColor Green; Read-Host "Press Enter..." }
        "4" { netsh advfirewall firewall delete rule name="Offline_Rockstar_Block" > $null 2>&1; Write-Host "Rockstar restored!" -ForegroundColor Green; Read-Host "Press Enter..." }
        "5" { netsh advfirewall firewall delete rule name="Offline_Custom_Block" > $null 2>&1; Write-Host "Custom rules cleared!" -ForegroundColor Green; Read-Host "Press Enter..." }
        "6" {
            Write-Host "`nRemoving all created firewall blocks..." -ForegroundColor Yellow
            netsh advfirewall firewall delete rule name="Offline_Steam_Block" > $null 2>&1
            netsh advfirewall firewall delete rule name="Offline_Ubi_Block" > $null 2>&1
            netsh advfirewall firewall delete rule name="Offline_Epic_Block" > $null 2>&1
            netsh advfirewall firewall delete rule name="Offline_Rockstar_Block" > $null 2>&1
            netsh advfirewall firewall delete rule name="Offline_Custom_Block" > $null 2>&1
            netsh advfirewall firewall delete rule name="Offline_Biz_Block" > $null 2>&1
            Write-Host "[SUCCESS] All clients and custom rules unblocked. Internet access completely restored!" -ForegroundColor Green
            Read-Host "Press Enter..."
        }
        "7" { return }
    }
}

# ===================================================
# MAIN EXECUTION LOOP
# ===================================================
do {
    Show-MainMenu
    $choice = Read-Host "Select an option (1-8)"

    switch ($choice) {
        "1" { Block-Steam }
        "2" { Block-Ubi }
        "3" { Block-Epic }
        "4" { Block-Rockstar }
        "5" { Show-EaAdapterMenu }
        "6" { Block-Custom }
        "7" { Show-ClearMenu }
        "8" { return }
    }
} while ($true)