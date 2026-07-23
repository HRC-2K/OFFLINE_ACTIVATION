# ==============================================================================
# 1. AUTO-ELEVATE TO ADMINISTRATOR
# ==============================================================================
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)

if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[!] Administrator rights required. Requesting elevation..." -ForegroundColor Yellow
    
    $scriptPath = $MyInvocation.MyCommand.Path
    
    if ($scriptPath) {
        # Saved script file: Relaunch with elevated privileges
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
    } else {
        # Remote/Inline execution: Pass the script content directly to an elevated process
        $scriptContent = $MyInvocation.MyCommand.ScriptBlock.ToString()
        $bytes = [System.Text.Encoding]::Unicode.GetBytes($scriptContent)
        $encodedCommand = [Convert]::ToBase64String($bytes)
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -EncodedCommand $encodedCommand" -Verb RunAs
    }
    exit
}

# ==============================================================================
# 2. MAIN SCRIPT
# ==============================================================================
$InstallDir = "$env:USERPROFILE\Desktop\App_Installers"
if (-not (Test-Path $InstallDir)) {
    New-Item -Path $InstallDir -ItemType Directory | Out-Null
}

function Show-Menu {
    Clear-Host
    Write-Host "=========================================================================" -ForegroundColor Cyan
    Write-Host "                FULLY SILENT SMART UPGRADE / INSTALLATION MENU          " -ForegroundColor Yellow
    Write-Host "=========================================================================" -ForegroundColor Cyan
    Write-Host " [0]  Chris Titus Tech Windows Utility" -ForegroundColor Cyan
	Write-Host " [1]  UltraViewer"
    Write-Host " [2]  Cloudflare 1.1.1.1 WARP"
    Write-Host " [3]  Firewall App Blocker (Extracts Only)"
    Write-Host " [4]  Steam"
    Write-Host " [5]  Ubisoft Connect"
    Write-Host " [6]  Epic Games"
    Write-Host " [7]  Rockstar Games (Manual Install)"
    Write-Host " [8]  EA App"
    Write-Host " [9]  TcNo Account Switcher"
    Write-Host " [10] Bulk Crap Uninstaller"
    Write-Host "------------------------------------------------------------------------- " -ForegroundColor DarkGray
    Write-Host " [11] Run All-in-1 Script" -ForegroundColor Green
    Write-Host " [12] Run EA Adapter Offline Script" -ForegroundColor Green
    Write-Host " [13] Run Steam/Ubi/Epic/Rockstar Script" -ForegroundColor Green
    Write-Host " [14] Update Silent Install Master Script" -ForegroundColor Green
    Write-Host "------------------------------------------------------------------------- " -ForegroundColor DarkGray
    Write-Host " [A]  Upgrade / Install ALL Items" -ForegroundColor Yellow
    Write-Host " [X]  Exit" -ForegroundColor Red
    Write-Host "=========================================================================" -ForegroundColor Cyan
    Write-Host " Files will be saved to: $InstallDir" -ForegroundColor Gray
    Write-Host "=========================================================================" -ForegroundColor Cyan
}

function Process-App ($url, $fileName, $arguments, $processName) {
    $filePath = Join-Path $InstallDir $fileName
    Write-Host "`n[PROCESSING]: $fileName" -ForegroundColor Cyan

    if ($processName -ne "none") {
        $running = Get-Process -Name ([System.IO.Path]::GetFileNameWithoutExtension($processName)) -ErrorAction SilentlyContinue
        if ($running) {
            Write-Host "[INFO]: Terminating running process $processName..." -ForegroundColor Yellow
            Stop-Process -Name ([System.IO.Path]::GetFileNameWithoutExtension($processName)) -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
        }
    }

    try {
        Invoke-WebRequest -Uri $url -UserAgent "Mozilla/5.0" -OutFile $filePath -ErrorAction Stop
    } catch {
        Write-Host "[ERROR]: Download failed for $fileName - $_" -ForegroundColor Red
        return
    }

    Write-Host "Download finished. Installing..." -ForegroundColor Green
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
    Write-Host "[STATUS]: SUCCESS - $fileName completed." -ForegroundColor Green
}

function Invoke-SubScript ($url, $fileName) {
    Write-Host "`n[+] Fetching and executing sub-script: $fileName..." -ForegroundColor Cyan
    try {
        $tempPath = Join-Path $InstallDir $fileName
        Invoke-WebRequest -Uri $url -UserAgent "Mozilla/5.0" -OutFile $tempPath -ErrorAction Stop
        Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$tempPath`"" -Wait -NoNewWindow
    } catch {
        Write-Error "Failed to execute remote script: $_"
    }
}

function Install-App ($choice) {
    switch ($choice) {
		"0"  { 
            Write-Host "`n[+] Launching Chris Titus Tech Windows Utility..." -ForegroundColor Cyan
            irm https://christitus.com/win | iex
        }
        "1"  { Process-App "https://www.ultraviewer.net/en/UltraViewer_setup_6.6_en.exe" "UltraViewer_setup_6.6_en.exe" "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART" "UltraViewer.exe" }
        "2"  { Process-App "https://downloads.cloudflareclient.com/v1/download/windows/ga" "Cloudflare_1.1.1.1_Setup.msi" "/quiet /norestart ONBOARDING=false" "CloudflareWARP.exe" }
        "3"  { Process-App "https://www.sordum.org/files/downloads.php?firewall-app-blocker" "FirewallAppBlocker.zip" "ZIP" "Fab.exe" }
        "4"  { Process-App "https://cdn.akamai.steamstatic.com/client/installer/SteamSetup.exe" "SteamSetup.exe" "/S" "steam.exe" }
        "5"  { Process-App "https://ubi.li/4vxt9" "UbisoftConnectInstaller.exe" "/S" "upc.exe" }
        "6"  { Process-App "https://launcher-public-service-prod06.ol.epicgames.com/launcher/api/installer/download/EpicGamesLauncherInstaller.exe" "EpicGamesLauncherInstaller.exe" "/qn /norestart" "EpicGamesLauncher.exe" }
        "7"  { Process-App "https://gamedownloads.rockstargames.com/public/installer/Rockstar-Games-Launcher.exe" "Rockstar-Games-Launcher.exe" "/s /v`"/qn`"" "Launcher.exe" }
        "8"  { Process-App "https://origin-a.akamaihd.net/EA-Desktop-Client-Download/installer-releases/EAappInstaller.exe" "EAappInstaller.exe" "/q" "EADesktop.exe" }
        "9"  { Process-App "https://github.com/TCNOco/TcNo-Acc-Switcher/releases/download/2025-11-20_03/TcNo.Account.Switcher.-.Installer_2025-11-20_03.exe" "TcNo.Account.Switcher.exe" "/S" "TcNo Account Switcher.exe" }
        "10" { Process-App "https://github.com/BCUninstaller/Bulk-Crap-Uninstaller/releases/download/v6.2/BCUninstaller_6.2.0_setup.exe" "BCUninstaller_6.2.0_setup.exe" "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART" "BCUninstaller.exe" }
        "11" { Invoke-SubScript "https://github.com/HRC-2K/OFFLINE_ACTIVATION/releases/download/OA/ALL_in_1.bat" "ALL_in_1.bat" }
        "12" { Invoke-SubScript "https://github.com/HRC-2K/OFFLINE_ACTIVATION/releases/download/OA/EA_Adapter_Offline_Method.bat" "EA_Adapter.bat" }
        "13" { Invoke-SubScript "https://github.com/HRC-2K/OFFLINE_ACTIVATION/releases/download/OA/Steam_Ubi_Epic_RStar.bat" "Launcher.bat" }
        "14" { Invoke-SubScript "https://github.com/HRC-2K/OFFLINE_ACTIVATION/releases/download/OA/Silent.Install_Upgrade.bat" "Silent_Install.bat" }
        "A"  { 
            Write-Host "`n[+] Installing ALL items sequentially..." -ForegroundColor Yellow
            1..14 | ForEach-Object { Install-App "$_" }
        }
        "X"  { exit }
        default { Write-Host "`n[!] Invalid Selection: $choice" -ForegroundColor Red }
    }
}

# Main Execution Loop
do {
    Show-Menu
    $selection = Read-Host "`nEnter numbers separated by spaces (e.g., 1 4 10) or selection"
    
    $choices = $selection -split '\s+'
    foreach ($choice in $choices) {
        if ($choice -ne "") {
            Install-App $choice.ToUpper()
        }
    }
    
    if ($selection.ToUpper() -ne "X") {
        Write-Host "`nPress Any Key to return to the menu..." -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
} while ($selection.ToUpper() -ne "X")