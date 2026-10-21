function Resolve-AppTheme {
    if ($script:theme -ne 'system') { return $script:theme }
    try {
        $value = Get-ItemPropertyValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'AppsUseLightTheme' -ErrorAction Stop
        if ($value -eq 0) { return 'dark' }
    } catch { }
    return 'light'
}
function Theme-Color([string]$hex) { [System.Drawing.ColorTranslator]::FromHtml($hex) }
function Set-ControlTheme($container) {
    $container.BackColor = $script:palette.Background
    $container.ForeColor = $script:palette.Text
    if ($container -is [ModernSettingsTabs] -or $container -is [ModernDeviceGroup]) {
        $container.BorderColor = $script:palette.Border
        $container.Invalidate()
    }
    foreach ($control in $container.Controls) {
        $control.ForeColor = $script:palette.Text
        if ($control.Tag -eq 'SecondaryText') {
            $control.ForeColor = if ($script:resolvedTheme -eq 'dark') { Theme-Color '#ACACAC' } else { Theme-Color '#686868' }
        } elseif ($control.Tag -eq 'CreatorCredit') {
            $control.ForeColor = if ($script:resolvedTheme -eq 'dark') { Theme-Color '#888888' } else { Theme-Color '#707070' }
        }
        $control.BackColor = $script:palette.Background
        if ($control -is [System.Windows.Forms.Button] -or ($control -is [System.Windows.Forms.CheckBox] -and $control.Appearance -eq 'Button')) {
            $control.UseVisualStyleBackColor = $false
            $control.FlatStyle = 'Flat'
            $control.BackColor = $script:palette.Button
            $control.FlatAppearance.BorderColor = $script:palette.Border
        } elseif ($control -is [System.Windows.Forms.TextBox]) {
            $control.BackColor = $script:palette.Button
            $control.BorderStyle = 'FixedSingle'
        } elseif ($control -is [System.Windows.Forms.ComboBox]) {
            $control.FlatStyle = 'Flat'
            $control.BackColor = $script:palette.Button
        }
    }
    foreach ($child in $container.Controls) { if ($child.HasChildren) { Set-ControlTheme $child } }
    if ($container -is [System.Windows.Forms.Form] -and $container.IsHandleCreated) {
        $darkTitle = if ($script:resolvedTheme -eq 'dark') { 1 } else { 0 }
        [void][AudioAppIdentity]::DwmSetWindowAttribute($container.Handle,20,[ref]$darkTitle,4)
        $container.Icon = if ($darkTitle -and $appIcon) { $appIcon } else { $titleIcon }
        if ($appIcon) { [void][AudioAppIdentity]::SendMessage($container.Handle,0x80,[IntPtr]1,$appIcon.Handle) }
        if ($container.Icon) { [void][AudioAppIdentity]::SendMessage($container.Handle,0x80,[IntPtr]::Zero,$container.Icon.Handle) }
    }
}
function Apply-Theme {
    $script:resolvedTheme = Resolve-AppTheme
    $colors = if ($script:resolvedTheme -eq 'dark') {
        @('#181818','#282828','#EFEFEF','#484848','#75BA8C','#D9B45B')
    } else { @('#F5F5F5','#FFFFFF','#252525','#C8C8C8','#42855A','#A77916') }
    $script:palette = @{Background=(Theme-Color $colors[0]); Button=(Theme-Color $colors[1]); Text=(Theme-Color $colors[2]); Border=(Theme-Color $colors[3]); Active=(Theme-Color $colors[4]); Switching=(Theme-Color $colors[5])}
    Set-ControlTheme $form
    Set-ButtonPhoto $speakersButton (Get-DeviceImage 'Speakers')
    Set-ButtonPhoto $earButton (Get-DeviceImage 'EarPods')
    $status.ForeColor = if ($script:resolvedTheme -eq 'dark') { Theme-Color '#ACACAC' } else { Theme-Color '#686868' }
    $status.Font = $script:indicatorFont
    $settingsButton.FlatAppearance.BorderSize = 0
    $settingsButton.BackColor = $script:palette.Button
    $menu.BackColor = $script:palette.Button
    $menu.ForeColor = $script:palette.Text
    $trayRenderer = New-Object ThemedTrayRenderer
    $trayRenderer.CheckColor = $script:palette.Text
    $menu.Renderer = $trayRenderer
    foreach ($item in $menu.Items) { $item.BackColor = $script:palette.Button; $item.ForeColor = $script:palette.Text }
    foreach ($indicator in $deviceIndicators.Values) { $indicator.Invalidate() }
    Update-DeviceButtons $script:displayActive $script:displaySwitching
}
function Save-AppSettings {
    @{language=$script:language; theme=$script:theme; resumePlayback=$script:resumePlayback; startMinimized=$script:startMinimized; devices=$script:deviceConfig} | ConvertTo-Json -Depth 5 | Set-Content $script:settingsPath -Encoding UTF8 -ErrorAction Stop
}
