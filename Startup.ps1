function Get-StartupShortcutPath {
    Join-Path ([Environment]::GetFolderPath('Startup')) 'EarPods Spotify Auto.lnk'
}
function Get-StartupEnabled {
    if (!(Test-Path -LiteralPath (Get-StartupShortcutPath))) { return $false }
    $approvalPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder'
    $approval = $null
    try {
        $approval = Get-ItemPropertyValue -LiteralPath $approvalPath -Name 'EarPods Spotify Auto.lnk' -ErrorAction Stop
    } catch {
        # Windows may not have recorded this shortcut yet; missing means no disabled override.
    }
    # Windows records disabled startup entries with state 3 (or 7).
    return !($approval -and $approval[0] -in @(3,7))
}
function Set-StartupEnabled([bool]$enabled, [string]$shortcutPath = (Get-StartupShortcutPath)) {
    if (!$enabled) {
        if (Test-Path -LiteralPath $shortcutPath) { Remove-Item -LiteralPath $shortcutPath -Force -ErrorAction Stop }
        return
    }
    $launcher = Join-Path $root 'Launch.ps1'
    if (!(Test-Path -LiteralPath $launcher)) { throw 'Launch.ps1 is missing.' }
    $shell = New-Object -ComObject WScript.Shell
    try {
        $shortcut = $shell.CreateShortcut($shortcutPath)
        try {
            $shortcut.TargetPath = Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'
            $shortcut.Arguments = '-STA -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "' + $launcher + '" -StartAtLogin'
            $executablePath = Join-Path $root 'SoundOutputFix.exe'
            if (Test-Path -LiteralPath $executablePath) {
                $shortcut.TargetPath = $executablePath
                $shortcut.Arguments = '--startup'
            }
            $shortcut.WindowStyle = 7
            $shortcut.WorkingDirectory = $root
            $iconPath = Join-Path $root 'assets\user-app-icon.ico'
            if (Test-Path $iconPath) { $shortcut.IconLocation = $iconPath + ',0' }
            $shortcut.Save()
            if ($shortcutPath -eq (Get-StartupShortcutPath)) {
                $approvalPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder'
                if (Test-Path -LiteralPath $approvalPath) {
                    Remove-ItemProperty -LiteralPath $approvalPath -Name 'EarPods Spotify Auto.lnk' -ErrorAction SilentlyContinue
                }
            }
        } finally { if ($shortcut) { [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($shortcut) } }
    } finally { [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($shell) }
}
