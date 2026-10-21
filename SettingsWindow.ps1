$settingsButton.Add_Click({
    $dialog = New-Object System.Windows.Forms.Form
    $dialog.Font = $form.Font
    $dialog.Text = T 'Settings'
    $dialog.ClientSize = New-Object System.Drawing.Size(530,520)
    $dialog.FormBorderStyle = 'FixedDialog'
    $dialog.StartPosition = 'CenterParent'
    $dialog.MaximizeBox = $false; $dialog.MinimizeBox = $false
    $dialog.ShowInTaskbar = $false
    if ($titleIcon) { $dialog.Icon = $titleIcon }
    $tabs = New-Object ModernSettingsTabs
    $tabs.SetBounds(12,12,506,450)
    $generalTab = New-Object System.Windows.Forms.Panel
    $generalTab.Text = T 'General'
    $devicesTab = New-Object System.Windows.Forms.Panel
    $devicesTab.Text = T 'Devices'
    $tabs.TabPages.AddRange(@($generalTab,$devicesTab))
    $dialog.Controls.Add($tabs)
    $languageLabel = New-Object System.Windows.Forms.Label
    $languageLabel.SetBounds(20,20,90,24)
    $languageLabel.Text = T 'Language'
    $languageChoice = New-Object SoftComboBox
    $languageChoice.DropDownStyle = 'DropDownList'
    $languageChoice.SetBounds(130,18,300,32)
    [void]$languageChoice.Items.Add('English')
    [void]$languageChoice.Items.Add(('Rom' + [char]0x00E2 + 'n' + [char]0x0103))
    [void]$languageChoice.Items.Add('Русский')
    [void]$languageChoice.Items.Add('简体中文')
    $languageChoice.SelectedIndex = @('en','ro','ru','zh-CN').IndexOf($script:language)
    $closeButton = New-Object SoftButton
    $closeButton.SetBounds(420,478,90,30)
    $closeButton.Text = T 'Close'
    $closeButton.Add_Click({ $dialog.Close() })
    $creditLabel = New-Object System.Windows.Forms.Label
    $creditLabel.SetBounds(24,478,260,30)
    $creditLabel.Text = 'Saiprien MMXXVI · v' + $script:appVersion
    $creditLabel.TextAlign = 'MiddleLeft'
    $creditLabel.Tag = 'CreatorCredit'
    $creditFont = New-Object System.Drawing.Font($script:uiFont,9,[System.Drawing.FontStyle]::Italic)
    $creditLabel.Font = $creditFont
    $dialog.Controls.Add($creditLabel)
    $startupLabel = New-Object System.Windows.Forms.Label
    $startupLabel.SetBounds(20,68,290,28)
    $startupLabel.Text = T 'Startup'
    $startupToggle = New-Object StartupSwitch
    $startupToggle.TextAlign = 'MiddleCenter'
    $startupToggle.SetBounds(325,64,110,32)
    $startupToggle.Checked = Get-StartupEnabled
    $startupToggle.Text = if ($startupToggle.Checked) { T 'On' } else { T 'Off' }
    $startupToggle.AccessibleName = T 'Startup'
    $startupToggle.Add_CheckedChanged({
        if ($script:updatingStartupToggle) { return }
        try { Set-StartupEnabled $startupToggle.Checked }
        catch {
            $script:updatingStartupToggle = $true
            try { $startupToggle.Checked = Get-StartupEnabled } finally { $script:updatingStartupToggle = $false }
            [void][System.Windows.Forms.MessageBox]::Show($_.Exception.Message,(T 'Settings'))
        }
        $startupToggle.Text = if ($startupToggle.Checked) { T 'On' } else { T 'Off' }
    })
    $trayChoice = New-Object System.Windows.Forms.CheckBox
    $trayChoice.SetBounds(20,104,470,38)
    $trayChoice.Text = T 'StartMinimized'
    $trayChoice.Checked = $script:startMinimized
    $trayChoice.Enabled = $startupToggle.Checked
    $trayChoice.Add_CheckedChanged({
        $script:startMinimized = $trayChoice.Checked
        try { Save-AppSettings } catch { [void][System.Windows.Forms.MessageBox]::Show($_.Exception.Message,(T 'Settings')) }
    })
    $generalTab.Controls.Add($trayChoice)
    $startupToggle.Add_CheckedChanged({ $trayChoice.Enabled = $startupToggle.Checked })
    $themeLabel = New-Object System.Windows.Forms.Label
    $themeLabel.SetBounds(20,155,90,24)
    $themeLabel.Text = T 'Theme'
    $themeChoice = New-Object SoftComboBox
    $themeChoice.DropDownStyle = 'DropDownList'
    $themeChoice.SetBounds(130,152,300,32)
    foreach ($key in @('Light','Dark','System')) { [void]$themeChoice.Items.Add((T $key)) }
    $themeChoice.SelectedIndex = @('light','dark','system').IndexOf($script:theme)
    $resumeChoice = New-Object System.Windows.Forms.CheckBox
    $resumeChoice.SetBounds(20,202,470,38)
    $resumeChoice.Text = T 'ResumePlayback'
    $resumeChoice.Checked = $script:resumePlayback
    $resumeChoice.Add_CheckedChanged({
        $previous = $script:resumePlayback
        $script:resumePlayback = $resumeChoice.Checked
        try { Save-AppSettings } catch {
            $script:resumePlayback = $previous
            [void][System.Windows.Forms.MessageBox]::Show($_.Exception.Message,(T 'Settings'))
        }
    })
    $generalTab.Controls.Add($resumeChoice)
    $resumeHint = New-Object System.Windows.Forms.Label
    $resumeHint.SetBounds(40,237,450,38)
    $resumeHint.Tag = 'SecondaryText'
    $resumeHint.Text = T 'ResumePlaybackHint'
    $generalTab.Controls.Add($resumeHint)
    $themeChoice.Add_SelectedIndexChanged({
        if ($script:refreshingThemeChoice) { return }
        $script:theme = @('light','dark','system')[$themeChoice.SelectedIndex]
        try { Save-AppSettings } catch { [void][System.Windows.Forms.MessageBox]::Show($_.Exception.Message,(T 'Settings')) }
        Apply-Theme
        Set-ControlTheme $dialog
    })
    $languageChoice.Add_SelectedIndexChanged({
        $script:language = @('en','ro','ru','zh-CN')[$languageChoice.SelectedIndex]
        try {
            Save-AppSettings
        } catch {
            [void][System.Windows.Forms.MessageBox]::Show($_.Exception.Message,(T 'Settings'))
        }
        Apply-Language
        $dialog.Text = T 'Settings'
        $generalTab.Text = T 'General'; $devicesTab.Text = T 'Devices'
        $languageLabel.Text = T 'Language'
        $trayChoice.Text = T 'StartMinimized'
        $resumeChoice.Text = T 'ResumePlayback'
        $resumeHint.Text = T 'ResumePlaybackHint'
        $closeButton.Text = T 'Close'
        $themeLabel.Text = T 'Theme'
        $script:refreshingThemeChoice = $true
        try {
            $themeChoice.Items.Clear()
            foreach ($key in @('Light','Dark','System')) { [void]$themeChoice.Items.Add((T $key)) }
            $themeChoice.SelectedIndex = @('light','dark','system').IndexOf($script:theme)
        } finally { $script:refreshingThemeChoice = $false }
        $startupLabel.Text = T 'Startup'
        $startupToggle.AccessibleName = T 'Startup'
        $startupToggle.Text = if ($startupToggle.Checked) { T 'On' } else { T 'Off' }
        $draft = Get-DeviceSettingsDraft
        foreach ($editor in $script:deviceEditors.Values) { if ($editor.preview.Image) { $editor.preview.Image.Dispose(); $editor.preview.Image = $null } }
        foreach ($control in @($devicesTab.Controls)) { $control.Dispose() }
        $devicesTab.Controls.Clear()
        Initialize-DeviceSettings $devicesTab $draft
        Set-ControlTheme $dialog
    })
    $generalTab.Controls.AddRange(@($languageLabel,$languageChoice,$startupLabel,$startupToggle,$themeLabel,$themeChoice))
    $dialog.Controls.Add($closeButton)
    Initialize-DeviceSettings $devicesTab
    $dialog.AcceptButton = $closeButton; $dialog.CancelButton = $closeButton
    Set-ControlTheme $dialog
    $dialog.Add_Shown({ Set-ControlTheme $dialog })
    try { [void]$dialog.ShowDialog($form) } finally {
        foreach ($editor in $script:deviceEditors.Values) { if ($editor.preview.Image) { $editor.preview.Image.Dispose(); $editor.preview.Image = $null } }
        $dialog.Dispose()
        $creditFont.Dispose()
    }
})
