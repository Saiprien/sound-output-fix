param([ValidateSet('Speakers','EarPods')][string]$Target, [switch]$Check)
. "$PSScriptRoot\AudioCore.ps1"
$ear = Get-ConfiguredEndpoint 'EarPods'
$speaker = Get-ConfiguredEndpoint 'Speakers'
if ($Target -eq 'EarPods') { $selected = $ear; $other = $speaker } else { $selected = $speaker; $other = $ear }
if ($Check) {
    if (!$selected) { throw "Dispozitivul $Target nu a fost identificat univoc." }
    $selected | Format-List; return
}
$result = Join-Path $root 'result.txt'
function Publish-SwitchPhase([string]$phase) {
    $path = Join-Path $root 'switch-phase.txt'
    $temporary = $path + '.tmp'
    [System.IO.File]::WriteAllText($temporary,$phase)
    if ([System.IO.File]::Exists($path)) {
        # PowerShell can marshal $null as an empty backup filename; use an explicit path.
        $backup = $path + '.bak'
        [System.IO.File]::Replace($temporary,$path,$backup)
        [System.IO.File]::Delete($backup)
    }
    else { [System.IO.File]::Move($temporary,$path) }
}
$restore = $false
if ($selected -and $other -and $selected.Key -eq $other.Key) { $other = $null }
try {
    Publish-SwitchPhase 'Switching'
    if (!$selected) { throw "Dispozitivul $Target nu a fost identificat univoc." }
    if (($selected.State -band 1) -eq 0) { throw "Dispozitivul $Target nu este activ. Conecteaza-l / activeaza-l." }
    if ((Get-AudioState $selected.Id) -ne 'Active') { throw "Dispozitivul $Target nu este activ. Conecteaza-l / activeaza-l." }
    $spotify = @(Get-Process Spotify -ErrorAction SilentlyContinue)
    $spotifyPath = $spotify | ForEach-Object { try { $_.Path } catch {} } | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
    Audio-Command '/SetDefault' $selected.Id 'all'
    if ($spotify.Count -gt 0) {
        $spotify | Stop-Process -Force
        $deadline = (Get-Date).AddSeconds(10)
        while ((Get-Process Spotify -ErrorAction SilentlyContinue) -and (Get-Date) -lt $deadline) { Start-Sleep -Milliseconds 250 }
        if (Get-Process Spotify -ErrorAction SilentlyContinue) { throw 'Spotify nu s-a inchis complet.' }
        if ($other -and (Get-AudioState $other.Id) -eq 'Active') {
            $restore = $true
            Audio-Command '/Disable' $other.Id
            if (!(Wait-AudioState $other.Id 'Disabled')) { throw ('Dezactivarea a esuat pentru ' + $other.Id + '. Detalii in monitor.log.') }
        }
        Audio-Command '/SetDefault' $selected.Id 'all'
        if ($spotifyPath -and $spotifyPath -notlike '*\WindowsApps\*') { Start-Process -FilePath $spotifyPath }
        else { Start-Process 'spotify:' }
        $deadline = (Get-Date).AddSeconds(20)
        while (!(Get-Process Spotify -ErrorAction SilentlyContinue) -and (Get-Date) -lt $deadline) { Start-Sleep -Seconds 1 }
        if (!(Get-Process Spotify -ErrorAction SilentlyContinue)) { throw 'Spotify nu a pornit.' }
        Publish-SwitchPhase 'Finishing'
        Start-Sleep -Seconds 4
    }
    Set-Content $result "OK: $Target. Apasa Play daca melodia este oprita."
    Log "Comutare la $Target. Spotify deschis: $($spotify.Count -gt 0)."
} catch {
    Set-Content $result ('EROARE: ' + $_.Exception.Message)
    Log $_.Exception.Message
} finally {
    if ($restore) {
        $restored = $false
        for ($attempt = 0; $attempt -lt 3; $attempt++) {
            try {
                Audio-Command '/Enable' $other.Id
                if (Wait-AudioState $other.Id 'Active') { $restored = $true; break }
            } catch { Log ('Restore attempt failed: ' + $_.Exception.Message) }
        }
        if (!$restored) {
            Set-Content $result 'EROARE: reactiveaza manual cealalta iesire din mmsys.cpl.'
        }
    }
}
