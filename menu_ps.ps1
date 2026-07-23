# ==============================================================================
# 1. AUTO-ELEVATE TO ADMINISTRATOR
# ==============================================================================
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)

if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[!] Administrator rights required. Requesting elevation..." -ForegroundColor Yellow
    
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

# Ensure ANSI escape sequences are supported in Windows Console
$Host.UI.RawUI.ForegroundColor = "Gray"

# ==============================================================================
# 2. CONFIGURATION & STYLES
# ==============================================================================
$InstallDir = "$env:USERPROFILE\Desktop\App_Installers"
if (-not (Test-Path $InstallDir)) {
    New-Item -Path $InstallDir -ItemType Directory | Out-Null
}

# Modern UI Formatting Helpers
function Format-TitleBar {
    param([string]$Text)
    $Width = 76
    $Pad = [math]::Max(0, [math]::Floor(($Width - $Text.Length) / 2))
    $Line = "─" * $Width
    Write-Host "┌$Line┐" -ForegroundColor DarkGray
    Write-Host ("│" + (" " * $Pad) + $Text + (" " * ($Width - $Pad - $Text.Length)) + "│") -ForegroundColor Cyan
    Write-Host "└$Line┘" -ForegroundColor DarkGray
}

function Format-SectionHeader {
    param([string]$Text)
    Write-Host "`n ─── $Text " -ForegroundColor DarkCyan -NoNewline
    $Remaining = 73 - $Text.Length
    if ($Remaining -gt 0) { Write-Host ("─" * $Remaining) -ForegroundColor DarkGray } else { Write-Host "" }
}

function Write-Status {
    param([string]$Type, [string]$Message)
    switch ($Type) {
        "INFO"  { Write-Host " [i] " -ForegroundColor Cyan -NoNewline; Write-Host $Message }
        "OK"    { Write-Host " [✓] " -ForegroundColor Green -NoNewline; Write-Host $Message -ForegroundColor Green }
        "WARN"  { Write-Host " [!] " -ForegroundColor Yellow -NoNewline; Write-Host $Message -ForegroundColor Yellow }
        "ERR"   { Write-Host " [X] " -ForegroundColor Red -NoNewline; Write-Host $Message -ForegroundColor Red }
        "WORK"  { Write-Host " [>] " -ForegroundColor Magenta -NoNewline; Write-Host $Message }
    }
}

# ==============================================================================
# 3. INTERFACE
# ==============================================================================
function Show-Menu {
    Clear-Host
    
    # Header Banner
    Write-Host @"
   ██╗  ██╗██████╗  ██████╗    ██╗   ██╗████████╗██╗██╗     ██╗████████╗██╗   ██╗
   ██║  ██║██╔══██╗██╔════╝    ██║   ██║╚══██╔══╝██║██║     ██║╚══██╔══╝╚██╗ ██╔╝
   ███████║██████╔╝██║         ██║   ██║   ██║   ██║██║     ██║   ██║    ╚████╔╝ 
   ██╔══██║██╔══██╗██║         ██║   ██║   ██║   ██║██║     ██║   ██║     ╚██╔╝  
   ██║  ██║██║  ██║╚██████╗    ╚██████╔╝   ██║   ██║███████╗██║   ██║      ██║   
   ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝     ╚═════╝    ╚═╝   ╚═╝╚══════╝╚═╝   ╚═╝      ╚═╝   
"@ -ForegroundColor DarkCyan

    Format-TitleBar "SYSTEM & SOFTWARE DEPLOYMENT TOOLKIT"

    Format-SectionHeader "SYSTEM & UTILITIES"
    Write-Host "  [0] " -ForegroundColor Cyan -NoNewline; Write-Host "Chris Titus Tech Windows Utility"
    Write-Host "  [1] " -ForegroundColor White -NoNewline; Write-Host "UltraViewer" -NoNewline
    Write-Host "`t`t`t  [2] " -ForegroundColor White -NoNewline; Write-Host "Cloudflare 1.1.1.1 WARP"
    Write-Host "  [3] " -ForegroundColor White -NoNewline; Write-Host "Firewall App Blocker" -NoNewline
    Write-Host "`t`t  [4] " -ForegroundColor White -NoNewline; Write-Host "Voidtools Everything (Search Engine)" -ForegroundColor Yellow
    Write-Host "  [5] " -ForegroundColor White -NoNewline; Write-Host "Bulk Crap Uninstaller"

    Format-SectionHeader "GAMING CLIENTS"
    Write-Host "  [6] " -ForegroundColor White -NoNewline; Write-Host "Steam" -NoNewline
    Write-Host "`t`t`t`t  [7] " -ForegroundColor White -NoNewline; Write-Host "Ubisoft Connect"
    Write-Host "  [8] " -ForegroundColor White -NoNewline; Write-Host "Epic Games Launcher" -NoNewline
    Write-Host "`t`t  [9] " -ForegroundColor White -NoNewline; Write-Host "Rockstar Games Launcher"
    Write-Host "  [10]" -ForegroundColor White -NoNewline; Write-Host "EA App" -NoNewline
    Write-Host "`t`t`t`t  [11]" -ForegroundColor White -NoNewline; Write-Host "TcNo Account Switcher"

    Format-SectionHeader "AUTOMATION & ACTIVATION SCRIPTS"
    Write-Host "  [12]" -ForegroundColor Green -NoNewline; Write-Host "Run All-in-1 Script" -NoNewline
    Write-Host "`t`t`t  [13]" -ForegroundColor Green -NoNewline; Write-Host "Run EA Adapter Offline Script"
    Write-Host "  [14]" -ForegroundColor Green -NoNewline; Write-Host "Run Steam/Ubi/Epic/Rockstar Script" -NoNewline
    Write-Host "`t  [15]" -ForegroundColor Green -NoNewline; Write-Host "Run Sub-scripts via Batch"

    Format-SectionHeader "ACTIONS"
    Write-Host "  [A] " -ForegroundColor Yellow -NoNewline; Write-Host "Upgrade / Install ALL Items"
    Write-Host "  [X] " -ForegroundColor Red -NoNewline; Write-Host "Exit Toolkit"

    Write-Host "`n" + ("─" * 78) -ForegroundColor DarkGray
    Write-Host " Output Directory: " -NoNewline; Write-Host "$InstallDir" -ForegroundColor DarkGray
    Write-Host ("─" * 78) -ForegroundColor DarkGray
}

# ==============================================================================
# 4. LOGIC ENGINE
# ==============================================================================
function Process-App ($url, $fileName, $arguments, $processName) {
    $filePath = Join-Path $InstallDir $fileName
    Write-Status "WORK" "Processing target: $fileName"

    if ($processName -ne "none") {
        $procBare = [System.IO.Path]::GetFileNameWithoutExtension($processName)
        $running = Get-Process -Name $procBare -ErrorAction SilentlyContinue
        if ($running) {
            Write-Status "WARN" "Active process detected ($processName). Terminating for safe install..."
            Stop-Process -Name $procBare -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
        }
    }

    try {
        Write-Status "INFO" "Downloading payload from source..."
        Invoke-WebRequest -Uri $url -UserAgent "Mozilla/5.0" -OutFile $filePath -ErrorAction Stop
    } catch {
        Write-Status "ERR" "Download failure on $fileName - $_"
        return
    }

    Write-Status "INFO" "Executing installation routine..."
    try {
        if ($arguments -eq "ZIP") {
            Expand-Archive -Path $filePath -DestinationPath "$InstallDir\FirewallAppBlocker" -Force
            Remove-Item -Path $filePath -Force -ErrorAction SilentlyContinue
        }
        elseif ($fileName.EndsWith(".msi")) {
            Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$filePath`" $arguments" -Wait
            Remove-Item -Path $filePath -Force -ErrorAction SilentlyContinue
        }
        else {
            Start-Process -FilePath $filePath -ArgumentList $arguments -Wait
            Remove-Item -Path $filePath -Force -ErrorAction SilentlyContinue
        }
        Write-Status "OK" "Successfully completed processing $fileName"
    } catch {
        Write-Status "ERR" "Installation failure: $_"
    }
}

function Install-App ($choice) {
    switch ($choice) {
        "0"  { 
            Write-Status "WORK" "Launching Chris Titus Tech Windows Utility..."
            irm https://christitus.com/win | iex
        }
        "1"  { Process-App "https://www.ultraviewer.net/en/UltraViewer_setup_6.6_en.exe" "UltraViewer_setup_6.6_en.exe" "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART" "UltraViewer.exe" }
        "2"  { Process-App "https://downloads.cloudflareclient.com/v1/download/windows/ga" "Cloudflare_1.1.1.1_Setup.msi" "/quiet /norestart ONBOARDING=false" "CloudflareWARP.exe" }
        "3"  { Process-App "https://www.sordum.org/files/downloads.php?firewall-app-blocker" "FirewallAppBlocker.zip" "ZIP" "Fab.exe" }
        "4"  { Process-App "https://www.voidtools.com/Everything-1.4.1.1026.x64-Setup.exe" "Everything_Setup.exe" "/S" "Everything.exe" }
        "5"  { Process-App "https://github.com/BCUninstaller/Bulk-Crap-Uninstaller/releases/download/v6.2/BCUninstaller_6.2.0_setup.exe" "BCUninstaller_6.2.0_setup.exe" "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART" "BCUninstaller.exe" }
        "6"  { Process-App "https://cdn.akamai.steamstatic.com/client/installer/SteamSetup.exe" "SteamSetup.exe" "/S" "steam.exe" }
        "7"  { Process-App "https://ubi.li/4vxt9" "UbisoftConnectInstaller.exe" "/S" "upc.exe" }
        "8"  { Process-App "https://launcher-public-service-prod06.ol.epicgames.com/launcher/api/installer/download/EpicGamesLauncherInstaller.exe" "EpicGamesLauncherInstaller.exe" "/qn /norestart" "EpicGamesLauncher.exe" }
        "9"  { Process-App "https://gamedownloads.rockstargames.com/public/installer/Rockstar-Games-Launcher.exe" "Rockstar-Games-Launcher.exe" "/s /v`"/qn`"" "Launcher.exe" }
        "10" { Process-App "https://origin-a.akamaihd.net/EA-Desktop-Client-Download/installer-releases/EAappInstaller.exe" "EAappInstaller.exe" "/q" "EADesktop.exe" }
        "11" { Process-App "https://github.com/TCNOco/TcNo-Acc-Switcher/releases/download/2025-11-20_03/TcNo.Account.Switcher.-.Installer_2025-11-20_03.exe" "TcNo.Account.Switcher.exe" "/S" "TcNo Account Switcher.exe" }
        "12" { 
            Write-Status "WORK" "Running All-in-1 Script..."
            irm "https://raw.githubusercontent.com/HRC-2K/OFFLINE_ACTIVATION/main/ALL_in_1.ps1" | iex 
        }
        "13" { 
            Write-Status "WORK" "Running EA Adapter Offline Script..."
            irm "https://raw.githubusercontent.com/HRC-2K/OFFLINE_ACTIVATION/main/EA_Adapter_Offline_Method.ps1" | iex 
        }
        "14" { 
            Write-Status "WORK" "Running Steam/Ubi/Epic/Rockstar Script..."
            irm "https://raw.githubusercontent.com/HRC-2K/OFFLINE_ACTIVATION/main/Steam_Ubi_Epic_RStar.ps1" | iex 
        }
        "15" { 
            Write-Status "WORK" "Running sub-scripts via Batch..."
            irm "https://raw.githubusercontent.com/HRC-2K/OFFLINE_ACTIVATION/main/menu_bat.ps1" | iex 
        }
        "A"  { 
            Write-Status "WARN" "Executing Full Automated Deployment Routine..."
            1..15 | ForEach-Object { Install-App "$_" }
        }
        "X"  { exit }
        default { Write-Status "ERR" "Invalid selection choice: $choice" }
    }
}

# ==============================================================================
# 5. MAIN EXECUTION LOOP
# ==============================================================================
do {
    Show-Menu
    Write-Host "`n Select options (e.g., '1 4 10') or menu choice: " -NoNewline -ForegroundColor Yellow
    $selection = Read-Host
    
    $choices = $selection -split '\s+'
    foreach ($choice in $choices) {
        if ($choice -ne "") {
            Install-App $choice.ToUpper()
        }
    }
    
    if ($selection.ToUpper() -ne "X") {
        Write-Host "`n Routine complete. Press any key to return to menu..." -ForegroundColor DarkGray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
} while ($selection.ToUpper() -ne "X")