
<#
    OAT.ps1 - Offline Activation & Utility Manager
    Copyright (C) 2026 HRC-2K <https://github.com/HRC-2K/OFFLINE_ACTIVATION>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
#>



# ==============================================================================
# 1. AUTO-ELEVATE TO ADMINISTRATOR
# ==============================================================================
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)

if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $scriptPath = $MyInvocation.MyCommand.Path
    
    if ($scriptPath) {
        Start-Process "$scriptPath" -Verb RunAs
    } else {
        $scriptContent = $MyInvocation.MyCommand.ScriptBlock.ToString()
        $bytes = [System.Text.Encoding]::Unicode.GetBytes($scriptContent)
        $encodedCommand = [Convert]::ToBase64String($bytes)
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -EncodedCommand $encodedCommand" -WindowStyle Hidden -Verb RunAs
    }
    exit
}

# ==============================================================================
# 2. DEPENDENCIES & PERSISTENT CONFIGURATION SETUP
# ==============================================================================
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# Determine executable root path (Works for both .ps1 and Win-PS2EXE compiled .exe)
if ([System.IO.Path]::GetExtension($MyInvocation.MyCommand.Path) -eq '.ps1') {
    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
} else {
    $ScriptDir = [System.IO.Path]::GetDirectoryName([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)
}

$ConfigFile = Join-Path $ScriptDir "config.json"
$defaultPath = "$env:USERPROFILE\Desktop\App_Installers"

# Load or initialize saved directory
if (Test-Path $ConfigFile) {
    try {
        $config = Get-Content -Path $ConfigFile -Raw | ConvertFrom-Json
        if ($config.InstallDir -and (Test-Path $config.InstallDir)) {
            $global:InstallDir = $config.InstallDir
        } else {
            $global:InstallDir = $defaultPath
        }
    } catch {
        $global:InstallDir = $defaultPath
    }
} else {
    $global:InstallDir = $defaultPath
}

if (-not (Test-Path $global:InstallDir)) {
    New-Item -Path $global:InstallDir -ItemType Directory | Out-Null
}

$DRIVES = @("C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z")

# Full catalog definition for multi-download popup dialog
$script:AppList = @(
    @{ Index = 1;  Name = "UltraViewer";                        Icon = "🖥️"; Type = "App" },
    @{ Index = 2;  Name = "Cloudflare 1.1.1.1 WARP";             Icon = "🌐"; Type = "App" },
    @{ Index = 3;  Name = "Firewall App Blocker (FAB)";         Icon = "🛡️"; Type = "App" },
    @{ Index = 4;  Name = "Steam Client";                      Icon = "🎮"; Type = "App" },
    @{ Index = 5;  Name = "Ubisoft Connect";                   Icon = "🎮"; Type = "App" },
    @{ Index = 6;  Name = "Epic Games Launcher";               Icon = "🎮"; Type = "App" },
    @{ Index = 7;  Name = "Rockstar Games Launcher";           Icon = "🎮"; Type = "App" },
    @{ Index = 8;  Name = "EA App";                            Icon = "🎮"; Type = "App" },
    @{ Index = 9;  Name = "TcNo Account Switcher";             Icon = "🔄"; Type = "App" },
    @{ Index = 10; Name = "Bulk Crap Uninstaller";             Icon = "🧹"; Type = "App" },
    @{ Index = 11; Name = "All-in-1 Script (AI1G.ps1)";         Icon = "⚡"; Type = "Script" },
    @{ Index = 12; Name = "EA Adapter Offline (EAOMG.ps1)";     Icon = "🔌"; Type = "Script" },
    @{ Index = 13; Name = "Launcher Blocker (SUERG.ps1)";       Icon = "🚫"; Type = "Script" }
)

# Main list box display items
$script:MainListItems = @(
    @{ Icon = "💻"; Name = "Chris Titus Tech Windows Utility" },
    @{ Icon = "🖥️"; Name = "UltraViewer" },
    @{ Icon = "🌐"; Name = "Cloudflare 1.1.1.1 WARP" },
    @{ Icon = "🛡️"; Name = "Firewall App Blocker (FAB)" },
    @{ Icon = "🎮"; Name = "Steam Client" },
    @{ Icon = "🎮"; Name = "Ubisoft Connect" },
    @{ Icon = "🎮"; Name = "Epic Games Launcher" },
    @{ Icon = "🎮"; Name = "Rockstar Games Launcher" },
    @{ Icon = "🎮"; Name = "EA App" },
    @{ Icon = "🔄"; Name = "TcNo Account Switcher" },
    @{ Icon = "🧹"; Name = "Bulk Crap Uninstaller" },
    @{ Icon = "⚡"; Name = "Run All-in-1 Script" },
    @{ Icon = "🔌"; Name = "Run EA Adapter Offline Script" },
    @{ Icon = "🚫"; Name = "Run Steam/Ubi/Epic/Rockstar Blocker" },
    @{ Icon = "📦"; Name = "Download Multiple Applications / Scripts" }
)

# ==============================================================================
# 3. MODERN DARK UI SETUP
# ==============================================================================
$form = New-Object Windows.Forms.Form
$form.Text = "Offline Activation & Utility Manager"
$form.Size = New-Object Drawing.Size(820, 820)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0F0F12")
$form.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#FFFFFF")
$form.Font = New-Object Drawing.Font("Segoe UI", 11)
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

# Header Title (Gamer / Cursive Script Font)
$lblTitle = New-Object Windows.Forms.Label
$lblTitle.Text = "HRC Offline Utility Tool"
$lblTitle.Font = New-Object Drawing.Font("Segoe Script", 22, [System.Drawing.FontStyle]::Bold)
$lblTitle.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#3B82F6") # Electric Blue accent
$lblTitle.Location = New-Object Drawing.Point(24, 12)
$lblTitle.AutoSize = $true
$form.Controls.Add($lblTitle)

# Subtitle
$lblSub = New-Object Windows.Forms.Label
$lblSub.Text = "Select a task below to download software, launch tools, or execute scripts."
$lblSub.Font = New-Object Drawing.Font("Segoe UI Variable Text", 10.5, [System.Drawing.FontStyle]::Regular)
$lblSub.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#9CA3AF")
$lblSub.Location = New-Object Drawing.Point(26, 65)
$lblSub.AutoSize = $true
$form.Controls.Add($lblSub)

# Directory Selector Bar UI
$lblDirTitle = New-Object Windows.Forms.Label
$lblDirTitle.Text = "Download Path:"
$lblDirTitle.Font = New-Object Drawing.Font("Segoe UI Variable Text", 9.5, [System.Drawing.FontStyle]::Bold)
$lblDirTitle.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#D1D5DB")
$lblDirTitle.Location = New-Object Drawing.Point(25, 103)
$lblDirTitle.AutoSize = $true
$form.Controls.Add($lblDirTitle)

$txtDir = New-Object Windows.Forms.TextBox
$txtDir.Text = $global:InstallDir
$txtDir.Location = New-Object Drawing.Point(135, 100)
$txtDir.Size = New-Object Drawing.Size(520, 26)
$txtDir.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#18181C")
$txtDir.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#10B981")
$txtDir.BorderStyle = "FixedSingle"
$txtDir.ReadOnly = $true
$form.Controls.Add($txtDir)

$btnChangeDir = New-Object Windows.Forms.Button
$btnChangeDir.Text = "Browse..."
$btnChangeDir.Location = New-Object Drawing.Point(665, 99)
$btnChangeDir.Size = New-Object Drawing.Size(110, 28)
$btnChangeDir.FlatStyle = "Flat"
$btnChangeDir.FlatAppearance.BorderSize = 0
$btnChangeDir.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#374151")
$btnChangeDir.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#FFFFFF")
$btnChangeDir.Font = New-Object Drawing.Font("Segoe UI Variable Text", 9.5, [System.Drawing.FontStyle]::Bold)
$btnChangeDir.Cursor = [System.Windows.Forms.Cursors]::Hand
$form.Controls.Add($btnChangeDir)

# Main ListBox (Taller Box: Height increased to 340)
$list = New-Object Windows.Forms.ListBox
$list.Location = New-Object Drawing.Point(25, 138)
$list.Size = New-Object Drawing.Size(750, 340)
$list.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#18181C")
$list.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#F3F4F6")
$list.BorderStyle = "FixedSingle"
$list.DrawMode = [System.Windows.Forms.DrawMode]::OwnerDrawFixed
$list.ItemHeight = 28
$list.IntegralHeight = $false

foreach ($item in $script:MainListItems) {
    [void]$list.Items.Add($item)
}

$fontEmoji = New-Object Drawing.Font("Segoe UI Emoji", 11)
$fontText  = New-Object Drawing.Font("Segoe UI Variable Text", 11)

$list.Add_DrawItem({
    param($sender, $e)
    if ($e.Index -lt 0) { return }

    $g = $e.Graphics
    $item = $sender.Items[$e.Index]

    if (($e.State -band [System.Windows.Forms.DrawItemState]::Selected) -eq [System.Windows.Forms.DrawItemState]::Selected) {
        $bgBrush = New-Object Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml("#2563EB"))
        $fgBrush = New-Object Drawing.SolidBrush([System.Drawing.Color]::White)
    } else {
        $bgBrush = New-Object Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml("#18181C"))
        $fgBrush = New-Object Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml("#F3F4F6"))
    }

    $g.FillRectangle($bgBrush, $e.Bounds)
    $g.DrawString($item.Icon, $fontEmoji, $fgBrush, 12, ($e.Bounds.Y + 2))
    $g.DrawString($item.Name, $fontText, $fgBrush, 48, ($e.Bounds.Y + 3))

    $e.DrawFocusRectangle()
})

$form.Controls.Add($list)

# Console Output Box (Shifted down to Y = 495)
$txtLog = New-Object Windows.Forms.RichTextBox
$txtLog.Location = New-Object Drawing.Point(25, 495)
$txtLog.Size = New-Object Drawing.Size(750, 200)
$txtLog.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#141417")
$txtLog.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#D1D5DB")
$txtLog.BorderStyle = "FixedSingle"
$txtLog.Font = New-Object Drawing.Font("Cascadia Code", 11, [System.Drawing.FontStyle]::Regular)
$txtLog.ReadOnly = $true
$txtLog.ScrollBars = "Vertical"
$form.Controls.Add($txtLog)

$global:txtLog = $txtLog

# Download Button (Shifted down to Y = 715)
$btnDownload = New-Object Windows.Forms.Button
$btnDownload.Text = "Download"
$btnDownload.Location = New-Object Drawing.Point(340, 715)
$btnDownload.Size = New-Object Drawing.Size(130, 48)
$btnDownload.FlatStyle = "Flat"
$btnDownload.FlatAppearance.BorderSize = 0
$btnDownload.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#059669")
$btnDownload.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#FFFFFF")
$btnDownload.Font = New-Object Drawing.Font("Segoe UI Variable Text", 11.5, [System.Drawing.FontStyle]::Bold)
$btnDownload.Cursor = [System.Windows.Forms.Cursors]::Hand
$form.Controls.Add($btnDownload)

# Run Button (Shifted down to Y = 715)
$btnRun = New-Object Windows.Forms.Button
$btnRun.Text = "Run Selected"
$btnRun.Location = New-Object Drawing.Point(480, 715)
$btnRun.Size = New-Object Drawing.Size(160, 48)
$btnRun.FlatStyle = "Flat"
$btnRun.FlatAppearance.BorderSize = 0
$btnRun.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2563EB")
$btnRun.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#FFFFFF")
$btnRun.Font = New-Object Drawing.Font("Segoe UI Variable Text", 11.5, [System.Drawing.FontStyle]::Bold)
$btnRun.Cursor = [System.Windows.Forms.Cursors]::Hand
$form.Controls.Add($btnRun)

# Exit Button (Shifted down to Y = 715)
$btnExit = New-Object Windows.Forms.Button
$btnExit.Text = "Exit"
$btnExit.Location = New-Object Drawing.Point(650, 715)
$btnExit.Size = New-Object Drawing.Size(125, 48)
$btnExit.FlatStyle = "Flat"
$btnExit.FlatAppearance.BorderSize = 0
$btnExit.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#27272A")
$btnExit.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#FFFFFF")
$btnExit.Font = New-Object Drawing.Font("Segoe UI Variable Text", 11.5, [System.Drawing.FontStyle]::Bold)
$btnExit.Cursor = [System.Windows.Forms.Cursors]::Hand
$form.Controls.Add($btnExit)

# ==============================================================================
# 4. HELPER & DETECTION FUNCTIONS
# ==============================================================================
function Log-Status ($message, $colorHex) {
    if ($null -eq $global:txtLog -or $global:txtLog.IsDisposed) { return }
    $color = [System.Drawing.ColorTranslator]::FromHtml($colorHex)
    $global:txtLog.SelectionStart = $global:txtLog.TextLength
    $global:txtLog.SelectionLength = 0
    $global:txtLog.SelectionColor = $color
    $global:txtLog.AppendText("[$(Get-Date -Format 'HH:mm:ss')] ${message}`r`n")
    $global:txtLog.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}

# Directory Browse & Persistence Logic
$btnChangeDir.Add_Click({
    $folderPicker = New-Object Windows.Forms.FolderBrowserDialog
    $folderPicker.Description = "Select a default directory for downloads and portable tools:"
    $folderPicker.SelectedPath = $global:InstallDir

    if ($folderPicker.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $global:InstallDir = $folderPicker.SelectedPath
        $txtDir.Text = $global:InstallDir
        
        # Save choice persistently to config.json
        try {
            @{ InstallDir = $global:InstallDir } | ConvertTo-Json | Set-Content -Path $ConfigFile -Encoding UTF8 -Force
            Log-Status "Download directory updated & saved: $global:InstallDir" "#10B981"
        } catch {
            Log-Status "Updated directory, but failed to save config.json - $($_.Exception.Message)" "#F59E0B"
        }
    }
})

# Smart Remote/Local Offline Script Runner
function Run-RemoteOrLocalScript ($url, $fileName, $scriptName) {
    $localPath = Join-Path $global:InstallDir $fileName

    # Preserve current log box reference
    $currentLog = $global:txtLog

    # Option A: Local File Exists
    if (Test-Path $localPath) {
        try {
            Log-Status "Local file found: Executing ${fileName} locally..." "#10B981"
            Log-Status "Local File Path: ${localPath}" "#9CA3AF"
            
            $form.Hide()
            
            # Execute script block cleanly
            $scriptContent = Get-Content -Path $localPath -Encoding UTF8 -Raw -ErrorAction Stop
            $scriptBlock = [ScriptBlock]::Create($scriptContent)
            & $scriptBlock
            
            # Restore log box reference after child script completes
            $global:txtLog = $currentLog
            $form.Show()
            Log-Status "Returned from ${scriptName}. Main Manager active." "#10B981"
            return
        } catch {
            $global:txtLog = $currentLog
            $form.Show()
            Log-Status "Failed to run local script - $($_.Exception.Message)" "#EF4444"
            return
        }
    }

    # Option B: Stream directly from GitHub
    try {
        Log-Status "Local file not downloaded yet. Streaming live from GitHub..." "#3B82F6"
        Log-Status "Source URL: ${url}" "#3B82F6"
        
        $form.Hide()
        
        # Download and execute in memory
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $scriptContent = Invoke-RestMethod -Uri $url -UserAgent "Mozilla/5.0" -ErrorAction Stop
        $scriptBlock = [ScriptBlock]::Create($scriptContent)
        & $scriptBlock
        
        # Restore log box reference
        $global:txtLog = $currentLog
        $form.Show()
        Log-Status "Returned from ${scriptName}. Main Manager active." "#10B981"
    } catch {
        $global:txtLog = $currentLog
        $form.Show()
        Log-Status "Failed to fetch/run remote script - $($_.Exception.Message)" "#EF4444"
    }
}

# Downloads a PS1 script file to disk for offline use
function Download-ScriptFile ($url, $fileName, $scriptName) {
    $localPath = Join-Path $global:InstallDir $fileName
    Log-Status "Downloading PS1 Script: ${scriptName}..." "#3B82F6"
    Log-Status "Download Source: ${url}" "#3B82F6"

    try {
        Invoke-WebRequest -Uri $url -UserAgent "Mozilla/5.0" -OutFile $localPath -ErrorAction Stop
        Log-Status "SUCCESS: ${fileName} downloaded to $global:InstallDir" "#10B981"
    } catch {
        Log-Status "Download failed for ${fileName} - $($_.Exception.Message)" "#EF4444"
    }
}

function Process-App ($url, $fileName, $arguments, $processName) {
    $filePath = Join-Path $global:InstallDir $fileName
    Log-Status "Processing ${fileName}..." "#3B82F6"
    Log-Status "Download Source: ${url}" "#3B82F6"

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
        Log-Status "Downloading binary to $global:InstallDir..." "#3B82F6"
        Invoke-WebRequest -Uri $url -UserAgent "Mozilla/5.0" -OutFile $filePath -ErrorAction Stop
    } catch {
        Log-Status "Download failed for ${fileName} - $($_.Exception.Message)" "#EF4444"
        return
    }

    Log-Status "Installing ${fileName} silently..." "#3B82F6"
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

function Get-AppExecutablePath ($index) {
    switch ($index) {
        1 { # UltraViewer - Scans Registry + Recursive Executable Search
            $regPath = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
                                             "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
                                             "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue |
                       Where-Object { $_.DisplayName -like "*UltraViewer*" -or $_.Publisher -like "*UltraViewer*" } | 
                       Select-Object -ExpandProperty InstallLocation -First 1

            if ($regPath) {
                $exe = Get-ChildItem -Path $regPath -Filter "*UltraViewer*.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($exe) { return $exe.FullName }
            }

            foreach ($d in $DRIVES) {
                $paths = @(
                    "$d`:\Program Files (x86)\UltraViewer\UltraViewer.exe", 
                    "$d`:\Program Files\UltraViewer\UltraViewer.exe",
                    "$global:InstallDir\UltraViewer.exe"
                )
                foreach ($p in $paths) { if (Test-Path $p) { return $p } }
            }
        }
        2 { # Cloudflare WARP
            $p = "C:\Program Files\Cloudflare\Cloudflare WARP\Cloudflare WARP.exe"
            if (Test-Path $p) { return $p }
        }
        3 { # FAB - Prioritizes Fab_x64.exe inside App_Installers
            $fabFiles = Get-ChildItem -Path $global:InstallDir -Filter "*Fab_x64.exe*" -Recurse -ErrorAction SilentlyContinue
            if ($fabFiles) { return $fabFiles[0].FullName }

            $fabFallback = Get-ChildItem -Path $global:InstallDir -Filter "*Fab*.exe*" -Recurse -ErrorAction SilentlyContinue
            if ($fabFallback) { return $fabFallback[0].FullName }
        }
        4 { # Steam
            foreach ($d in $DRIVES) {
                $p = "$d`:\Program Files (x86)\Steam\steam.exe"
                if (Test-Path $p) { return $p }
            }
        }
        5 { # Ubisoft Connect
            foreach ($d in $DRIVES) {
                $p = "$d`:\Program Files (x86)\Ubisoft\Ubisoft Game Launcher\upc.exe"
                if (Test-Path $p) { return $p }
            }
        }
        6 { # Epic Games Launcher
            foreach ($d in $DRIVES) {
                $paths = @(
                    "$d`:\Program Files\Epic Games\Launcher\Portal\Binaries\Win64\EpicGamesLauncher.exe",
                    "$d`:\Program Files (x86)\Epic Games\Launcher\Portal\Binaries\Win64\EpicGamesLauncher.exe"
                )
                foreach ($p in $paths) { if (Test-Path $p) { return $p } }
            }
        }
        7 { # Rockstar Games Launcher
            foreach ($d in $DRIVES) {
                $p = "$d`:\Program Files\Rockstar Games\Launcher\Launcher.exe"
                if (Test-Path $p) { return $p }
            }
        }
        8 { # EA App
            foreach ($d in $DRIVES) {
                $p = "$d`:\Program Files\Electronic Arts\EA Desktop\EA Desktop\EADesktop.exe"
                if (Test-Path $p) { return $p }
            }
        }
        9 { # TcNo Account Switcher - Only launches the Main Application
            $regPath = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
                                             "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
                                             "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue |
                       Where-Object { $_.DisplayName -like "*TcNo*" } | Select-Object -ExpandProperty InstallLocation -First 1

            if ($regPath) {
                # Strictly filter OUT Tray, Server, and Update executables
                $exe = Get-ChildItem -Path $regPath -Filter "*.exe" -ErrorAction SilentlyContinue | 
                       Where-Object { 
                           $_.Name -like "*TcNo*" -and 
                           $_.Name -notlike "*Server*" -and 
                           $_.Name -notlike "*Tray*" -and 
                           $_.Name -notlike "*Update*" 
                       } | Select-Object -First 1

                if ($exe) { return $exe.FullName }
            }

            # Explicit direct paths to the main UI binary
            $userPaths = @(
                "$env:LOCALAPPDATA\Programs\TcNo-Account-Switcher\TcNo Account Switcher.exe",
                "$env:LOCALAPPDATA\Programs\TcNo-Account-Switcher\TcNo.Account.Switcher.exe",
                "C:\Program Files\TcNo Account Switcher\TcNo Account Switcher.exe",
                "C:\Program Files (x86)\TcNo Account Switcher\TcNo Account Switcher.exe",
                "$global:InstallDir\TcNo Account Switcher.exe"
            )
            foreach ($p in $userPaths) { if (Test-Path $p) { return $p } }

            foreach ($d in $DRIVES) {
                $paths = @(
                    "$d`:\Program Files\TcNo Account Switcher\TcNo Account Switcher.exe",
                    "$d`:\Program Files (x86)\TcNo Account Switcher\TcNo Account Switcher.exe"
                )
                foreach ($p in $paths) { if (Test-Path $p) { return $p } }
            }
        }
        10 { # Bulk Crap Uninstaller - Scans Registry + Portable App_Installers + Drives
            $regPath = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
                                             "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
                                             "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue |
                       Where-Object { $_.DisplayName -like "*Bulk Crap Uninstaller*" -or $_.DisplayName -like "*BCUninstaller*" } | 
                       Select-Object -ExpandProperty InstallLocation -First 1

            if ($regPath -and (Test-Path "$regPath\BCUninstaller.exe")) { return "$regPath\BCUninstaller.exe" }

            $bcuPortable = Get-ChildItem -Path $global:InstallDir -Filter "BCUninstaller.exe" -Recurse -ErrorAction SilentlyContinue
            if ($bcuPortable) { return $bcuPortable[0].FullName }

            foreach ($d in $DRIVES) {
                $paths = @(
                    "$d`:\Program Files\Bulk Crap Uninstaller\BCUninstaller.exe",
                    "$d`:\Program Files (x86)\Bulk Crap Uninstaller\BCUninstaller.exe",
                    "$d`:\BCUninstaller\BCUninstaller.exe"
                )
                foreach ($p in $paths) { if (Test-Path $p) { return $p } }
            }
        }
    }
    return $null
}

function Execute-Download ($index) {
    switch ($index) {
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
        11 { Download-ScriptFile "https://raw.githubusercontent.com/HRC-2K/OFFLINE_ACTIVATION/main/AI1G.ps1" "AI1G.ps1" "All-In-1 Script" }
        12 { Download-ScriptFile "https://raw.githubusercontent.com/HRC-2K/OFFLINE_ACTIVATION/main/EAOMG.ps1" "EAOMG.ps1" "EA Adapter Offline Script" }
        13 { Download-ScriptFile "https://raw.githubusercontent.com/HRC-2K/OFFLINE_ACTIVATION/main/SUERG.ps1" "SUERG.ps1" "Steam/Ubi/Epic/Rockstar Blocker" }
    }
}

# ==============================================================================
# 5. MULTI-SELECTION DIALOG POP-UP
# ==============================================================================
function Show-MultiDownloadDialog {
    $dlg = New-Object Windows.Forms.Form
    $dlg.Text = "Select Items to Download"
    $dlg.Size = New-Object Drawing.Size(480, 520)
    $dlg.StartPosition = "CenterParent"
    $dlg.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#18181C")
    $dlg.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#FFFFFF")
    $dlg.Font = New-Object Drawing.Font("Segoe UI", 10)
    $dlg.FormBorderStyle = "FixedDialog"
    $dlg.MaximizeBox = $false
    $dlg.MinimizeBox = $false

    $dlgLabel = New-Object Windows.Forms.Label
    $dlgLabel.Text = "Check the applications and scripts you would like to download:"
    $dlgLabel.Location = New-Object Drawing.Point(20, 15)
    $dlgLabel.AutoSize = $true
    $dlgLabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#D1D5DB")
    $dlg.Controls.Add($dlgLabel)

    $chkList = New-Object Windows.Forms.ListBox
    $chkList.Location = New-Object Drawing.Point(20, 45)
    $chkList.Size = New-Object Drawing.Size(420, 350)
    $chkList.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0F0F12")
    $chkList.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#F3F4F6")
    $chkList.BorderStyle = "FixedSingle"
    $chkList.DrawMode = [System.Windows.Forms.DrawMode]::OwnerDrawFixed
    $chkList.ItemHeight = 28
    
    $script:CheckedStates = @{}

    for ($i = 0; $i -lt $script:AppList.Count; $i++) {
        [void]$chkList.Items.Add($script:AppList[$i])
        $script:CheckedStates[$i] = $false
    }

    $dlgFontEmoji = New-Object Drawing.Font("Segoe UI Emoji", 11)
    $dlgFontText  = New-Object Drawing.Font("Segoe UI", 10.5)

    $chkList.Add_DrawItem({
        param($sender, $e)
        if ($e.Index -lt 0) { return }

        $g = $e.Graphics
        $app = $sender.Items[$e.Index]
        $isChecked = $script:CheckedStates[$e.Index]

        if (($e.State -band [System.Windows.Forms.DrawItemState]::Selected) -eq [System.Windows.Forms.DrawItemState]::Selected) {
            $bgBrush = New-Object Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml("#2563EB"))
            $fgBrush = New-Object Drawing.SolidBrush([System.Drawing.Color]::White)
        } else {
            $bgBrush = New-Object Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml("#0F0F12"))
            $fgBrush = New-Object Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml("#F3F4F6"))
        }

        $g.FillRectangle($bgBrush, $e.Bounds)

        $chkState = if ($isChecked) { [System.Windows.Forms.VisualStyles.CheckBoxState]::CheckedNormal } else { [System.Windows.Forms.VisualStyles.CheckBoxState]::UncheckedNormal }
        $chkY = $e.Bounds.Y + [int]((28 - 14) / 2)
        [System.Windows.Forms.CheckBoxRenderer]::DrawCheckBox($g, (New-Object Drawing.Point(8, $chkY)), $chkState)

        $g.DrawString($app.Icon, $dlgFontEmoji, $fgBrush, 32, ($e.Bounds.Y + 2))
        $g.DrawString($app.Name, $dlgFontText, $fgBrush, 68, ($e.Bounds.Y + 3))

        $e.DrawFocusRectangle()
    })

    $chkList.Add_Click({
        $pt = $chkList.PointToClient([System.Windows.Forms.Cursor]::Position)
        $idx = $chkList.IndexFromPoint($pt)
        if ($idx -ge 0) {
            $script:CheckedStates[$idx] = -not $script:CheckedStates[$idx]
            $chkList.Invalidate()
        }
    })

    $dlg.Controls.Add($chkList)

    $btnSelectAll = New-Object Windows.Forms.Button
    $btnSelectAll.Text = "Select All"
    $btnSelectAll.Location = New-Object Drawing.Point(20, 410)
    $btnSelectAll.Size = New-Object Drawing.Size(95, 30)
    $btnSelectAll.FlatStyle = "Flat"
    $btnSelectAll.FlatAppearance.BorderSize = 0
    $btnSelectAll.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#27272A")
    $btnSelectAll.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#FFFFFF")
    $btnSelectAll.Add_Click({
        for ($i = 0; $i -lt $chkList.Items.Count; $i++) {
            $script:CheckedStates[$i] = $true
        }
        $chkList.Invalidate()
    })
    $dlg.Controls.Add($btnSelectAll)

    $btnDeselectAll = New-Object Windows.Forms.Button
    $btnDeselectAll.Text = "Deselect All"
    $btnDeselectAll.Location = New-Object Drawing.Point(125, 410)
    $btnDeselectAll.Size = New-Object Drawing.Size(100, 30)
    $btnDeselectAll.FlatStyle = "Flat"
    $btnDeselectAll.FlatAppearance.BorderSize = 0
    $btnDeselectAll.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#27272A")
    $btnDeselectAll.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#FFFFFF")
    $btnDeselectAll.Add_Click({
        for ($i = 0; $i -lt $chkList.Items.Count; $i++) {
            $script:CheckedStates[$i] = $false
        }
        $chkList.Invalidate()
    })
    $dlg.Controls.Add($btnDeselectAll)

    $btnStart = New-Object Windows.Forms.Button
    $btnStart.Text = "Start Download"
    $btnStart.Location = New-Object Drawing.Point(300, 410)
    $btnStart.Size = New-Object Drawing.Size(140, 30)
    $btnStart.FlatStyle = "Flat"
    $btnStart.FlatAppearance.BorderSize = 0
    $btnStart.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#059669")
    $btnStart.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#FFFFFF")
    $btnStart.Font = New-Object Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $btnStart.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $dlg.Controls.Add($btnStart)

    $dlg.AcceptButton = $btnStart

    if ($dlg.ShowDialog($form) -eq [System.Windows.Forms.DialogResult]::OK) {
        $selectedIndices = @()
        for ($i = 0; $i -lt $chkList.Items.Count; $i++) {
            if ($script:CheckedStates[$i]) {
                $selectedIndices += $script:AppList[$i].Index
            }
        }
        return $selectedIndices
    }
    return $null
}

# ==============================================================================
# 6. EXECUTION LOGIC
# ==============================================================================
Log-Status "Manager initialized. Active directory: $global:InstallDir" "#9CA3AF"

# BUTTON 1: DOWNLOAD
$btnDownload.Add_Click({
    if ($list.SelectedIndex -lt 0) {
        Log-Status "Please select an item to download." "#EF4444"
        return
    }

    $idx = $list.SelectedIndex
    
    # Download Single App or Script (1 - 13)
    if ($idx -ge 1 -and $idx -le 13) {
        $btnDownload.Enabled = $false
        $btnRun.Enabled = $false
        Execute-Download $idx
        $btnDownload.Enabled = $true
        $btnRun.Enabled = $true
    } 
    # Download Multiple Applications / Scripts (14)
    elseif ($idx -eq 14) {
        $toDownload = Show-MultiDownloadDialog
        if ($toDownload -and $toDownload.Count -gt 0) {
            $btnDownload.Enabled = $false
            $btnRun.Enabled = $false
            Log-Status "Starting multi-item download ($($toDownload.Count) selected)..." "#F59E0B"
            foreach ($appIdx in $toDownload) {
                Execute-Download $appIdx
            }
            $btnDownload.Enabled = $true
            $btnRun.Enabled = $true
        } else {
            Log-Status "Multi-download canceled or no items selected." "#9CA3AF"
        }
    } 
    else {
        Log-Status "Download option is not available for this item." "#F59E0B"
    }
})

# BUTTON 2: RUN SELECTED
$btnRun.Add_Click({
    if ($list.SelectedIndex -lt 0) {
        Log-Status "Please select an option from the list first." "#EF4444"
        return
    }

    $btnDownload.Enabled = $false
    $btnRun.Enabled = $false
    $idx = $list.SelectedIndex

    switch ($idx) {
        0 { 
            Log-Status "Launching Chris Titus Tech Utility..." "#3B82F6"
            $cmd = "Set-ExecutionPolicy Bypass -Scope Process -Force; irm https://christitus.com/win | iex"
            $bytes = [System.Text.Encoding]::Unicode.GetBytes($cmd)
            $encoded = [Convert]::ToBase64String($bytes)
            Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -EncodedCommand $encoded" -WindowStyle Hidden -Wait
            Log-Status "Chris Titus Tech Utility closed." "#10B981"
        }
        
        # Applications 1 to 10
        { $_ -ge 1 -and $_ -le 10 } {
            $exePath = Get-AppExecutablePath $idx
            if ($exePath -and (Test-Path $exePath)) {
                Log-Status "Launching installed app: ${exePath}..." "#10B981"
                Start-Process -FilePath $exePath
            } else {
                Log-Status "Application not found on system." "#F59E0B"
                $appName = $script:AppList[$idx - 1].Name
                $response = [System.Windows.Forms.MessageBox]::Show(
                    "The selected application '${appName}' is not installed on this system.`n`nWould you like to download and install it now?", 
                    "Application Not Found", 
                    [System.Windows.Forms.MessageBoxButtons]::YesNo, 
                    [System.Windows.Forms.MessageBoxIcon]::Question
                )
                
                if ($response -eq [System.Windows.Forms.DialogResult]::Yes) {
                    Execute-Download $idx
                }
            }
        }

        # Scripts 11-13 (Checks for local file first; if missing, streams directly from GitHub without saving)
        11 { Run-RemoteOrLocalScript "https://raw.githubusercontent.com/HRC-2K/OFFLINE_ACTIVATION/main/AI1G.ps1" "AI1G.ps1" "All-In-1 Script" }
        12 { Run-RemoteOrLocalScript "https://raw.githubusercontent.com/HRC-2K/OFFLINE_ACTIVATION/main/EAOMG.ps1" "EAOMG.ps1" "EA Adapter Offline Script" }
        13 { Run-RemoteOrLocalScript "https://raw.githubusercontent.com/HRC-2K/OFFLINE_ACTIVATION/main/SUERG.ps1" "SUERG.ps1" "Steam/Ubi/Epic/Rockstar Blocker" }
        
        # Multi-Download Option
        14 {
            $toDownload = Show-MultiDownloadDialog
            if ($toDownload -and $toDownload.Count -gt 0) {
                Log-Status "Starting multi-item download ($($toDownload.Count) selected)..." "#F59E0B"
                foreach ($appIdx in $toDownload) {
                    Execute-Download $appIdx
                }
            } else {
                Log-Status "Multi-download canceled or no items selected." "#9CA3AF"
            }
        }
    }
    
    $btnDownload.Enabled = $true
    $btnRun.Enabled = $true
})

# BUTTON 3: EXIT
$btnExit.Add_Click({ $form.Close() })

[void]$form.ShowDialog()
