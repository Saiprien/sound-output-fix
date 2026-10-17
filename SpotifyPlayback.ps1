# Optional Windows media-session integration. Fail closed when state is unavailable.
function Wait-MediaOperation($operation, [type]$resultType) {
    $adapter = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
        $_.Name -eq 'AsTask' -and $_.IsGenericMethodDefinition -and
        $_.GetGenericArguments().Count -eq 1 -and $_.GetParameters().Count -eq 1 -and
        $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1'
    } | Select-Object -First 1
    $task = $adapter.MakeGenericMethod($resultType).Invoke($null,@($operation))
    if (!$task.Wait(750)) { $operation.Cancel(); throw 'Media-session request timed out.' }
    return $task.GetAwaiter().GetResult()
}
function Get-SpotifyMediaSession($manager) {
    $sessions = @($manager.GetSessions() | Where-Object {
        $_.SourceAppUserModelId -match '^(Spotify(?:\.exe)?|SpotifyAB\.SpotifyMusic_[^!]+!Spotify)$'
    })
    # Ambiguous sessions must never cause an unsolicited Play request.
    if ($sessions.Count -eq 1) { return $sessions[0] }
    return $null
}
function Get-SpotifyPlaybackSnapshot {
    try {
        Add-Type -AssemblyName System.Runtime.WindowsRuntime
        $type = [Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager,Windows.Media.Control,ContentType=WindowsRuntime]
        $manager = Wait-MediaOperation ($type::RequestAsync()) $type
        $session = Get-SpotifyMediaSession $manager
        if (!$session) { return $null }
        return [pscustomobject]@{
            Manager = $manager
            AppId = $session.SourceAppUserModelId
            WasPlaying = ($session.GetPlaybackInfo().PlaybackStatus.ToString() -eq 'Playing')
        }
    } catch { Log ('Playback state unavailable; automatic resume skipped: ' + $_.Exception.Message); return $null }
}
function Resume-SpotifyPlayback($snapshot) {
    if (!$snapshot -or !$snapshot.WasPlaying) { return $true }
    try {
        $session = Get-SpotifyMediaSession $snapshot.Manager
        if (!$session -or $session.SourceAppUserModelId -ne $snapshot.AppId) { return $false }
        $info = $session.GetPlaybackInfo()
        $state = $info.PlaybackStatus.ToString()
        if ($state -eq 'Playing') { return $true }
        if ($state -ne 'Paused' -or !$info.Controls.IsPlayEnabled) { return $false }
        # Play is idempotent; never send a global Play/Pause toggle or target another app.
        $accepted = Wait-MediaOperation ($session.TryPlayAsync()) ([bool])
        Log ('Spotify resume request accepted: ' + $accepted)
        return $true # At most one request, even when Spotify rejects it.
    } catch { Log ('Automatic resume skipped: ' + $_.Exception.Message); return $true }
}
