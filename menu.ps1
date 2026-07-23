# Requires Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Please re-run this script in a PowerShell window opened as Administrator!"
    exit
}

$InstallDir = "$env:USERPROFILE\Desktop\App_Installers"
if (-not (Test-Path $InstallDir)) {
    New-Item -Path $InstallDir -ItemType Directory | Out-Null
}

function Show-Menu {
    Clear-Host
    Write-Host "=========================================================================" -ForegroundColor Cyan
    Write-Host "                FULLY SILENT SMART UPGRADE / INSTALLATION MENU          " -ForegroundColor Yellow
    Write-Host "=========================================================================" -ForegroundColor Cyan
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

function Invoke-SubScript ($url, $fileName) {
    Write-Host "`n[+] Fetching and executing sub-script..." -ForegroundColor Cyan
    try {
        $tempPath = Join-Path $env:TEMP $fileName
        Invoke-WebRequest -Uri $url -UserAgent "Mozilla/5.0" -OutFile $tempPath
        Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$tempPath`"" -Wait -NoNewWindow
    } catch {
        Write-Error "Failed to execute remote script: $_"
    }
}

function Install-App ($choice) {
    switch ($choice) {
        "1"  { Write-Host "`n[+] Installing UltraViewer..." -ForegroundColor Yellow }
        "2"  { Write-Host "`n[+] Installing Cloudflare WARP..." -ForegroundColor Yellow }
        "3"  { Write-Host "`n[+] Extracting Firewall App Blocker..." -ForegroundColor Yellow }
        "4"  { Write-Host "`n[+] Installing Steam..." -ForegroundColor Yellow }
        "5"  { Write-Host "`n[+] Installing Ubisoft Connect..." -ForegroundColor Yellow }
        "6"  { Write-Host "`n[+] Installing Epic Games Launcher..." -ForegroundColor Yellow }
        "7"  { Write-Host "`n[+] Downloading Rockstar Games Launcher..." -ForegroundColor Yellow }
        "8"  { Write-Host "`n[+] Installing EA App..." -ForegroundColor Yellow }
        "9"  { Write-Host "`n[+] Installing TcNo Account Switcher..." -ForegroundColor Yellow }
        "10" { Write-Host "`n[+] Installing Bulk Crap Uninstaller..." -ForegroundColor Yellow }
        "11" { Invoke-SubScript "https://github.com/HRC-2K/OFFLINE_ACTIVATION/releases/download/OA/ALL_in_1.bat" "ALL_in_1.bat" }
        "12" { Invoke-SubScript "https://github.com/HRC-2K/OFFLINE_ACTIVATION/releases/download/OA/EA_Adapter_Offline_Method.bat" "EA_Adapter.bat" }
        "13" { Invoke-SubScript "https://github.com/HRC-2K/OFFLINE_ACTIVATION/releases/download/OA/Steam_Ubi_Epic_RStar.bat" "Launcher.bat" }
        "14" { Invoke-SubScript "https://github.com/HRC-2K/OFFLINE_ACTIVATION/releases/download/OA/Silent.Install_Upgrade.bat" "Silent_Install.bat" }
        "A"  { 
            Write-Host "`n[+] Installing ALL items sequentially..." -ForegroundColor Yellow
            1..10 | ForEach-Object { Install-App "$_" }
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