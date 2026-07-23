# ===================================================
# AUTOMATIC ADMINISTRATOR ELEVATION (UAC PROMPT)
# ===================================================
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)

if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Requesting Administrator privileges..." -ForegroundColor Yellow[cite: 5]
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

# Explicit drive order: Checks C: first, then covers everything else alphabetically
$DRIVES = @("C", "A", "B", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z")[cite: 5]

function Show-MainMenu {
    Clear-Host
    Write-Host "===================================================" -ForegroundColor Cyan[cite: 5]
    Write-Host "        ULTIMATE FIREWALL ACTIVATION MANAGER" -ForegroundColor Yellow[cite: 5]
    Write-Host "===================================================" -ForegroundColor Cyan[cite: 5]
    Write-Host ""
    Write-Host " [1] Block Steam"[cite: 5]
    Write-Host " [2] Block Ubisoft"[cite: 5]
    Write-Host " [3] Block Epic Games"[cite: 5]
    Write-Host " [4] Block Rockstar Launcher"[cite: 5]
    Write-Host " [5] Block Custom Game Directory (Manual Folder Prompt)"[cite: 5]
    Write-Host " [6] Clear Firewall Rules (Unblock Options)"[cite: 5]
    Write-Host " [7] Exit"[cite: 5]
    Write-Host ""
    Write-Host "===================================================" -ForegroundColor Cyan[cite: 5]
}

# Helper Function: Recursively adds inbound & outbound firewall rules for exes in a folder
function Add-FirewallRulesForPath ($folderPath, $ruleName) {
    if (Test-Path $folderPath) {
        $exeFiles = Get-ChildItem -Path $folderPath -Filter "*.exe" -Recurse -ErrorAction SilentlyContinue
        foreach ($exe in $exeFiles) {
            netsh advfirewall firewall add rule name=$ruleName dir=out action=block program="$($exe.FullName)" enable=yes > $null 2>&1[cite: 5]
            netsh advfirewall firewall add rule name=$ruleName dir=in action=block program="$($exe.FullName)" enable=yes > $null 2>&1[cite: 5]
        }
    }
}

# ===================================================
# BLOCKING LOGIC
# ===================================================

function Block-Steam {
    Clear-Host
    Write-Host "Scanning drives for Steam (Checking C: first)..." -ForegroundColor Yellow[cite: 5]
    $steamPath = $null
    $steamCommon = $null
    $steamBin = $null

    foreach ($d in $DRIVES) {
        if (-not $steamPath -and (Test-Path "$d`:\Program Files (x86)\Steam")) {[cite: 5]
            $steamPath = "$d`:\Program Files (x86)\Steam"[cite: 5]
            $steamBin = "$d`:\Program Files (x86)\Steam\bin"[cite: 5]
        }
        if (-not $steamCommon -and (Test-Path "$d`:\Program Files (x86)\Common Files\Steam")) {[cite: 5]
            $steamCommon = "$d`:\Program Files (x86)\Common Files\Steam"[cite: 5]
        }
    }

    if (-not $steamPath) {
        Write-Host "[WARNING] Steam launcher files could not be found automatically." -ForegroundColor Red[cite: 5]
        $steamPath = Read-Host "Enter the correct Steam folder path (e.g., J:\Steam)"[cite: 5]
        $steamBin = Join-Path $steamPath "bin"[cite: 5]
    }
    if (-not $steamCommon) { $steamCommon = "C:\Program Files (x86)\Common Files\Steam" }[cite: 5]

    Write-Host "`nProcessing Steam folders... Please wait." -ForegroundColor Cyan[cite: 5]
    Add-FirewallRulesForPath $steamPath "Offline_Steam_Block"
    Add-FirewallRulesForPath $steamBin "Offline_Steam_Block"
    Add-FirewallRulesForPath $steamCommon "Offline_Steam_Block"

    Write-Host "[SUCCESS] Steam inbound and outbound rules successfully applied!" -ForegroundColor Green[cite: 5]
    Read-Host "Press Enter to return to main menu..."
}

function Block-Ubi {
    Clear-Host
    Write-Host "Scanning drives for Ubisoft (Checking C: first)..." -ForegroundColor Yellow[cite: 5]
    $ubiPath = $null

    foreach ($d in $DRIVES) {
        if (-not $ubiPath -and (Test-Path "$d`:\Program Files (x86)\Ubisoft")) {[cite: 5]
            $ubiPath = "$d`:\Program Files (x86)\Ubisoft"[cite: 5]
        }
    }

    if (-not $ubiPath) {
        Write-Host "[WARNING] Ubisoft launcher files could not be found automatically." -ForegroundColor Red[cite: 5]
        $ubiPath = Read-Host "Enter the correct Ubisoft folder path"[cite: 5]
    }

    Write-Host "`nProcessing Ubisoft folders... Please wait." -ForegroundColor Cyan[cite: 5]
    Add-FirewallRulesForPath $ubiPath "Offline_Ubi_Block"

    Write-Host "[SUCCESS] Ubisoft inbound and outbound rules successfully applied!" -ForegroundColor Green[cite: 5]
    Read-Host "Press Enter to return to main menu..."
}

function Block-Epic {
    Clear-Host
    Write-Host "Scanning drives for Epic Games Launcher..." -ForegroundColor Yellow[cite: 5]
    $epicPath = $null

    foreach ($d in $DRIVES) {
        if (-not $epicPath -and (Test-Path "$d`:\Program Files (x86)\Epic Games")) {[cite: 5]
            $epicPath = "$d`:\Program Files (x86)\Epic Games"[cite: 5]
        }
    }

    if (-not $epicPath) {
        Write-Host "[WARNING] Epic Games Launcher could not be found automatically." -ForegroundColor Red[cite: 5]
        $epicPath = Read-Host "Enter the correct Epic Games Launcher folder path"[cite: 5]
    }

    Write-Host "`nProcessing Epic Games Launcher folders... Please wait." -ForegroundColor Cyan[cite: 5]
    Add-FirewallRulesForPath $epicPath "Offline_Epic_Block"

    $localEpic = "$env:LOCALAPPDATA\EpicGamesLauncher"[cite: 5]
    if (Test-Path $localEpic) {
        Write-Host "Processing WebHelper files..." -ForegroundColor Yellow[cite: 5]
        Add-FirewallRulesForPath $localEpic "Offline_Epic_Block"
    }

    $epicGameDir = "C:\Program Files\Epic Games"[cite: 5]
    if (Test-Path $epicGameDir) {
        Write-Host "Found default Epic Games directory at C:\Program Files\Epic Games" -ForegroundColor Green[cite: 5]
    } else {
        do {
            Write-Host "`n[NOTICE] Default Epic Games directory not found on C:\" -ForegroundColor Yellow[cite: 5]
            $epicGameDir = Read-Host "Please enter or paste your custom Game download folder path (e.g. J:\Games\EpicGames)"[cite: 5]
            $valid = Test-Path $epicGameDir
            if (-not $valid) { Write-Host "[ERROR] The path you typed does not exist." -ForegroundColor Red }[cite: 5]
        } while (-not $valid)
    }

    Write-Host "`nProcessing Game Files directory inside: $epicGameDir... Please wait." -ForegroundColor Cyan[cite: 5]
    Add-FirewallRulesForPath $epicGameDir "Offline_Epic_Block"

    Write-Host "[SUCCESS] Epic Games Launcher and game directories successfully isolated!" -ForegroundColor Green[cite: 5]
    Read-Host "Press Enter to return to main menu..."
}

function Block-Rockstar {
    Clear-Host
    Write-Host "Scanning drives for Rockstar Launcher..." -ForegroundColor Yellow[cite: 5]
    $rockstarMain = $null
    $rockstarSC64 = $null
    $rockstarSC32 = $null

    foreach ($d in $DRIVES) {
        if (-not $rockstarMain -and (Test-Path "$d`:\Program Files\Rockstar Games\Launcher")) {[cite: 5]
            $rockstarMain = "$d`:\Program Files\Rockstar Games\Launcher"[cite: 5]
        }
        if (-not $rockstarSC64 -and (Test-Path "$d`:\Program Files\Rockstar Games\Social Club")) {[cite: 5]
            $rockstarSC64 = "$d`:\Program Files\Rockstar Games\Social Club"[cite: 5]
        }
        if (-not $rockstarSC32 -and (Test-Path "$d`:\Program Files (x86)\Rockstar Games\Social Club")) {[cite: 5]
            $rockstarSC32 = "$d`:\Program Files (x86)\Rockstar Games\Social Club"[cite: 5]
        }
    }

    if (-not $rockstarMain) {
        Write-Host "[WARNING] Rockstar Launcher could not be found automatically." -ForegroundColor Red[cite: 5]
        $rockstarMain = Read-Host "Enter your main Rockstar Games\Launcher folder path"[cite: 5]
    }

    Write-Host "`nProcessing Rockstar folders... Please wait." -ForegroundColor Cyan[cite: 5]
    Add-FirewallRulesForPath $rockstarMain "Offline_Rockstar_Block"
    Add-FirewallRulesForPath $rockstarSC64 "Offline_Rockstar_Block"
    Add-FirewallRulesForPath $rockstarSC32 "Offline_Rockstar_Block"
    Add-FirewallRulesForPath "$env:LOCALAPPDATA\Rockstar Games" "Offline_Rockstar_Block"[cite: 5]

    Write-Host "[SUCCESS] Rockstar folders successfully isolated!" -ForegroundColor Green[cite: 5]
    Read-Host "Press Enter to return to main menu..."
}

function Block-Custom {
    Clear-Host
    Write-Host "===================================================" -ForegroundColor Cyan[cite: 5]
    Write-Host "          CUSTOM GAME DIRECTORY BLOCKER (FAB MODE)" -ForegroundColor Yellow[cite: 5]
    Write-Host "===================================================" -ForegroundColor Cyan[cite: 5]
    Write-Host ""

    do {
        $customDir = Read-Host "Enter or paste the exact Game folder path (e.g., J:\Games\GTA V)"[cite: 5]
        $valid = Test-Path $customDir
        if (-not $valid) {
            Write-Host "`n[ERROR] The folder path you typed does not exist. Please try again.`n" -ForegroundColor Red[cite: 5]
        }
    } while (-not $valid)

    Write-Host "`nProcessing Custom Directory... Please wait." -ForegroundColor Cyan[cite: 5]
    Add-FirewallRulesForPath $customDir "Offline_Custom_Block"

    Write-Host "`n[SUCCESS] All executables inside `"$customDir`" successfully blocked!" -ForegroundColor Green[cite: 5]
    Read-Host "Press Enter to return to main menu..."
}

# ===================================================
# UNBLOCKING LOGIC
# ===================================================

function Show-ClearMenu {
    Clear-Host
    Write-Host "===================================================" -ForegroundColor Cyan[cite: 5]
    Write-Host "               UNBLOCK / CLEAR MENU" -ForegroundColor Yellow[cite: 5]
    Write-Host "===================================================" -ForegroundColor Cyan[cite: 5]
    Write-Host ""
    Write-Host "  [1] Unblock Steam          [4] Unblock Rockstar"[cite: 5]
    Write-Host "  [2] Unblock Ubisoft        [5] Unblock Custom Folder Rules"[cite: 5]
    Write-Host "  [3] Unblock Epic Games     [6] UNBLOCK ALL CLIENTS"[cite: 5]
    Write-Host "  [7] Back to Main Menu"[cite: 5]
    Write-Host ""
    Write-Host "===================================================" -ForegroundColor Cyan[cite: 5]
    $clearChoice = Read-Host "Select an option (1-7)"[cite: 5]

    switch ($clearChoice) {
        "1" { netsh advfirewall firewall delete rule name="Offline_Steam_Block" > $null 2>&1; Write-Host "Steam restored!" -ForegroundColor Green; Read-Host "Press Enter..." }[cite: 5]
        "2" { netsh advfirewall firewall delete rule name="Offline_Ubi_Block" > $null 2>&1; Write-Host "Ubisoft restored!" -ForegroundColor Green; Read-Host "Press Enter..." }[cite: 5]
        "3" { netsh advfirewall firewall delete rule name="Offline_Epic_Block" > $null 2>&1; Write-Host "Epic restored!" -ForegroundColor Green; Read-Host "Press Enter..." }[cite: 5]
        "4" { netsh advfirewall firewall delete rule name="Offline_Rockstar_Block" > $null 2>&1; Write-Host "Rockstar restored!" -ForegroundColor Green; Read-Host "Press Enter..." }[cite: 5]
        "5" { netsh advfirewall firewall delete rule name="Offline_Custom_Block" > $null 2>&1; Write-Host "Custom rules cleared!" -ForegroundColor Green; Read-Host "Press Enter..." }[cite: 5]
        "6" {
            Write-Host "`nRemoving all created firewall blocks..." -ForegroundColor Yellow[cite: 5]
            netsh advfirewall firewall delete rule name="Offline_Steam_Block" > $null 2>&1[cite: 5]
            netsh advfirewall firewall delete rule name="Offline_Ubi_Block" > $null 2>&1[cite: 5]
            netsh advfirewall firewall delete rule name="Offline_Epic_Block" > $null 2>&1[cite: 5]
            netsh advfirewall firewall delete rule name="Offline_Rockstar_Block" > $null 2>&1[cite: 5]
            netsh advfirewall firewall delete rule name="Offline_Custom_Block" > $null 2>&1[cite: 5]
            netsh advfirewall firewall delete rule name="Offline_Biz_Block" > $null 2>&1[cite: 5]
            Write-Host "[SUCCESS] All clients and custom rules unblocked. Internet access completely restored!" -ForegroundColor Green[cite: 5]
            Read-Host "Press Enter..."
        }
        "7" { return }[cite: 5]
    }
}

# ===================================================
# MAIN EXECUTION LOOP
# ===================================================
do {
    Show-MainMenu
    $choice = Read-Host "Select an option (1-7)"[cite: 5]

    switch ($choice) {
        "1" { Block-Steam }[cite: 5]
        "2" { Block-Ubi }[cite: 5]
        "3" { Block-Epic }[cite: 5]
        "4" { Block-Rockstar }[cite: 5]
        "5" { Block-Custom }[cite: 5]
        "6" { Show-ClearMenu }[cite: 5]
        "7" { exit }[cite: 5]
    }
} while ($true)