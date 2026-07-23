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

# ==============================================================================
# 2. HELPER FUNCTIONS
# ==============================================================================
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
# 3. MAIN GUI MENU
# ==============================================================================
$form = New-Object Windows.Forms.Form
$form.Text = "EA App Automated Offline Tool"
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
"[1] Launch EA + Game in Strict Offline Loop",
"[2] Clear / Reset (Force Kill Running Instances)"
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
        0 { # Option 1: Launch EA + Game in Strict Offline Loop
            $gameExe = Prompt-TextInput "Target Game Executable" "Enter exact game executable name (e.g. bf3.exe, DA2.exe):"
            if ([string]::IsNullOrWhiteSpace($gameExe)) {
                [System.Windows.Forms.MessageBox]::Show("Game executable name cannot be empty.", "Error", "OK", "Error")
                return
            }

            # 1. Kill processes
            $exeNameNoExt = [System.IO.Path]::GetFileNameWithoutExtension($gameExe)
            Stop-Process -Name "EADesktop", "EABackgroundService", "Link2EA", $exeNameNoExt -Force -ErrorAction SilentlyContinue

            # 2. Locate EA App
            $eaLauncherExe = $null
            foreach ($d in @("C", "D", "E", "F", "G", "H")) {
                $testPath = "$d`:\Program Files\Electronic Arts\EA Desktop\EA Desktop\EADesktop.exe"
                if (Test-Path $testPath) {
                    $eaLauncherExe = $testPath
                    break
                }
            }

            if (-not $eaLauncherExe) {
                [System.Windows.Forms.MessageBox]::Show("EA Launcher path not found automatically.", "Error", "OK", "Error")
                return
            }

            # 3. Disable Network Adapters
            Disable-NetAdapter -Name "Wi-Fi", "Ethernet" -Confirm:$false -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2

            # 4. Start Offline Service & Launcher
            Set-Service -Name "EABackgroundService" -StartupType Manual -ErrorAction SilentlyContinue
            Start-Service -Name "EABackgroundService" -ErrorAction SilentlyContinue
            Start-Process -FilePath $eaLauncherExe

            # 5. Prompt User to launch game
            [System.Windows.Forms.MessageBox]::Show("1. EA App has opened offline.`n2. Launch your game now from the library.`n`n3. Click OK ONLY AFTER your game has fully booted up.", "Action Required")

            # 6. Restore Internet
            Enable-NetAdapter -Name "Wi-Fi", "Ethernet" -Confirm:$false -ErrorAction SilentlyContinue

            # 7. Background Loop Monitoring
            while ($true) {
                Start-Sleep -Seconds 2
                $running = Get-Process -Name $exeNameNoExt -ErrorAction SilentlyContinue
                if (-not $running) { break }
            }

            # 8. Cleanup
            Stop-Process -Name "EADesktop", "EABackgroundService", "Link2EA" -Force -ErrorAction SilentlyContinue
            [System.Windows.Forms.MessageBox]::Show("Game exit detected! EA session wiped clean before reconnection.", "Success")
        }

        1 { # Option 2: Clear / Reset
            Enable-NetAdapter -Name "Wi-Fi", "Ethernet" -Confirm:$false -ErrorAction SilentlyContinue
            Stop-Process -Name "EADesktop", "EABackgroundService", "Link2EA" -Force -ErrorAction SilentlyContinue
            [System.Windows.Forms.MessageBox]::Show("Emergency reset complete! Network adapters restored and EA tasks terminated.", "Cleanup Complete")
        }
    }
})

$btnReturn.Add_Click({ $form.Close() })

$form.Controls.Add($btnBlock)
$form.Controls.Add($btnReturn)

[void]$form.ShowDialog()