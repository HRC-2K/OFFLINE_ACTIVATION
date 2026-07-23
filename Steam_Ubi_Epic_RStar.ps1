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
    Write-Host "        ULTIMATE FIREWALL ACTIVATION MANAGER" -ForegroundColor Yellow
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " [1] Block Steam"
    Write-Host " [2] Block Ubisoft"
    Write-Host " [3] Block Epic Games"
    Write-Host " [4] Block Rockstar Launcher"
    Write-Host " [5] Block Custom Game Directory (Manual Folder Prompt)"
    Write-Host " [6] Clear Firewall Rules (Unblock Options)"
    Write-Host " [7] Return"
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
# BLOCKING LOGIC
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
    Write-Host "          CUSTOM GAME DIRECTORY BLOCKER (FAB MODE)" -ForegroundColor Yellow
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
# UNBLOCKING LOGIC
# ===================================================

function Show-ClearMenu {
    Clear-Host
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "               UNBLOCK / CLEAR MENU" -ForegroundColor Yellow
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] Unblock Steam          [4] Unblock Rockstar"
    Write-Host "  [2] Unblock Ubisoft        [5] Unblock Custom Folder Rules"
    Write-Host "  [3] Unblock Epic Games     [6] UNBLOCK ALL CLIENTS"
    Write-Host "  [7] Back to Main Menu"
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
    $choice = Read-Host "Select an option (1-7)"

    switch ($choice) {
        "1" { Block-Steam }
        "2" { Block-Ubi }
        "3" { Block-Epic }
        "4" { Block-Rockstar }
        "5" { Block-Custom }
        "6" { Show-ClearMenu }
        "7" { return }
    }
} while ($true)