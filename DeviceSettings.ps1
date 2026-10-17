function Update-AudioChoices($editor, [bool]$showDisconnected) {
    $id = if ($editor.audio.SelectedItem) { $editor.audio.SelectedItem.Id } else { $script:deviceConfig[$editor.slot].endpointId }
    if (!$id) {
        $default = Get-ConfiguredEndpoint $editor.slot
        if ($default) {
            $match = $script:settingsEndpoints | Where-Object { $_.Key -eq $default.Key } | Select-Object -First 1
            if ($match) { $id = $match.Id }
        }
    }
    $editor.audio.Items.Clear()
    $selectedIndex = -1
    foreach ($endpoint in $script:settingsEndpoints) {
        if (!$showDisconnected -and ($endpoint.State -band 1) -eq 0 -and $endpoint.Id -ne $id) { continue }
        $name = $endpoint.Name
        if (($endpoint.State -band 1) -eq 0) { $name += ' (' + (T 'Disconnected') + ')' }
        $index = $editor.audio.Items.Add([pscustomobject]@{Name=$name; Id=$endpoint.Id})
        if ($endpoint.Id -eq $id) { $selectedIndex = $index }
    }
    if ($selectedIndex -lt 0) {
        $label = if ($id) { (Get-DeviceName $editor.slot) + ' (' + (T 'Disconnected') + ')' } else { T 'NoDevice' }
        $selectedIndex = $editor.audio.Items.Add([pscustomobject]@{Name=$label; Id=$id})
    }
    $editor.audio.SelectedIndex = $selectedIndex
}
function Refresh-DeviceThumbnail($editor) {
    $path = if ($editor.image) { Join-Path $root $editor.image } else {
        Get-DefaultDeviceImage $editor.slot
    }
    if (Test-Path $path) {
        $source = [System.Drawing.Image]::FromFile($path)
        try { $copy = New-Object System.Drawing.Bitmap($source) } finally { $source.Dispose() }
        $old = $editor.preview.Image
        $editor.preview.Image = $copy
        if ($old) { $old.Dispose() }
    }
}
function Get-DeviceSettingsDraft {
    $draft = @{}
    foreach ($slot in @('Speakers','EarPods')) {
        $editor = $script:deviceEditors[$slot]
        $draft[$slot] = @{nameMode=[string]$editor.mode.SelectedItem.Key; customName=$editor.custom.Text; endpointId=$editor.audio.SelectedItem.Id; image=$editor.image}
    }
    return $draft
}
function Initialize-DeviceSettings($page, $draft = $null) {
    $script:deviceEditors = @{}
    $script:settingsEndpoints = @(Get-RenderEndpoints)
    $showDisconnected = New-Object System.Windows.Forms.CheckBox
    $showDisconnected.Text = T 'ShowDisconnected'
    $showDisconnected.SetBounds(14,365,315,30)
    $showDisconnected.Add_CheckedChanged({ param($sender,$e)
        foreach ($editor in $script:deviceEditors.Values) { Update-AudioChoices $editor $sender.Checked }
    })
    $page.Controls.Add($showDisconnected)
    $row = 0
    foreach ($slot in @('Speakers','EarPods')) {
        $current = if ($draft) { $draft[$slot] } else { $script:deviceConfig[$slot] }
        $box = New-Object ModernDeviceGroup
        $box.Text = (Get-DeviceName $slot)
        $box.SetBounds(12,(12+$row*174),468,164)
        $label = New-Object System.Windows.Forms.Label
        $label.Text = T 'Name'; $label.SetBounds(12,24,100,24)
        $mode = New-Object SoftComboBox
        $mode.DropDownStyle = 'DropDownList'; $mode.SetBounds(116,22,142,25)
        $mode.DisplayMember = 'Label'
        foreach ($name in @('Speakers','EarPods','Headphones','Custom')) {
            $labelKey = switch ($name) { 'Speakers' { 'SpeakersNormal' }; 'Headphones' { 'HeadphonesNormal' }; default { $name } }
            $presetLabel = if ($name -eq 'EarPods') { 'EarPods' } else { T $labelKey }
            $index = $mode.Items.Add([pscustomobject]@{Key=$name; Label=$presetLabel})
            if ($name -eq $current.nameMode) { $mode.SelectedIndex = $index }
        }
        $custom = New-Object System.Windows.Forms.TextBox
        $custom.SetBounds(270,22,180,25); $custom.MaxLength = 24
        $custom.Text = $current.customName
        $custom.Enabled = $mode.SelectedItem.Key -eq 'Custom'
        $mode.Tag = $slot
        $mode.Add_SelectedIndexChanged({ param($sender,$e)
            $script:deviceEditors[$sender.Tag].custom.Enabled = $sender.SelectedItem.Key -eq 'Custom'
        })
        $audioLabel = New-Object System.Windows.Forms.Label
        $audioLabel.Text = T 'AudioDevice'; $audioLabel.SetBounds(12,58,100,24)
        $audio = New-Object SoftComboBox
        $audio.DropDownStyle = 'DropDownList'; $audio.SetBounds(116,56,334,25)
        $audio.DisplayMember = 'Name'
        $preview = New-Object System.Windows.Forms.PictureBox
        $preview.SetBounds(116,91,65,60); $preview.SizeMode = 'Zoom'
        $choose = New-Object SoftButton
        $choose.Text = T 'Choose'; $choose.SetBounds(194,106,120,30); $choose.Tag = $slot
        $reset = New-Object SoftButton
        $reset.Text = T 'Reset'; $reset.SetBounds(328,106,122,30); $reset.Tag = $slot
        $editor = @{slot=$slot; mode=$mode; custom=$custom; audio=$audio; preview=$preview; image=$current.image}
        if ($current.endpointId) {
            [void]$audio.Items.Add([pscustomobject]@{Name=$current.endpointId; Id=$current.endpointId})
            $audio.SelectedIndex = 0
        }
        $script:deviceEditors[$slot] = $editor
        Update-AudioChoices $editor $false
        Refresh-DeviceThumbnail $editor
        $choose.Add_Click({ param($sender,$e)
            $picker = New-Object System.Windows.Forms.OpenFileDialog
            $picker.Filter = 'Images (*.png;*.jpg;*.jpeg)|*.png;*.jpg;*.jpeg'
            try {
                if ($picker.ShowDialog($dialog) -ne 'OK') { return }
                $source = [System.Drawing.Image]::FromFile($picker.FileName)
                try {
                    $destination = Join-Path $root 'assets\custom'
                    [void][System.IO.Directory]::CreateDirectory($destination)
                    $relative = 'assets\custom\' + [Guid]::NewGuid().ToString('N') + '.png'
                    $source.Save((Join-Path $root $relative),[System.Drawing.Imaging.ImageFormat]::Png)
                } finally { $source.Dispose() }
                $editor = $script:deviceEditors[$sender.Tag]
                $editor.image = $relative
                Refresh-DeviceThumbnail $editor
            } catch { [void][System.Windows.Forms.MessageBox]::Show($_.Exception.Message,(T 'Settings')) }
            finally { $picker.Dispose() }
        })
        $reset.Add_Click({ param($sender,$e)
            $editor = $script:deviceEditors[$sender.Tag]; $editor.image = ''; Refresh-DeviceThumbnail $editor
        })
        $box.Controls.AddRange(@($label,$mode,$custom,$audioLabel,$audio,$preview,$choose,$reset))
        $page.Controls.Add($box)
        $row++
    }
    $apply = New-Object SoftButton
    $apply.Text = T 'Apply'; $apply.SetBounds(350,370,130,30)
    $apply.Add_Click({
        if ($script:worker) { [void][System.Windows.Forms.MessageBox]::Show((T 'Busy')); return }
        $next = @{}
        foreach ($slot in @('Speakers','EarPods')) {
            $editor = $script:deviceEditors[$slot]
            if ($editor.mode.SelectedItem.Key -eq 'Custom' -and !$editor.custom.Text.Trim()) {
                [void][System.Windows.Forms.MessageBox]::Show((T 'EmptyName')); return
            }
            $next[$slot] = @{nameMode=[string]$editor.mode.SelectedItem.Key; customName=$editor.custom.Text.Trim(); endpointId=$editor.audio.SelectedItem.Id; image=$editor.image}
        }
        $previous = $script:deviceConfig
        $script:deviceConfig = $next
        try {
            $first = Get-ConfiguredEndpoint 'Speakers'; $second = Get-ConfiguredEndpoint 'EarPods'
            if ($first -and $second -and $first.Key -eq $second.Key) { throw (T 'SameDevice') }
            Save-AppSettings
        } catch {
            $script:deviceConfig = $previous
            [void][System.Windows.Forms.MessageBox]::Show($_.Exception.Message,(T 'Settings')); return
        }
        $script:lastOutput = $null; $script:outputCandidate = $null
        $script:lastConnected = $true; $script:pendingConnect = $false
        Apply-Language; Apply-Theme
        $script:statusKey = 'Ready'; $status.Text = T 'Ready'
    })
    $page.Controls.Add($apply)
}
