# ===================================================
# AUTOMATIC ADMINISTRATOR ELEVATION (UAC PROMPT)
# ===================================================
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)

if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Requesting Administrative Privileges..." -ForegroundColor Yellow
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

function Show-MainMenu {
    Clear-Host
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "             EA APP AUTOMATED OFFLINE TOOL" -ForegroundColor Yellow
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "  1. Launch EA + Game in Strict Offline Loop"
    Write-Host "  2. Clear / Reset (Force Kill Running Instances)"
    Write-Host "  3. Return"
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host ""
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
        Read-Host "Press Enter to return to main menu..."
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
        Read-Host "Press Enter to return to main menu..."
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
    Write-Host "3. RETURN TO THIS WINDOW ONLY AFTER YOU HAVE COMPLETELY EXITED THE GAME.`n"
    Read-Host "Press Enter AFTER YOU HAVE COMPLETELY EXITED THE GAME..."

    Write-Host "`n6. Game running! Restoring PC internet access (Adapters ON)..." -ForegroundColor Green
    Enable-NetAdapter -Name "Wi-Fi", "Ethernet" -Confirm:$false -ErrorAction SilentlyContinue

    Write-Host "`n===================================================" -ForegroundColor Cyan
    Write-Host "      MONITORING GAMEPLAY - DO NOT CLOSE WINDOW" -ForegroundColor Yellow
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "Tracking $global:GAME_EXE..."
    Write-Host "The moment you close the game, EA will be wiped instantly`n"

    # Monitor Loop
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
    Read-Host "Press Enter to return to main menu..."
}

# ===================================================
# MAIN EXECUTION LOOP
# ===================================================
do {
    Show-MainMenu
    $choice = Read-Host "Choose an option (1-3)"

    switch ($choice) {
        "1" { Invoke-EaLaunchOffline }
        "2" { Invoke-EaForceCleanup }
        "3" { return }
    }
} while ($true)