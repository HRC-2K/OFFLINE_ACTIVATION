# ==============================================================================
# 1. MEMORY-SAFE AUTOMATIC ADMINISTRATOR ELEVATION
# ==============================================================================
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)

if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $rawUrl = "https://raw.githubusercontent.com/HRC-2K/OFFLINE_ACTIVATION/main/ultimate_activation_tool.ps1"
    
    # If running from a file on disk
    if ($MyInvocation.MyCommand.Path) {
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`"" -Verb RunAs
    } 
    # If running directly from web memory (irm | iex)
    else {
        $cmd = "Set-ExecutionPolicy Bypass -Scope Process -Force; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; irm '$rawUrl' | iex"
        $bytes = [System.Text.Encoding]::Unicode.GetBytes($cmd)
        $encoded = [Convert]::ToBase64String($bytes)
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -EncodedCommand $encoded" -Verb RunAs
    }
    exit
}

# ==============================================================================
# 2. DEPENDENCIES & SETUP
# ==============================================================================
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$global:InstallDir = "$env:USERPROFILE\Desktop\App_Installers"
if (-not (Test-Path $global:InstallDir)) {
    New-Item -Path $global:InstallDir -ItemType Directory | Out-Null
}

# ==============================================================================
# 3. MODERN DARK UI SETUP
# ==============================================================================
$form = New-Object Windows.Forms.Form
$form.Text = "Offline Activation & Utility Manager"
$form.Size = New-Object Drawing.Size(820, 800)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0F0F12")
$form.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#FFFFFF")
$form.Font = New-Object Drawing.Font("Segoe UI", 11)
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

# Header Title
$lblTitle = New-Object Windows.Forms.Label
$lblTitle.Text = "Utility Manager"
$lblTitle.Font = New-Object Drawing.Font("Segoe UI Variable Display", 24, [System.Drawing.FontStyle]::Bold)
$lblTitle.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#F9FAFB")
$lblTitle.Location = New-Object Drawing.Point(24, 18)
$lblTitle.AutoSize = $true
$form.Controls.Add($lblTitle)

# Subtitle
$lblSub = New-Object Windows.Forms.Label
$lblSub.Text = "Select a task below to download software, configure rules, or execute scripts."
$lblSub.Font = New-Object Drawing.Font("Segoe UI Variable Text", 11, [System.Drawing.FontStyle]::Regular)
$lblSub.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#9CA3AF")
$lblSub.Location = New-Object Drawing.Point(27, 65)
$lblSub.AutoSize = $true
$form.Controls.Add($lblSub)

# Main ListBox
$list = New-Object Windows.Forms.ListBox
$list.Location = New-Object Drawing.Point(25, 105)
$list.Size = New-Object Drawing.Size(750, 300)
$list.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#18181C")
$list.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#F3F4F6")
$list.BorderStyle = "FixedSingle"
$list.Font = New-Object Drawing.Font("Segoe UI Emoji", 12.5, [System.Drawing.FontStyle]::Regular)
$list.IntegralHeight = $false

@(
"💻   Chris Titus Tech Windows Utility",
"🖥️   UltraViewer",
"🌐   Cloudflare 1.1.1.1 WARP",
"🛡️   Firewall App Blocker (FAB)",
"🎮   Steam Client",
"🎮   Ubisoft Connect",
"🎮   Epic Games Launcher",
"🎮   Rockstar Games Launcher",
"🎮   EA App",
"🔄   TcNo Account Switcher",
"🧹   Bulk Crap Uninstaller",
"⚡   Run All-in-1 Script",
"🔌   Run EA Adapter Offline Script",
"🚫   Run Steam/Ubi/Epic/Rockstar Blocker",
"📦   Download Applications (1-10)"
) | ForEach-Object { [void]$list.Items.Add($_) }

$form.Controls.Add($list)

# Console Output Box
$txtLog = New-Object Windows.Forms.RichTextBox
$txtLog.Location = New-Object Drawing.Point(25, 425)
$txtLog.Size = New-Object Drawing.Size(750, 200)
$txtLog.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#141417")
$txtLog.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#D1D5DB")
$txtLog.BorderStyle = "FixedSingle"
$txtLog.Font = New-Object Drawing.Font("Cascadia Code", 11, [System.Drawing.FontStyle]::Regular)
$txtLog.ReadOnly = $true
$txtLog.ScrollBars = "Vertical"
$form.Controls.Add($txtLog)

# Run Button
$btnRun = New-Object Windows.Forms.Button
$btnRun.Text = "Run Selected"
$btnRun.Location = New-Object Drawing.Point(485, 645)
$btnRun.Size = New-Object Drawing.Size(155, 50)
$btnRun.FlatStyle = "Flat"
$btnRun.FlatAppearance.BorderSize = 0
$btnRun.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2563EB")
$btnRun.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#FFFFFF")
$btnRun.Font = New-Object Drawing.Font("Segoe UI Variable Text", 11.5, [System.Drawing.FontStyle]::Bold)
$btnRun.Cursor = [System.Windows.Forms.Cursors]::Hand
$form.Controls.Add($btnRun)

# Exit Button
$btnExit = New-Object Windows.Forms.Button
$btnExit.Text = "Exit"
$btnExit.Location = New-Object Drawing.Point(655, 645)
$btnExit.Size = New-Object Drawing.Size(120, 50)
$btnExit.FlatStyle = "Flat"
$btnExit.FlatAppearance.BorderSize = 0
$btnExit.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#27272A")
$btnExit.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#FFFFFF")
$btnExit.Font = New-Object Drawing.Font("Segoe UI Variable Text", 11.5, [System.Drawing.FontStyle]::Bold)
$btnExit.Cursor = [System.Windows.Forms.Cursors]::Hand
$form.Controls.Add($btnExit)

# ==============================================================================
# 4. HELPER FUNCTIONS
# ==============================================================================
function Log-Status ($message, $colorHex) {
    $color = [System.Drawing.ColorTranslator]::FromHtml($colorHex)
    $txtLog.SelectionStart = $txtLog.TextLength
    $txtLog.SelectionLength = 0
    $txtLog.SelectionColor = $color
    $txtLog.AppendText("[$(Get-Date -Format 'HH:mm:ss')] ${message}`r`n")
    $txtLog.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}

function Run-RemoteGuiScript ($url) {
    try {
        Log-Status "Fetching remote script..." "#3B82F6"
        $scriptContent = Invoke-RestMethod -Uri $url -UserAgent "Mozilla/5.0" -ErrorAction Stop
        $scriptBlock = [ScriptBlock]::Create($scriptContent)
        
        $form.Hide()
        & $scriptBlock
        $form.Show()
        Log-Status "Remote script execution finished." "#10B981"
    } catch {
        Log-Status "Failed to run remote script - $($_.Exception.Message)" "#EF4444"
        $form.Show()
    }
}

function Process-App ($url, $fileName, $arguments, $processName) {
    $filePath = Join-Path $global:InstallDir $fileName
    Log-Status "Processing ${fileName}..." "#3B82F6"

    if ($processName -ne "none") {
        $pName = [System.IO.Path]::GetFileNameWithoutExtension($processName)
        $running = Get-Process -Name $pName -ErrorAction SilentlyContinue
        if ($running) {
            Log-Status "Terminating running process ${pName}..." "#F59E0B"
            Stop-Process -Name $pName -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
        }
    }

    try {
        Invoke-WebRequest -Uri $url -UserAgent "Mozilla/5.0" -OutFile $filePath -ErrorAction Stop
    } catch {
        Log-Status "Download failed for ${fileName} - $($_.Exception.Message)" "#EF4444"
        return
    }

    Log-Status "Installing ${fileName}..." "#3B82F6"
    if ($arguments -eq "ZIP") {
        Expand-Archive -Path $filePath -DestinationPath "$global:InstallDir\FirewallAppBlocker" -Force
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
    Log-Status "SUCCESS: ${fileName} completed." "#10B981"
}

# ==============================================================================
# 5. EXECUTION LOGIC
# ==============================================================================
Log-Status "Manager initialized. Select a task and click 'Run Selected'." "#9CA3AF"

$btnRun.Add_Click({
    if ($list.SelectedIndex -lt 0) {
        Log-Status "Please select an option from the list first." "#EF4444"
        return
    }

    $btnRun.Enabled = $false
    
    switch ($list.SelectedIndex) {
        0 { 
            Log-Status "Launching Chris Titus Tech Utility..." "#3B82F6"
            $cmd = "Set-ExecutionPolicy Bypass -Scope Process -Force; irm https://christitus.com/win | iex"
            $bytes = [System.Text.Encoding]::Unicode.GetBytes($cmd)
            $encoded = [Convert]::ToBase64String($bytes)
            Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -EncodedCommand $encoded" -WindowStyle Hidden -Wait
            Log-Status "Chris Titus Tech Utility closed." "#10B981"
        }
        1  { Process-App "https://www.ultraviewer.net/en/UltraViewer_setup_6.6_en.exe" "UltraViewer_setup_6.6_en.exe" "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART" "UltraViewer.exe" }
        2  { Process-App "https://downloads.cloudflareclient.com/v1/download/windows/ga" "Cloudflare_1.1.1.1_Setup.msi" "/quiet /norestart ONBOARDING=false" "CloudflareWARP.exe" }
        3  { Process-App "https://www.sordum.org/files/downloads.php?firewall-app-blocker" "FirewallAppBlocker.zip" "ZIP" "Fab.exe" }
        4  { Process-App "https://cdn.akamai.steamstatic.com/client/installer/SteamSetup.exe" "SteamSetup.exe" "/S" "steam.exe" }
        5  { Process-App "https://ubi.li/4vxt9" "UbisoftConnectInstaller.exe" "/S" "upc.exe" }
        6  { Process-App "https://launcher-public-service-prod06.ol.epicgames.com/launcher/api/installer/download/EpicGamesLauncherInstaller.exe" "EpicGamesLauncherInstaller.exe" "/qn /norestart" "EpicGamesLauncher.exe" }
        7  { Process-App "https://gamedownloads.rockstargames.com/public/installer/Rockstar-Games-Launcher.exe" "Rockstar-Games-Launcher.exe" "/s /v`"/qn`"" "Launcher.exe" }
        8  { Process-App "https://origin-a.akamaihd.net/EA-Desktop-Client-Download/installer-releases/EAappInstaller.exe" "EAappInstaller.exe" "/q" "EADesktop.exe" }
        9  { Process-App "https://github.com/TCNOco/TcNo-Acc-Switcher/releases/download/2025-11-20_03/TcNo.Account.Switcher.-.Installer_2025-11-20_03.exe" "TcNo.Account.Switcher.exe" "/S" "TcNo Account Switcher.exe" }
        10 { Process-App "https://github.com/BCUninstaller/Bulk-Crap-Uninstaller/releases/download/v6.2/BCUninstaller_6.2.0_setup.exe" "BCUninstaller_6.2.0_setup.exe" "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART" "BCUninstaller.exe" }
        11 { Run-RemoteGuiScript "https://raw.githubusercontent.com/HRC-2K/OFFLINE_ACTIVATION/main/AI1G.ps1" }
        12 { Run-RemoteGuiScript "https://raw.githubusercontent.com/HRC-2K/OFFLINE_ACTIVATION/main/EAOMG.ps1" }
        13 { Run-RemoteGuiScript "https://raw.githubusercontent.com/HRC-2K/OFFLINE_ACTIVATION/main/SUERG.ps1" }
        14 {
            Log-Status "Starting bulk installation (Apps 1 to 10)..." "#F59E0B"
            1..10 | ForEach-Object { 
                $list.SelectedIndex = $_
                $btnRun.PerformClick() 
            }
        }
    }
    
    $btnRun.Enabled = $true
})

$btnExit.Add_Click({ $form.Close() })

[void]$form.ShowDialog()