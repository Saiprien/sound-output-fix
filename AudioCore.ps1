$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$tool = Join-Path $root 'WindowsAudio.cs'
$audioLibrary = Join-Path $root 'WindowsAudio.dll'
function Test-BlockedAssembly($errorRecord) {
    $exception = $errorRecord.Exception
    while ($exception) {
        if ($exception.HResult -eq -2146233067 -or $exception.Message -match '0x80131515') { return $true }
        $exception = $exception.InnerException
    }
    return $false
}
if (Test-Path $audioLibrary) {
    try { Add-Type -Path $audioLibrary -ErrorAction Stop }
    catch {
        if (!(Test-BlockedAssembly $_)) { throw }
        # Internet-marked DLLs can be blocked by .NET Framework. Compile the bundled source instead.
        Add-Type -Path $tool -ErrorAction Stop
    }
} else { Add-Type -Path $tool }
$audioRoot = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render'
. "$PSScriptRoot\DeviceConfig.ps1"
function Find-Endpoint($label, $driver) {
    $matches = @(Get-ChildItem $audioRoot | ForEach-Object {
        $props = Get-ItemProperty ($_.PSPath + '\Properties')
        if ($props.'{a45c254e-df1c-4efd-8020-67d146a850e0},2' -eq $label -and
            $props.'{b3f8fa53-0004-438e-9003-51a46e139bfc},6' -eq $driver) {
            [pscustomobject]@{Key=$_.PSPath; Id=('{0.0.0.00000000}.' + $_.PSChildName); State=[int](Get-ItemProperty $_.PSPath).DeviceState}
        }
    })
    $active = @($matches | Where-Object {($_.State -band 1) -ne 0})
    if ($active.Count -eq 1) { return $active[0] }
    if ($matches.Count -eq 1) { return $matches[0] }
    return $null
}
function Log($message) { Add-Content (Join-Path $root 'monitor.log') ('{0:u} {1}' -f (Get-Date), $message) }
function Audio-Command($verb, $id, $role) {
    switch ($verb) {
        '/SetDefault' { [WindowsAudio]::SetDefault($id) }
        '/Disable' { [WindowsAudio]::SetEnabled($id,$false) }
        '/Enable' { [WindowsAudio]::SetEnabled($id,$true) }
        default { throw ('Unsupported audio command: ' + $verb) }
    }
    Log "$verb $id : Windows Core Audio"
}
function Get-AudioState($id) {
    $state = [WindowsAudio]::GetState($id)
    if (($state -band 1) -ne 0) { return 'Active' }
    if (($state -band 2) -ne 0) { return 'Disabled' }
    if (($state -band 8) -ne 0) { return 'Unplugged' }
    return 'Not Present'
}
function Wait-AudioState($id, $expected) {
    for ($poll = 0; $poll -lt 12; $poll++) {
        if ((Get-AudioState $id) -eq $expected) { return $true }
        Start-Sleep -Milliseconds 250
    }
    return $false
}
function Convert-DefaultAudioTarget($lines) {
    foreach ($slot in @('Speakers','EarPods')) {
        $endpoint = Get-ConfiguredEndpoint $slot
        if ($endpoint) {
            foreach ($line in $lines) {
                if (([string]$line).Trim() -in @($endpoint.Id,$endpoint.FriendlyId)) { return $slot }
            }
        }
    }
    return 'Other'
}
function Get-DefaultAudioTarget {
    return Convert-DefaultAudioTarget @([WindowsAudio]::GetDefaultId())
}
