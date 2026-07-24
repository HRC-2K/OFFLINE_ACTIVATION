# ==============================================================================
# 1. AUTOMATIC ADMINISTRATOR ELEVATION
# ==============================================================================
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)

if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $scriptPath = $MyInvocation.MyCommand.Path
    if ($scriptPath) {
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -WindowStyle Hidden -Verb RunAs
    } else {
        $scriptContent = $MyInvocation.MyCommand.ScriptBlock.ToString()
        $bytes = [System.Text.Encoding]::Unicode.GetBytes($scriptContent)
        $encodedCommand = [Convert]::ToBase64String($bytes)
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -EncodedCommand $encodedCommand" -WindowStyle Hidden -Verb RunAs
    }
    exit
}

# ==============================================================================
# 2. DEPENDENCIES & CONFIGURATION
# ==============================================================================
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$DRIVES = @("C", "A", "B", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z")

# ==============================================================================
# 3. HELPER & BACKEND FUNCTIONS
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

function Add-FirewallRulesForPath ($folderPath, $ruleName) {
    if (Test-Path $folderPath) {
        $exeFiles = Get-ChildItem -Path $folderPath -Filter "*.exe" -Recurse -ErrorAction SilentlyContinue
        foreach ($exe in $exeFiles) {
            netsh advfirewall firewall add rule name=$ruleName dir=out action=block program="$($exe.FullName)" enable=yes > $null 2>&1
            netsh advfirewall firewall add rule name=$ruleName dir=in action=block program="$($exe.FullName)" enable=yes > $null 2>&1
        }
        Log-Status "Applied firewall rules to: ${folderPath}" "#10B981"
    } else {
        Log-Status "Path not found: ${folderPath}" "#F59E0B"
    }
}

function Prompt-TextInput ($title, $promptText) {
    $inputForm = New-Object Windows.Forms.Form
    $inputForm.Text = $title
    $inputForm.Size = New-Object Drawing.Size(520, 220)
    $inputForm.StartPosition = "CenterParent"
    $inputForm.FormBorderStyle = "FixedDialog"
    $inputForm.MaximizeBox = $false
    $inputForm.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0F0F12")
    $inputForm.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#FFFFFF")

    $lbl = New-Object Windows.Forms.Label
    $lbl.Text = $promptText
    $lbl.Location = New-Object Drawing.Point(20, 20)
    $lbl.Size = New-Object Drawing.Size(460, 25)
    $lbl.Font = New-Object Drawing.Font("Segoe UI Variable Text", 10.5)
    $lbl.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#F3F4F6")
    $inputForm.Controls.Add($lbl)

    $tb = New-Object Windows.Forms.TextBox
    $tb.Location = New-Object Drawing.Point(20, 55)
    $tb.Size = New-Object Drawing.Size(460, 30)
    $tb.Font = New-Object Drawing.Font("Segoe UI", 11)
    $tb.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#18181C")
    $tb.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#E4E4E7")
    $tb.BorderStyle = "FixedSingle"
    $inputForm.Controls.Add($tb)

    $btnOk = New-Object Windows.Forms.Button
    $btnOk.Text = "OK"
    $btnOk.Location = New-Object Drawing.Point(250, 110)
    $btnOk.Size = New-Object Drawing.Size(110, 40)
    $btnOk.FlatStyle = "Flat"
    $btnOk.FlatAppearance.BorderSize = 0
    $btnOk.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2563EB")
    $btnOk.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#FFFFFF")
    $btnOk.Font = New-Object Drawing.Font("Segoe UI Variable Text", 10.5, [System.Drawing.FontStyle]::Bold)
    $btnOk.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $inputForm.Controls.Add($btnOk)

    $btnCancel = New-Object Windows.Forms.Button
    $btnCancel.Text = "Cancel"
    $btnCancel.Location = New-Object Drawing.Point(370, 110)
    $btnCancel.Size = New-Object Drawing.Size(110, 40)
    $btnCancel.FlatStyle = "Flat"
    $btnCancel.FlatAppearance.BorderSize = 0
    $btnCancel.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#27272A")
    $btnCancel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#FFFFFF")
    $btnCancel.Font = New-Object Drawing.Font("Segoe UI Variable Text", 10.5, [System.Drawing.FontStyle]::Bold)
    $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $inputForm.Controls.Add($btnCancel)

    $inputForm.AcceptButton = $btnOk
    $inputForm.CancelButton = $btnCancel

    if ($inputForm.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return $tb.Text.Trim()
    }
    return $null
}

# ==============================================================================
# 4. SUB-WINDOW (CLEAR / UNBLOCK RULES MENU)
# ==============================================================================
function Show-ClearMenu {
    $form.Hide() # Hide main window
    
    $clearForm = New-Object Windows.Forms.Form
    $clearForm.Text = "Unblock / Clear Firewall Rules"
    $clearForm.Size = New-Object Drawing.Size(820, 800)
    $clearForm.StartPosition = "CenterScreen"
    $clearForm.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0F0F12")
    $clearForm.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#FFFFFF")
    $clearForm.Font = New-Object Drawing.Font("Segoe UI", 11)
    $clearForm.FormBorderStyle = "FixedDialog"
    $clearForm.MaximizeBox = $false

    # Header Title
    $lblTitle = New-Object Windows.Forms.Label
    $lblTitle.Text = "Unblock Firewall Rules"
    $lblTitle.Font = New-Object Drawing.Font("Segoe UI Variable Display", 24, [System.Drawing.FontStyle]::Bold)
    $lblTitle.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#F9FAFB")
    $lblTitle.Location = New-Object Drawing.Point(24, 18)
    $lblTitle.AutoSize = $true
    $clearForm.Controls.Add($lblTitle)

    # Subtitle
    $lblSub = New-Object Windows.Forms.Label
    $lblSub.Text = "Select a firewall rule category below to remove."
    $lblSub.Font = New-Object Drawing.Font("Segoe UI Variable Text", 11, [System.Drawing.FontStyle]::Regular)
    $lblSub.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#9CA3AF")
    $lblSub.Location = New-Object Drawing.Point(27, 65)
    $lblSub.AutoSize = $true
    $clearForm.Controls.Add($lblSub)

    # Main ListBox
    $clearList = New-Object Windows.Forms.ListBox
    $clearList.Location = New-Object Drawing.Point(25, 105)
    $clearList.Size = New-Object Drawing.Size(750, 300)
    $clearList.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#18181C")
    $clearList.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#F3F4F6")
    $clearList.BorderStyle = "FixedSingle"
    $clearList.Font = New-Object Drawing.Font("Segoe UI Emoji", 12.5, [System.Drawing.FontStyle]::Regular)
    $clearList.IntegralHeight = $false

    @(
    "🎮   Unblock Steam Rules",
    "🎮   Unblock Ubisoft Rules",
    "🎮   Unblock Epic Games Rules",
    "🎮   Unblock Rockstar Rules",
    "📁   Unblock Custom Folder Rules",
    "🧹   UNBLOCK ALL CLIENTS & CUSTOM RULES"
    ) | ForEach-Object { [void]$clearList.Items.Add($_) }

    $clearForm.Controls.Add($clearList)

    # Console Output Box
    $subLog = New-Object Windows.Forms.RichTextBox
    $subLog.Location = New-Object Drawing.Point(25, 425)
    $subLog.Size = New-Object Drawing.Size(750, 200)
    $subLog.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#141417")
    $subLog.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#D1D5DB")
    $subLog.BorderStyle = "FixedSingle"
    $subLog.Font = New-Object Drawing.Font("Cascadia Code", 11, [System.Drawing.FontStyle]::Regular)
    $subLog.ReadOnly = $true
    $subLog.ScrollBars = "Vertical"
    $clearForm.Controls.Add($subLog)

    $global:txtLog = $subLog
    Log-Status "Unblock Manager initialized. Select an option to remove." "#9CA3AF"

    # Delete Action Button
    $btnDelete = New-Object Windows.Forms.Button
    $btnDelete.Text = "Delete Rule"
    $btnDelete.Location = New-Object Drawing.Point(485, 645)
    $btnDelete.Size = New-Object Drawing.Size(155, 50)
    $btnDelete.FlatStyle = "Flat"
    $btnDelete.FlatAppearance.BorderSize = 0
    $btnDelete.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#DC2626")
    $btnDelete.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#FFFFFF")
    $btnDelete.Font = New-Object Drawing.Font("Segoe UI Variable Text", 11.5, [System.Drawing.FontStyle]::Bold)
    $btnDelete.Cursor = [System.Windows.Forms.Cursors]::Hand
    $clearForm.Controls.Add($btnDelete)

    # Return Button
    $btnReturn = New-Object Windows.Forms.Button
    $btnReturn.Text = "Return"
    $btnReturn.Location = New-Object Drawing.Point(655, 645)
    $btnReturn.Size = New-Object Drawing.Size(120, 50)
    $btnReturn.FlatStyle = "Flat"
    $btnReturn.FlatAppearance.BorderSize = 0
    $btnReturn.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#27272A")
    $btnReturn.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#FFFFFF")
    $btnReturn.Font = New-Object Drawing.Font("Segoe UI Variable Text", 11.5, [System.Drawing.FontStyle]::Bold)
    $btnReturn.Cursor = [System.Windows.Forms.Cursors]::Hand
    $clearForm.Controls.Add($btnReturn)

    $btnDelete.Add_Click({
        if ($clearList.SelectedIndex -lt 0) {
            Log-Status "Please select a rule option to delete." "#EF4444"
            return
        }

        switch ($clearList.SelectedIndex) {
            0 { netsh advfirewall firewall delete rule name="Offline_Steam_Block" > $null 2>&1; Log-Status "Deleted Steam Firewall Rules." "#10B981" }
            1 { netsh advfirewall firewall delete rule name="Offline_Ubi_Block" > $null 2>&1; Log-Status "Deleted Ubisoft Firewall Rules." "#10B981" }
            2 { netsh advfirewall firewall delete rule name="Offline_Epic_Block" > $null 2>&1; Log-Status "Deleted Epic Games Firewall Rules." "#10B981" }
            3 { netsh advfirewall firewall delete rule name="Offline_Rockstar_Block" > $null 2>&1; Log-Status "Deleted Rockstar Firewall Rules." "#10B981" }
            4 { netsh advfirewall firewall delete rule name="Offline_Custom_Block" > $null 2>&1; Log-Status "Deleted Custom Folder Firewall Rules." "#10B981" }
            5 {
                netsh advfirewall firewall delete rule name="Offline_Steam_Block" > $null 2>&1
                netsh advfirewall firewall delete rule name="Offline_Ubi_Block" > $null 2>&1
                netsh advfirewall firewall delete rule name="Offline_Epic_Block" > $null 2>&1
                netsh advfirewall firewall delete rule name="Offline_Rockstar_Block" > $null 2>&1
                netsh advfirewall firewall delete rule name="Offline_Custom_Block" > $null 2>&1
                netsh advfirewall firewall delete rule name="Offline_Biz_Block" > $null 2>&1
                Log-Status "SUCCESS: All client and custom firewall blocks deleted!" "#10B981"
            }
        }
    })

    $btnReturn.Add_Click({ $clearForm.Close() })

    [void]$clearForm.ShowDialog()
    $global:txtLog = $mainLog
    $form.Show()
}

# ==============================================================================
# 5. MAIN GUI MENU
# ==============================================================================
$form = New-Object Windows.Forms.Form
$form.Text = "Ultimate Firewall Manager"
$form.Size = New-Object Drawing.Size(820, 800)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0F0F12")
$form.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#FFFFFF")
$form.Font = New-Object Drawing.Font("Segoe UI", 11)
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

# Header Title
$lblTitle = New-Object Windows.Forms.Label
$lblTitle.Text = "Firewall Manager"
$lblTitle.Font = New-Object Drawing.Font("Segoe UI Variable Display", 24, [System.Drawing.FontStyle]::Bold)
$lblTitle.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#F9FAFB")
$lblTitle.Location = New-Object Drawing.Point(24, 18)
$lblTitle.AutoSize = $true
$form.Controls.Add($lblTitle)

# Subtitle
$lblSub = New-Object Windows.Forms.Label
$lblSub.Text = "Select a launcher or directory below to manage offline firewall rules."
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
"🎮   Block Steam",
"🎮   Block Ubisoft Connect",
"🎮   Block Epic Games Launcher",
"🎮   Block Rockstar Games Launcher",
"📁   Block Custom Game Directory (Manual Folder Prompt)",
"🧹   Clear Firewall Rules (Unblock Options)"
) | ForEach-Object { [void]$list.Items.Add($_) }

$form.Controls.Add($list)

# Console Output Box
$mainLog = New-Object Windows.Forms.RichTextBox
$mainLog.Location = New-Object Drawing.Point(25, 425)
$mainLog.Size = New-Object Drawing.Size(750, 200)
$mainLog.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#141417")
$mainLog.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#D1D5DB")
$mainLog.BorderStyle = "FixedSingle"
$mainLog.Font = New-Object Drawing.Font("Cascadia Code", 11, [System.Drawing.FontStyle]::Regular)
$mainLog.ReadOnly = $true
$mainLog.ScrollBars = "Vertical"
$form.Controls.Add($mainLog)

$global:txtLog = $mainLog

# Block Action Button
$btnBlock = New-Object Windows.Forms.Button
$btnBlock.Text = "Apply Action"
$btnBlock.Location = New-Object Drawing.Point(485, 645)
$btnBlock.Size = New-Object Drawing.Size(155, 50)
$btnBlock.FlatStyle = "Flat"
$btnBlock.FlatAppearance.BorderSize = 0
$btnBlock.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2563EB")
$btnBlock.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#FFFFFF")
$btnBlock.Font = New-Object Drawing.Font("Segoe UI Variable Text", 11.5, [System.Drawing.FontStyle]::Bold)
$btnBlock.Cursor = [System.Windows.Forms.Cursors]::Hand
$form.Controls.Add($btnBlock)

# Return Button
$btnReturn = New-Object Windows.Forms.Button
$btnReturn.Text = "Return"
$btnReturn.Location = New-Object Drawing.Point(655, 645)
$btnReturn.Size = New-Object Drawing.Size(120, 50)
$btnReturn.FlatStyle = "Flat"
$btnReturn.FlatAppearance.BorderSize = 0
$btnReturn.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#27272A")
$btnReturn.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#FFFFFF")
$btnReturn.Font = New-Object Drawing.Font("Segoe UI Variable Text", 11.5, [System.Drawing.FontStyle]::Bold)
$btnReturn.Cursor = [System.Windows.Forms.Cursors]::Hand
$form.Controls.Add($btnReturn)

# ==============================================================================
# 6. EXECUTION LOGIC
# ==============================================================================
Log-Status "Manager initialized. Select a task and click 'Apply Action'." "#9CA3AF"

$btnBlock.Add_Click({
    if ($list.SelectedIndex -lt 0) {
        Log-Status "Please select an option from the list first." "#EF4444"
        return
    }

    $btnBlock.Enabled = $false

    switch ($list.SelectedIndex) {
        0 { # Steam
            Log-Status "Scanning drives for Steam installation..." "#3B82F6"
            $steamPath = $null; $steamCommon = $null; $steamBin = $null
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
                $steamPath = Prompt-TextInput "Steam Path" "Enter Steam directory path (e.g. J:\Steam):"
                if ($steamPath) { $steamBin = Join-Path $steamPath "bin" } else { $btnBlock.Enabled = $true; return }
            }
            if (-not $steamCommon) { $steamCommon = "C:\Program Files (x86)\Common Files\Steam" }

            Add-FirewallRulesForPath $steamPath "Offline_Steam_Block"
            Add-FirewallRulesForPath $steamBin "Offline_Steam_Block"
            Add-FirewallRulesForPath $steamCommon "Offline_Steam_Block"
            Log-Status "SUCCESS: Steam inbound and outbound rules applied!" "#10B981"
        }
        1 { # Ubisoft
            Log-Status "Scanning drives for Ubisoft installation..." "#3B82F6"
            $ubiPath = $null
            foreach ($d in $DRIVES) {
                if (-not $ubiPath -and (Test-Path "$d`:\Program Files (x86)\Ubisoft")) {
                    $ubiPath = "$d`:\Program Files (x86)\Ubisoft"
                }
            }
            if (-not $ubiPath) {
                $ubiPath = Prompt-TextInput "Ubisoft Path" "Enter Ubisoft folder path:"
                if (-not $ubiPath) { $btnBlock.Enabled = $true; return }
            }

            Add-FirewallRulesForPath $ubiPath "Offline_Ubi_Block"
            Log-Status "SUCCESS: Ubisoft inbound and outbound rules applied!" "#10B981"
        }
        2 { # Epic Games
            Log-Status "Scanning drives for Epic Games Launcher..." "#3B82F6"
            $epicPath = $null;
            foreach ($d in $DRIVES) {
                if (-not $epicPath -and (Test-Path "$d`:\Program Files (x86)\Epic Games")) {
                    $epicPath = "$d`:\Program Files (x86)\Epic Games"
                }
            }
            if (-not $epicPath) {
                $epicPath = Prompt-TextInput "Epic Games Path" "Enter Epic Games Launcher folder path:"
                if (-not $epicPath) { $btnBlock.Enabled = $true; return }
            }

            Add-FirewallRulesForPath $epicPath "Offline_Epic_Block"

            $localEpic = "$env:LOCALAPPDATA\EpicGamesLauncher"
            if (Test-Path $localEpic) { Add-FirewallRulesForPath $localEpic "Offline_Epic_Block" }

            $epicGameDir = "C:\Program Files\Epic Games"
            if (-not (Test-Path $epicGameDir)) {
                $epicGameDir = Prompt-TextInput "Custom Game Path" "Enter custom Game download folder path (e.g. J:\Games\EpicGames):"
            }

            if ($epicGameDir -and (Test-Path $epicGameDir)) {
                Add-FirewallRulesForPath $epicGameDir "Offline_Epic_Block"
                Log-Status "SUCCESS: Epic Games Launcher and game directories isolated!" "#10B981"
            }
        }
        3 { # Rockstar
            Log-Status "Scanning drives for Rockstar Games Launcher..." "#3B82F6"
            $rockstarMain = $null; $rockstarSC64 = $null; $rockstarSC32 = $null
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
                $rockstarMain = Prompt-TextInput "Rockstar Path" "Enter Rockstar Launcher path:"
                if (-not $rockstarMain) { $btnBlock.Enabled = $true; return }
            }

            Add-FirewallRulesForPath $rockstarMain "Offline_Rockstar_Block"
            Add-FirewallRulesForPath $rockstarSC64 "Offline_Rockstar_Block"
            Add-FirewallRulesForPath $rockstarSC32 "Offline_Rockstar_Block"
            Add-FirewallRulesForPath "$env:LOCALAPPDATA\Rockstar Games" "Offline_Rockstar_Block"
            Log-Status "SUCCESS: Rockstar folders isolated!" "#10B981"
        }
        4 { # Custom Folder Blocker
            $customDir = Prompt-TextInput "Custom Folder Blocker" "Enter or paste exact Game folder path (e.g. J:\Games\GTA V):"
            if ($customDir -and (Test-Path $customDir)) {
                Add-FirewallRulesForPath $customDir "Offline_Custom_Block"
                Log-Status "SUCCESS: All executables inside '${customDir}' blocked!" "#10B981"
            } elseif ($customDir) {
                Log-Status "ERROR: The specified directory '${customDir}' does not exist." "#EF4444"
            }
        }
        5 { # Unblock Options Sub-Page
            Show-ClearMenu
        }
    }

    $btnBlock.Enabled = $true
})

$btnReturn.Add_Click({ $form.Close() })

[void]$form.ShowDialog()