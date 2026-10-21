param([switch]$StartInTray, [switch]$StartAtLogin)
$ErrorActionPreference = 'Stop'
try {
    & "$PSScriptRoot\App.ps1" -StartInTray:$StartInTray -StartAtLogin:$StartAtLogin
} catch {
    $_ | Out-String | Set-Content (Join-Path $PSScriptRoot 'launch-error.txt')
    Add-Type -AssemblyName System.Windows.Forms
    [void][System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Sound Output Fix - eroare')
}
