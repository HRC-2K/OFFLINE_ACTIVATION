# ==============================================================================
# 1. AUTOMATIC ADMINISTRATOR ELEVATION
# ==============================================================================
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)

if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
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

[System.Windows.Forms.Application]::EnableVisualStyles()
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Global Drive Configuration
$DRIVES = @("C", "A", "B", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z")

# ==============================================================================
# 2. HELPER & BACKEND FUNCTIONS
# ==============================================================================
function Add-FirewallRulesForPath ($folderPath, $ruleName) {
    if (Test-Path $folderPath) {
        $exeFiles = Get-ChildItem -Path $folderPath -Filter "*.exe" -Recurse -ErrorAction SilentlyContinue
        foreach ($exe in $exeFiles) {
            netsh advfirewall firewall add rule name=$ruleName dir=out action=block program="$($exe.FullName)" enable=yes > $null 2>&1
            netsh advfirewall firewall add rule name=$ruleName dir=in action=block program="$($exe.FullName)" enable=yes > $null 2>&1
        }
    }
}

function Prompt-TextInput ($title, $promptText) {
    $inputForm = New-Object Windows.Forms.Form
    $inputForm.Text = $title
    $inputForm.Size = New-Object Drawing.Size(450, 180)
    $inputForm.StartPosition = "CenterParent"
    $inputForm.FormBorderStyle = "FixedDialog"
    $inputForm.MaximizeBox = $false

    $lbl = New-Object Windows.Forms.Label
    $lbl.Text = $promptText
    $lbl.Location = New-Object Drawing.Point(20, 15)
    $lbl.Size = New-Object Drawing.Size(400, 20)
    $inputForm.Controls.Add($lbl)

    $tb = New-Object Windows.Forms.TextBox
    $tb.Location = New-Object Drawing.Point(20, 45)
    $tb.Size = New-Object Drawing.Size(390, 25)
    $inputForm.Controls.Add($tb)

    $btnOk = New-Object Windows.Forms.Button
    $btnOk.Text = "OK"
    $btnOk.Location = New-Object Drawing.Point(220, 85)
    $btnOk.Size = New-Object Drawing.Size(90, 30)
    $btnOk.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $inputForm.Controls.Add($btnOk)

    $btnCancel = New-Object Windows.Forms.Button
    $btnCancel.Text = "Cancel"
    $btnCancel.Location = New-Object Drawing.Point(320, 85)
    $btnCancel.Size = New-Object Drawing.Size(90, 30)
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
# 3. SUB-WINDOW (CLEAR FIREWALL RULES MENU)
# ==============================================================================
function Show-ClearMenu {
    $clearForm = New-Object Windows.Forms.Form
    $clearForm.Text = "Unblock / Clear Firewall Rules"
    $clearForm.Size = New-Object Drawing.Size(650, 560)
    $clearForm.StartPosition = "CenterParent"

    $lbl = New-Object Windows.Forms.Label
    $lbl.Text = "Select a firewall rule category and click Delete"
    $lbl.Location = New-Object Drawing.Point(20, 15)
    $lbl.AutoSize = $true
    $clearForm.Controls.Add($lbl)

    $clearList = New-Object Windows.Forms.ListBox
    $clearList.Location = New-Object Drawing.Point(20, 40)
    $clearList.Size = New-Object Drawing.Size(590, 380)
    $clearList.Font = New-Object Drawing.Font("Segoe UI", 10)

    @(
    "[1] Unblock Steam",
    "[2] Unblock Ubisoft",
    "[3] Unblock Epic Games",
    "[4] Unblock Rockstar",
    "[5] Unblock Custom Folder Rules",
    "[6] UNBLOCK ALL CLIENTS"
    ) | ForEach-Object { [void]$clearList.Items.Add($_) }

    $clearForm.Controls.Add($clearList)

    # Renamed Run to DELETE
    $btnDelete = New-Object Windows.Forms.Button
    $btnDelete.Text = "DELETE"
    $btnDelete.Size = New-Object Drawing.Size(100, 35)
    $btnDelete.Location = New-Object Drawing.Point(20, 440)

    $btnReturn = New-Object Windows.Forms.Button
    $btnReturn.Text = "Return"
    $btnReturn.Size = New-Object Drawing.Size(100, 35)
    $btnReturn.Location = New-Object Drawing.Point(130, 440)

    $btnDelete.Add_Click({
        if ($clearList.SelectedIndex -lt 0) {
            [System.Windows.Forms.MessageBox]::Show("Please select an option to delete.", "Notice")
            return
        }

        switch ($clearList.SelectedIndex) {
            0 { netsh advfirewall firewall delete rule name="Offline_Steam_Block" > $null 2>&1; [System.Windows.Forms.MessageBox]::Show("Steam rules deleted!", "Success") }
            1 { netsh advfirewall firewall delete rule name="Offline_Ubi_Block" > $null 2>&1; [System.Windows.Forms.MessageBox]::Show("Ubisoft rules deleted!", "Success") }
            2 { netsh advfirewall firewall delete rule name="Offline_Epic_Block" > $null 2>&1; [System.Windows.Forms.MessageBox]::Show("Epic Games rules deleted!", "Success") }
            3 { netsh advfirewall firewall delete rule name="Offline_Rockstar_Block" > $null 2>&1; [System.Windows.Forms.MessageBox]::Show("Rockstar rules deleted!", "Success") }
            4 { netsh advfirewall firewall delete rule name="Offline_Custom_Block" > $null 2>&1; [System.Windows.Forms.MessageBox]::Show("Custom folder rules deleted!", "Success") }
            5 {
                netsh advfirewall firewall delete rule name="Offline_Steam_Block" > $null 2>&1
                netsh advfirewall firewall delete rule name="Offline_Ubi_Block" > $null 2>&1
                netsh advfirewall firewall delete rule name="Offline_Epic_Block" > $null 2>&1
                netsh advfirewall firewall delete rule name="Offline_Rockstar_Block" > $null 2>&1
                netsh advfirewall firewall delete rule name="Offline_Custom_Block" > $null 2>&1
                netsh advfirewall firewall delete rule name="Offline_Biz_Block" > $null 2>&1
                [System.Windows.Forms.MessageBox]::Show("All client and custom firewall blocks deleted successfully!", "Success")
            }
        }
    })

    $btnReturn.Add_Click({ $clearForm.Close() })

    $clearForm.Controls.Add($btnDelete)
    $clearForm.Controls.Add($btnReturn)
    [void]$clearForm.ShowDialog()
}

# ==============================================================================
# 4. MAIN GUI MENU
# ==============================================================================
$form = New-Object Windows.Forms.Form
$form.Text = "Ultimate Firewall Activation Manager"
$form.Size = New-Object Drawing.Size(650, 560)
$form.StartPosition = "CenterScreen"

$label = New-Object Windows.Forms.Label
$label.Text = "Select an option and click BLOCK"
$label.Location = New-Object Drawing.Point(20, 15)
$label.AutoSize = $true
$form.Controls.Add($label)

$list = New-Object Windows.Forms.ListBox
$list.Location = New-Object Drawing.Point(20, 40)
$list.Size = New-Object Drawing.Size(590, 380)
$list.Font = New-Object Drawing.Font("Segoe UI", 10)

@(
"[1] Block Steam",
"[2] Block Ubisoft",
"[3] Block Epic Games",
"[4] Block Rockstar Launcher",
"[5] Block Custom Game Directory (Manual Folder Prompt)",
"[6] Clear Firewall Rules (Unblock Options)"
) | ForEach-Object { [void]$list.Items.Add($_) }

$form.Controls.Add($list)

# Renamed Run to BLOCK
$btnBlock = New-Object Windows.Forms.Button
$btnBlock.Text = "BLOCK"
$btnBlock.Size = New-Object Drawing.Size(100, 35)
$btnBlock.Location = New-Object Drawing.Point(20, 440)

# Renamed Exit to Return
$btnReturn = New-Object Windows.Forms.Button
$btnReturn.Text = "Return"
$btnReturn.Size = New-Object Drawing.Size(100, 35)
$btnReturn.Location = New-Object Drawing.Point(130, 440)

$btnBlock.Add_Click({
    if ($list.SelectedIndex -lt 0) {
        [System.Windows.Forms.MessageBox]::Show("Please select an option.", "Notice")
        return
    }

    switch ($list.SelectedIndex) {
        0 { # Option 1: Steam
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
                if ($steamPath) { $steamBin = Join-Path $steamPath "bin" } else { return }
            }
            if (-not $steamCommon) { $steamCommon = "C:\Program Files (x86)\Common Files\Steam" }

            Add-FirewallRulesForPath $steamPath "Offline_Steam_Block"
            Add-FirewallRulesForPath $steamBin "Offline_Steam_Block"
            Add-FirewallRulesForPath $steamCommon "Offline_Steam_Block"
            [System.Windows.Forms.MessageBox]::Show("Steam inbound and outbound rules successfully applied!", "Success")
        }

        1 { # Option 2: Ubisoft
            $ubiPath = $null
            foreach ($d in $DRIVES) {
                if (-not $ubiPath -and (Test-Path "$d`:\Program Files (x86)\Ubisoft")) {
                    $ubiPath = "$d`:\Program Files (x86)\Ubisoft"
                }
            }
            if (-not $ubiPath) {
                $ubiPath = Prompt-TextInput "Ubisoft Path" "Enter Ubisoft folder path:"
                if (-not $ubiPath) { return }
            }

            Add-FirewallRulesForPath $ubiPath "Offline_Ubi_Block"
            [System.Windows.Forms.MessageBox]::Show("Ubisoft inbound and outbound rules successfully applied!", "Success")
        }

        2 { # Option 3: Epic Games
            $epicPath = $null
            foreach ($d in $DRIVES) {
                if (-not $epicPath -and (Test-Path "$d`:\Program Files (x86)\Epic Games")) {
                    $epicPath = "$d`:\Program Files (x86)\Epic Games"
                }
            }
            if (-not $epicPath) {
                $epicPath = Prompt-TextInput "Epic Games Path" "Enter Epic Games Launcher folder path:"
                if (-not $epicPath) { return }
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
                [System.Windows.Forms.MessageBox]::Show("Epic Games Launcher and game directories isolated!", "Success")
            }
        }

        3 { # Option 4: Rockstar
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
                if (-not $rockstarMain) { return }
            }

            Add-FirewallRulesForPath $rockstarMain "Offline_Rockstar_Block"
            Add-FirewallRulesForPath $rockstarSC64 "Offline_Rockstar_Block"
            Add-FirewallRulesForPath $rockstarSC32 "Offline_Rockstar_Block"
            Add-FirewallRulesForPath "$env:LOCALAPPDATA\Rockstar Games" "Offline_Rockstar_Block"
            [System.Windows.Forms.MessageBox]::Show("Rockstar folders successfully isolated!", "Success")
        }

        4 { # Option 5: Custom Game Directory Prompt
            $customDir = Prompt-TextInput "Custom Game Directory Blocker" "Enter or paste exact Game folder path (e.g. J:\Games\GTA V):"
            if ($customDir -and (Test-Path $customDir)) {
                Add-FirewallRulesForPath $customDir "Offline_Custom_Block"
                [System.Windows.Forms.MessageBox]::Show("All executables inside `"$customDir`" successfully blocked!", "Success")
            } elseif ($customDir) {
                [System.Windows.Forms.MessageBox]::Show("The specified directory does not exist.", "Error", "OK", "Error")
            }
        }

        5 { # Option 6: Clear Firewall Rules Menu
            Show-ClearMenu
        }
    }
})

$btnReturn.Add_Click({ $form.Close() })

$form.Controls.Add($btnBlock)
$form.Controls.Add($btnReturn)

[void]$form.ShowDialog()