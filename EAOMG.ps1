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

# ==============================================================================
# 3. HELPER & BACKEND FUNCTIONS
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
# 4. MAIN GUI MENU
# ==============================================================================
$form = New-Object Windows.Forms.Form
$form.Text = "EA App Automated Offline Tool"
$form.Size = New-Object Drawing.Size(820, 800)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0F0F12")
$form.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#FFFFFF")
$form.Font = New-Object Drawing.Font("Segoe UI", 11)
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

# Header Title
$lblTitle = New-Object Windows.Forms.Label
$lblTitle.Text = "EA Offline Adapter Tool"
$lblTitle.Font = New-Object Drawing.Font("Segoe UI Variable Display", 24, [System.Drawing.FontStyle]::Bold)
$lblTitle.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#F9FAFB")
$lblTitle.Location = New-Object Drawing.Point(24, 18)
$lblTitle.AutoSize = $true
$form.Controls.Add($lblTitle)

# Subtitle
$lblSub = New-Object Windows.Forms.Label
$lblSub.Text = "Select an EA execution mode below and click 'Run Selected'."
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
"🔌   Launch EA + Game in Strict Offline Loop",
"🔄   Clear / Reset (Force Kill Running Instances & Restore Network)"
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

# Action Button
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

# Return / Exit Button
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
# 5. EXECUTION LOGIC
# ==============================================================================
Log-Status "Tool initialized. Select a mode and click 'Run Selected'." "#9CA3AF"

$btnRun.Add_Click({
    if ($list.SelectedIndex -lt 0) {
        Log-Status "Please select an option from the list first." "#EF4444"
        return
    }

    $btnRun.Enabled = $false

    switch ($list.SelectedIndex) {
        0 { # Option 1: Launch EA + Game in Strict Offline Loop
            $gameExe = Prompt-TextInput "Target Game Executable" "Enter exact game executable name (e.g. bf3.exe, DA2.exe):"
            if ([string]::IsNullOrWhiteSpace($gameExe)) {
                Log-Status "ERROR: Game executable name cannot be empty." "#EF4444"
                $btnRun.Enabled = $true
                return
            }

            # 1. Kill active processes
            $exeNameNoExt = [System.IO.Path]::GetFileNameWithoutExtension($gameExe)
            Log-Status "Terminating running EA instances and target game..." "#F59E0B"
            Stop-Process -Name "EADesktop", "EABackgroundService", "Link2EA", $exeNameNoExt -Force -ErrorAction SilentlyContinue

            # 2. Locate EA App
            Log-Status "Locating EA App installation..." "#3B82F6"
            $eaLauncherExe = $null
            foreach ($d in @("C", "D", "E", "F", "G", "H")) {
                $testPath = "$d`:\Program Files\Electronic Arts\EA Desktop\EA Desktop\EADesktop.exe"
                if (Test-Path $testPath) {
                    $eaLauncherExe = $testPath
                    break
                }
            }

            if (-not $eaLauncherExe) {
                Log-Status "ERROR: EA Launcher path not found automatically." "#EF4444"
                $btnRun.Enabled = $true
                return
            }

            # 3. Disable Network Adapters
            Log-Status "Disabling network adapters (Wi-Fi, Ethernet)..." "#F59E0B"
            Disable-NetAdapter -Name "Wi-Fi", "Ethernet" -Confirm:$false -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2

            # 4. Start Offline Service & Launcher
            Log-Status "Starting EABackgroundService & launching EA Desktop..." "#3B82F6"
            Set-Service -Name "EABackgroundService" -StartupType Manual -ErrorAction SilentlyContinue
            Start-Service -Name "EABackgroundService" -ErrorAction SilentlyContinue
            Start-Process -FilePath $eaLauncherExe

            # 5. Prompt User to launch game
            [System.Windows.Forms.MessageBox]::Show("1. EA App has opened offline.`n2. Launch your game now from the library.`n`n3. CLICK OK ONLY AFTER YOU HAVE COMPLETELY EXITED THE GAME.", "Action Required", "OK", "Information")

            # 6. Restore Internet
            Log-Status "Restoring network adapters..." "#10B981"
            Enable-NetAdapter -Name "Wi-Fi", "Ethernet" -Confirm:$false -ErrorAction SilentlyContinue

            # 7. Background Loop Monitoring
            Log-Status "Monitoring process '${exeNameNoExt}' exit state..." "#3B82F6"
            while ($true) {
                Start-Sleep -Seconds 2
                $running = Get-Process -Name $exeNameNoExt -ErrorAction SilentlyContinue
                if (-not $running) { break }
            }

            # 8. Cleanup
            Log-Status "Game exit detected! Force closing EA session..." "#F59E0B"
            Stop-Process -Name "EADesktop", "EABackgroundService", "Link2EA" -Force -ErrorAction SilentlyContinue
            Log-Status "SUCCESS: EA session wiped clean before reconnection." "#10B981"
        }

        1 { # Option 2: Clear / Reset
            Log-Status "Executing emergency reset..." "#F59E0B"
            Enable-NetAdapter -Name "Wi-Fi", "Ethernet" -Confirm:$false -ErrorAction SilentlyContinue
            Stop-Process -Name "EADesktop", "EABackgroundService", "Link2EA" -Force -ErrorAction SilentlyContinue
            Log-Status "SUCCESS: Emergency reset complete! Network restored and EA tasks terminated." "#10B981"
        }
    }

    $btnRun.Enabled = $true
})

$btnReturn.Add_Click({ $form.Close() })

[void]$form.ShowDialog()