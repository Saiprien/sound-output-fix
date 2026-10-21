param([switch]$SmokeTest, [string]$PreviewPath, [switch]$StartInTray, [switch]$StartAtLogin)
. "$PSScriptRoot\AudioCore.ps1"
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
. "$PSScriptRoot\Localization.ps1"
$script:appVersion = '1.2.0'
$launchInTray = $StartInTray -or ($StartAtLogin -and $script:startMinimized)
. "$PSScriptRoot\Startup.ps1"
. "$PSScriptRoot\Theme.ps1"
. "$PSScriptRoot\ModernControls.ps1"
Add-Type @'
using System.Runtime.InteropServices;
public static class AudioAppIdentity {
    [DllImport("dwmapi.dll")]
    public static extern int DwmSetWindowAttribute(System.IntPtr hwnd, int attribute, ref int value, int size);
    [DllImport("shell32.dll", CharSet = CharSet.Unicode)]
    public static extern int SetCurrentProcessExplicitAppUserModelID(string appId);
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern System.IntPtr SendMessage(System.IntPtr hwnd, int msg, System.IntPtr wparam, System.IntPtr lparam);
}
'@
[void][AudioAppIdentity]::SetCurrentProcessExplicitAppUserModelID('EarPodsAuto.SpotifyAudio')
[System.Windows.Forms.Application]::EnableVisualStyles()
$mutex = New-Object System.Threading.Mutex($false, 'Local\EarPodsSpotifyAuto')
if (!$mutex.WaitOne(0)) {
    if (!$StartAtLogin -and !$StartInTray) { Set-Content (Join-Path $root 'show.flag') 'show' }
    $mutex.Dispose()
    return
}
Remove-Item (Join-Path $root 'stop.flag') -ErrorAction SilentlyContinue
Remove-Item (Join-Path $root 'show.flag') -ErrorAction SilentlyContinue
$script:worker = $null
$script:lastConnected = $false
$script:pendingConnect = $false
$script:lastOutput = $null
$script:outputCandidate = $null
$script:statusExpiresAt = $null
$form = New-Object System.Windows.Forms.Form
$fontNames = @([System.Drawing.FontFamily]::Families | ForEach-Object Name)
$script:uiFont = if ($fontNames -contains 'Segoe UI Variable Text') { 'Segoe UI Variable Text' } else { 'Segoe UI' }
$script:buttonFont = if ($fontNames -contains 'Segoe UI Semibold') { 'Segoe UI Semibold' } else { $script:uiFont }
$form.Font = New-Object System.Drawing.Font($script:uiFont,10)
$script:indicatorFont = New-Object System.Drawing.Font($script:uiFont,9)
$script:audioButtonFont = New-Object System.Drawing.Font($script:buttonFont,11,[System.Drawing.FontStyle]::Bold)
$form.Text = 'Sound Output Fix'
$form.ClientSize = New-Object System.Drawing.Size(440,282)
$form.FormBorderStyle = 'FixedSingle'
$form.MaximizeBox = $false
$form.StartPosition = 'CenterScreen'
$appIcon = $null
$titleIcon = $null
$iconPath = Join-Path $root 'assets\user-app-icon.ico'
if (Test-Path $iconPath) {
    $appIcon = New-Object System.Drawing.Icon($iconPath)
    $form.Icon = $appIcon
}
$titleIconPath = Join-Path $root 'assets\user-title-icon.ico'
if (Test-Path $titleIconPath) {
    $titleIcon = New-Object System.Drawing.Icon($titleIconPath, ([System.Windows.Forms.SystemInformation]::SmallIconSize))
    $form.Icon = $titleIcon
    $form.Add_HandleCreated({
        # Set the small window icon when Windows creates its handle.
        [void][AudioAppIdentity]::SendMessage($form.Handle, 0x80, [IntPtr]::Zero, $titleIcon.Handle)
    })
}
$speakersButton = New-Object SoftButton
$speakersButton.Text = 'SPEAKERS'
$speakersButton.SetBounds(20,20,190,95)
$earButton = New-Object SoftButton
$earButton.Text = 'EARPODS'
$earButton.SetBounds(230,20,190,95)
function Set-ButtonPhoto($button, $filename) {
    $path = if ([System.IO.Path]::IsPathRooted($filename)) { $filename } else { Join-Path $root ('assets\' + $filename) }
    if (!(Test-Path $path)) { return }
    $source = [System.Drawing.Image]::FromFile($path)
    $bitmap = New-Object System.Drawing.Bitmap($button.Width, $button.Height)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $attributes = New-Object System.Drawing.Imaging.ImageAttributes
    try {
        $graphics.Clear($(if ($script:palette) { $script:palette.Button } else { [System.Drawing.Color]::White }))
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $matrix = New-Object System.Drawing.Imaging.ColorMatrix
        $isDefaultIcon = [System.IO.Path]::GetFileName($path) -match '^(speakers|headphones)-(light|dark)\.png$'
        $matrix.Matrix33 = if ($isDefaultIcon) { 0.85 } else { 0.40 }
        $attributes.SetColorMatrix($matrix)
        $scale = [Math]::Min(($button.Width - 12) / $source.Width, ($button.Height - 8) / $source.Height)
        $width = [int]($source.Width * $scale)
        $height = [int]($source.Height * $scale)
        $rect = New-Object System.Drawing.Rectangle([int](($button.Width - $width)/2), [int](($button.Height - $height)/2), $width, $height)
        if ($isDefaultIcon) {
            $iconTop = if ([System.IO.Path]::GetFileName($path) -like 'headphones-*') { 10 } else { 7 }
            $rect = New-Object System.Drawing.Rectangle([int](($button.Width - 48)/2), $iconTop, 48, 48)
            $button.TextAlign = 'BottomCenter'
        } else { $button.TextAlign = 'MiddleCenter' }
        $graphics.DrawImage($source, $rect, 0, 0, $source.Width, $source.Height, [System.Drawing.GraphicsUnit]::Pixel, $attributes)
        $previousImage = $button.BackgroundImage
        $button.BackgroundImage = $bitmap
        if ($previousImage) { $previousImage.Dispose() }
        $button.BackgroundImageLayout = 'None'
        $button.FlatStyle = 'Flat'
        $button.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(195,195,195)
        $button.Font = $script:audioButtonFont
        $button.ForeColor = if ($script:palette) { $script:palette.Text } else { [System.Drawing.Color]::FromArgb(25,25,25) }
    } finally { $source.Dispose(); $graphics.Dispose(); $attributes.Dispose() }
}
Set-ButtonPhoto $speakersButton 'speakers.png'
Set-ButtonPhoto $earButton 'earpods.png'
$script:animationClock = [System.Diagnostics.Stopwatch]::StartNew()
$deviceIndicators = @{}
foreach ($target in @('Speakers','EarPods')) {
    $indicator = New-Object SmoothIndicatorPanel
    $left = if ($target -eq 'Speakers') { 20 } else { 230 }
    $indicator.SetBounds($left,118,190,28)
    $indicator.Tag = ''
    $indicator.Add_Paint({ param($sender,$eventArgs)
        $g = $eventArgs.Graphics
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        if ($sender.Tag -eq 'Active') {
            $text = (T 'Active') + ' ' + [char]0x2713
            $brush = New-Object System.Drawing.SolidBrush($script:palette.Active)
            try {
                $size = $g.MeasureString($text,$script:indicatorFont)
                $g.DrawString($text,$script:indicatorFont,$brush,[single](($sender.Width-$size.Width)/2),[single]5)
            } finally { $brush.Dispose() }
        } elseif ($sender.Tag -in @('Switching','Finishing')) {
            $brush = New-Object System.Drawing.SolidBrush($script:palette.Switching)
            try {
                $size = $g.MeasureString((T $sender.Tag),$script:indicatorFont)
                $x = [single](($sender.Width-$size.Width-24)/2)
                $g.DrawString((T $sender.Tag),$script:indicatorFont,$brush,$x,[single]5)
                for ($i=0; $i -lt 3; $i++) {
                    $phase = ($script:animationClock.Elapsed.TotalSeconds / 1.2 - $i / 8.0) * 2 * [Math]::PI
                    $lift = [Math]::Max(0,[Math]::Sin($phase))*4
                    $g.FillEllipse($brush,[single]($x+$size.Width+3+$i*6),[single](15-$lift),[single]3,[single]3)
                }
            } finally { $brush.Dispose() }
        }
    })
    $deviceIndicators[$target] = $indicator
    $form.Controls.Add($indicator)
}
$animationTimer = New-Object System.Windows.Forms.Timer
$animationTimer.Interval = 30
$animationTimer.Add_Tick({
    foreach ($indicator in $deviceIndicators.Values) { if ($indicator.Tag -in @('Switching','Finishing')) { $indicator.Invalidate() } }
})
function Update-DeviceButtons([string]$active, [string]$switching = '') {
    $script:displayActive = $active
    $script:displaySwitching = $switching
    if ($speakerItem -and $earItem) {
        $speakerItem.Checked = $active -eq 'Speakers' -and !$switching
        $earItem.Checked = $active -eq 'EarPods' -and !$switching
    }
    foreach ($entry in @(@($speakersButton,'Speakers'), @($earButton,'EarPods'))) {
        $button = $entry[0]
        $selected = $active -eq $entry[1]
        $button.Text = (Get-DeviceName $entry[1]).ToUpperInvariant()
        $indicator = $deviceIndicators[$entry[1]]
        $indicator.Tag = if ($switching -eq $entry[1]) { if ($script:switchPhase -eq 'Finishing') { 'Finishing' } else { 'Switching' } } elseif ($selected -and !$switching) { 'Active' } else { '' }
        $indicator.Invalidate()
        $button.FlatStyle = 'Flat'
        $button.FlatAppearance.BorderSize = if (($selected -and !$switching) -or ($switching -eq $entry[1] -and $script:switchPhase -eq 'Finishing')) { 2 } else { 1 }
        $button.FlatAppearance.BorderColor = if ($switching -eq $entry[1] -and $script:palette) { $script:palette.Switching } elseif ($selected -and !$switching) { $(if ($script:palette) { $script:palette.Active } else { [System.Drawing.Color]::FromArgb(92,145,111) }) } else { if ($script:palette) { $script:palette.Border } else { [System.Drawing.Color]::FromArgb(195,195,195) } }
    }
    if ($switching) { $animationTimer.Start() } else { $animationTimer.Stop(); $script:animationClock.Restart() }
}
Update-DeviceButtons ''
$auto = New-Object System.Windows.Forms.CheckBox
$auto.Text = 'Comuta automat cand conectez EarPods'
$auto.SetBounds(20,155,360,27)
$auto.Checked = $true
$followOutput = New-Object System.Windows.Forms.CheckBox
$followOutput.Text = 'Urmeaza iesirea aleasa din meniul Windows'
$followOutput.SetBounds(20,185,360,27)
$followOutput.Checked = $true
$followOutput.Add_CheckedChanged({ $script:lastOutput = $null; $script:outputCandidate = $null })
$status = New-Object System.Windows.Forms.Label
$status.SetBounds(20,223,355,45)
$status.Tag = 'SecondaryText'
$script:statusKey = 'Ready'
$script:statusTarget = ''
$script:rawResult = ''
$status.Text = T 'Ready'
if (!(Test-Path $tool)) { $script:statusKey = 'Missing'; $status.Text = T 'Missing' }
$form.Controls.AddRange(@($speakersButton,$earButton,$auto,$followOutput,$status))
$tray = New-Object System.Windows.Forms.NotifyIcon
$tray.Icon = [System.Drawing.SystemIcons]::Application
if ($appIcon) { $tray.Icon = $appIcon }
$tray.Text = 'Sound Output Fix'
$tray.Visible = $true
$menu = New-Object System.Windows.Forms.ContextMenuStrip
$showItem = $menu.Items.Add('Deschide')
$speakerItem = $menu.Items.Add('SPEAKERS')
$earItem = $menu.Items.Add('EARPODS')
$quitItem = $menu.Items.Add('Iesire')
$tray.ContextMenuStrip = $menu
$settingsButton = New-Object SoftButton
$settingsButton.Text = [char]0xE713
$settingsButton.Font = New-Object System.Drawing.Font('Segoe MDL2 Assets',14)
$settingsButton.SetBounds(386,228,32,32)
$settingsButton.FlatStyle = 'Flat'
$settingsButton.FlatAppearance.BorderSize = 0
$settingsButton.Add_MouseEnter({ $settingsButton.BackColor = [System.Windows.Forms.ControlPaint]::Light($script:palette.Button) })
$settingsButton.Add_MouseLeave({ $settingsButton.BackColor = $script:palette.Button })
$form.Controls.Add($settingsButton)
$settingsTip = New-Object System.Windows.Forms.ToolTip
function Apply-Language {
    $auto.Text = (T 'AutoDevice') -f (Get-DeviceName 'EarPods')
    $followOutput.Text = T 'Follow'
    $showItem.Text = T 'Open'
    $quitItem.Text = T 'Exit'
    $speakerItem.Text = Get-DeviceName 'Speakers'
    $earItem.Text = Get-DeviceName 'EarPods'
    $speakersButton.Text = (Get-DeviceName 'Speakers').ToUpperInvariant()
    $earButton.Text = (Get-DeviceName 'EarPods').ToUpperInvariant()
    $settingsButton.AccessibleName = T 'Settings'
    $settingsTip.SetToolTip($settingsButton,(T 'Settings'))
    if ($script:statusKey -eq 'Result') { $status.Text = Localize-Result $script:rawResult }
    elseif ($script:statusKey -in @('SwitchingStatus','DeviceUnavailable','ActiveStatus')) { $status.Text = (T $script:statusKey) -f (Get-DeviceName $script:statusTarget) }
    else { $status.Text = T $script:statusKey }
    foreach ($indicator in $deviceIndicators.Values) { $indicator.Invalidate() }
}
. "$PSScriptRoot\DeviceSettings.ps1"
. "$PSScriptRoot\SettingsWindow.ps1"
Apply-Language
Apply-Theme
$form.Add_Shown({ Set-ControlTheme $form })

function Begin-Switch([string]$target, [switch]$FromWindows) {
    if ($script:worker) { return }
    $endpoint = Get-ConfiguredEndpoint $target
    if (!$endpoint -or ($endpoint.State -band 1) -eq 0) {
        $script:statusKey = 'DeviceUnavailable'
        $script:statusTarget = $target
        $status.Text = (T 'DeviceUnavailable') -f (Get-DeviceName $target)
        $script:statusExpiresAt = (Get-Date).AddSeconds(8)
        return
    }
    if (!(Test-Path $tool)) {
        [void][System.Windows.Forms.MessageBox]::Show((T 'Missing'), 'Sound Output Fix')
        return
    }
    if (!$FromWindows -and (Get-DefaultAudioTarget) -eq $target) {
        $script:statusKey = 'ActiveStatus'; $script:statusTarget = $target
        $script:statusExpiresAt = $null
        Update-DeviceButtons $target
        Apply-Language
        return
    }
    $script:switchPhase = 'Switching'
    $script:workerTarget = $target
    Remove-Item (Join-Path $root 'switch-phase.txt') -ErrorAction SilentlyContinue
    $script:statusKey = 'Restarting'; $script:statusTarget = $target
    $script:statusExpiresAt = $null
    $status.Text = T 'Restarting'
    Update-DeviceButtons '' $target
    $speakersButton.Enabled = $false
    $earButton.Enabled = $false
    $speakerItem.Enabled = $false
    $earItem.Enabled = $false
    Set-Content (Join-Path $root 'result.txt') 'Comutare in curs...'
    $argsText = '-NoProfile -ExecutionPolicy Bypass -File "' + (Join-Path $root 'Switch.ps1') + '" -Target ' + $target
    if ($script:resumePlayback) { $argsText += ' -ResumePlayback' }
    try {
        $script:worker = Start-Process powershell.exe -ArgumentList $argsText -WindowStyle Hidden -PassThru -ErrorAction Stop
    } catch {
        $speakersButton.Enabled = $true; $earButton.Enabled = $true
        $speakerItem.Enabled = $true; $earItem.Enabled = $true
        Update-DeviceButtons $script:lastOutput
        $status.Text = $_.Exception.Message
        $script:statusExpiresAt = (Get-Date).AddSeconds(8)
    }
}
$speakersButton.Add_Click({ Begin-Switch 'Speakers' })
$earButton.Add_Click({ Begin-Switch 'EarPods' })
$speakerItem.Add_Click({ Begin-Switch 'Speakers' })
$earItem.Add_Click({ Begin-Switch 'EarPods' })
$showItem.Add_Click({ $form.Show(); $form.WindowState = 'Normal'; $form.Activate() })
$tray.Add_DoubleClick({ $form.Show(); $form.WindowState = 'Normal'; $form.Activate() })
$script:exitRequested = $false
$quitItem.Add_Click({ $script:exitRequested = $true; if (!$script:worker) { $form.Close() } else { $script:statusKey = 'Exiting'; $status.Text = T 'Exiting' } })
$form.Add_FormClosing({ param($sender,$eventArgs)
    if (!$script:exitRequested -or $script:worker) { $eventArgs.Cancel = $true; $form.Hide() }
})
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 2000
$timer.Add_Tick({
    try {
        if (!$script:worker -and $script:statusExpiresAt -and (Get-Date) -ge $script:statusExpiresAt) {
            $script:statusExpiresAt = $null
            $script:statusKey = 'Ready'
            $status.Text = T 'Ready'
        }
        if ($script:theme -eq 'system' -and (Resolve-AppTheme) -ne $script:resolvedTheme) { Apply-Theme }
        if (Test-Path (Join-Path $root 'show.flag')) {
            Remove-Item (Join-Path $root 'show.flag') -ErrorAction SilentlyContinue
            $form.Show(); $form.WindowState = 'Normal'; $form.Activate()
        }
        if (Test-Path (Join-Path $root 'stop.flag')) { $script:exitRequested = $true }
        if ($script:worker -and !$script:worker.HasExited) {
            $phasePath = Join-Path $root 'switch-phase.txt'
            if (Test-Path $phasePath) {
                $phase = (Get-Content $phasePath -Raw).Trim()
                if ($phase -in @('Switching','Finishing')) {
                    $script:switchPhase = $phase
                    Update-DeviceButtons '' $script:workerTarget
                    if (!$script:exitRequested) {
                        $script:statusKey = if ($phase -eq 'Finishing') { 'FinishingStatus' } else { 'Restarting' }
                        $status.Text = T $script:statusKey
                    }
                }
            }
        }
        if ($script:worker -and $script:worker.HasExited) {
            $script:statusKey = 'Result'
            $script:rawResult = Get-Content (Join-Path $root 'result.txt') -Raw
            $status.Text = Localize-Result $script:rawResult
            if ($script:rawResult -match '^EROARE:') { $script:statusExpiresAt = (Get-Date).AddSeconds(8) }
            $script:worker.Dispose(); $script:worker = $null
            $speakersButton.Enabled = $true; $earButton.Enabled = $true
            $speakerItem.Enabled = $true; $earItem.Enabled = $true
            # Establish a fresh baseline after changes made by the app: never restart in a loop.
            $script:lastOutput = Get-DefaultAudioTarget
            $script:switchPhase = $null
            Update-DeviceButtons $script:lastOutput
            if ($script:rawResult -match '^OK:' -and $script:lastOutput -eq $script:workerTarget) {
                $script:statusKey = 'ActiveStatus'; $script:statusTarget = $script:workerTarget
                $status.Text = (T 'ActiveStatus') -f (Get-DeviceName $script:workerTarget)
            }
            $script:outputCandidate = $null
        }
        if ($script:exitRequested) { if (!$script:worker) { $form.Close() }; return }
        # The worker owns endpoint changes; defer registry enumeration until it finishes.
        if ($script:worker) { return }
        $endpoint = Get-ConfiguredEndpoint 'EarPods'
        # Disabled by the switching worker still means physically connected.
        $connected = $endpoint -and (($endpoint.State -band 1) -ne 0 -or ($endpoint.State -band 2) -ne 0)
        if ($auto.Checked -and $connected -and !$script:lastConnected) { $script:pendingConnect = $true }
        if (!$connected) { $script:pendingConnect = $false }
        $script:lastConnected = [bool]$connected
        if ($script:pendingConnect -and !$script:worker -and (Test-Path $tool)) {
            $script:pendingConnect = $false
            Begin-Switch 'EarPods'
        }
        if (!$script:worker -and (Test-Path $tool)) {
            $currentOutput = Get-DefaultAudioTarget
            if (!$followOutput.Checked) { Update-DeviceButtons $currentOutput; return }
            if ($null -eq $script:lastOutput) {
                # Starting the watcher alone must not restart Spotify.
                $script:lastOutput = $currentOutput
                Update-DeviceButtons $currentOutput
            } elseif ($currentOutput -eq $script:lastOutput) {
                $script:outputCandidate = $null
                Update-DeviceButtons $currentOutput
            } elseif ($currentOutput -ne $script:outputCandidate) {
                # Require two identical observations, so quick menu changes settle first.
                $script:outputCandidate = $currentOutput
                if ($currentOutput -in @('Speakers','EarPods')) {
                    Update-DeviceButtons '' $currentOutput
                } else { Update-DeviceButtons $currentOutput }
            } else {
                $script:lastOutput = $currentOutput
                $script:outputCandidate = $null
                if ($currentOutput -in @('Speakers','EarPods')) { Begin-Switch $currentOutput -FromWindows }
            }
        }
    } catch { $status.Text = $_.Exception.Message }
})
try {
    if ($SmokeTest) {
        . "$PSScriptRoot\SmokeTest.ps1"

    }
    else { $timer.Start(); if ($launchInTray) { $context = New-Object System.Windows.Forms.ApplicationContext; $form.Add_FormClosed({ $context.ExitThread() }); try { [System.Windows.Forms.Application]::Run($context) } finally { $context.Dispose() } } else { [System.Windows.Forms.Application]::Run($form) } }
}
finally {
    foreach ($button in @($speakersButton,$earButton)) {
        if ($button.BackgroundImage) { $button.BackgroundImage.Dispose(); $button.BackgroundImage = $null }
    }
    $form.Dispose()
    $script:audioButtonFont.Dispose()
    $script:indicatorFont.Dispose()
    $settingsTip.Dispose()
    $animationTimer.Stop(); $animationTimer.Dispose()
    $timer.Stop(); $timer.Dispose()
    $tray.Visible = $false; $tray.Dispose()
    if ($appIcon) { $appIcon.Dispose() }
    if ($titleIcon) { $titleIcon.Dispose() }
    $mutex.ReleaseMutex(); $mutex.Dispose()
}
