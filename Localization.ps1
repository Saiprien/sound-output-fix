$script:language = 'en'
$script:theme = 'system'
$script:settingsPath = Join-Path $root 'settings.json'
if (Test-Path $script:settingsPath) {
    try {
        $saved = Get-Content $script:settingsPath -Raw | ConvertFrom-Json
        if ($saved.theme -in @('light','dark','system')) { $script:theme = $saved.theme }
        if ($saved.language -in @('en','ro')) { $script:language = $saved.language }
    } catch { }
}
$script:translations = @{
    en = @{
        HeadphonesNormal = 'Headphones'
        Finishing = 'Finishing'; Restarting = 'Restarting Spotify…'; FinishingStatus = 'Spotify is open. Restoring other output…'; ActiveStatus = '{0} is active.'
        DeviceUnavailable = '{0} is disconnected or disabled. Connect or enable it first.'
        SpeakersNormal = 'Speakers'
        ShowDisconnected='Show disconnected devices'; Disconnected='disconnected'; NoDevice='No device selected'
        General='General'; Devices='Devices'; Name='Display name'; AudioDevice='Audio device'; Custom='Custom'; Choose='Choose...'; Reset='Reset'; Apply='Apply'; DefaultDevice='Original device'; AutoDevice='Switch automatically when {0} connects'; SameDevice='Choose different audio devices for the two buttons.'; EmptyName='Enter a custom name (up to 24 characters).'; Busy='Wait for switching to finish before applying device settings.'
        Theme = 'Theme'; Light = 'Light'; Dark = 'Dark'; System = 'System'
        Startup = 'Start with Windows'; On = 'On'; Off = 'Off'
        Auto = 'Switch automatically when EarPods connect'
        Follow = 'Follow the output selected in Windows'
        Ready = 'Ready. Closing this window keeps the app in the tray.'
        Missing = 'Run Instaleaza.cmd to install the audio utility.'
        SwitchingStatus = 'Switching to {0}... allow about 15 seconds.'
        Exiting = 'Exiting after restoring the audio devices...'
        Open = 'Open'; Exit = 'Exit'; Settings = 'Settings'; Language = 'Language'; Close = 'Close'
        Active = 'Active'; Switching = 'Switching'; Speakers = 'SPEAKERS'
    }
    ro = @{
        HeadphonesNormal = 'Căști'
        Finishing = 'Finalizare'; Restarting = 'Repornesc Spotify…'; FinishingStatus = 'Spotify este deschis. Reactivez ieșirea…'; ActiveStatus = '{0} este activ.'
        DeviceUnavailable = '{0} este deconectat sau dezactivat. Conectează-l sau activează-l.'
        SpeakersNormal = 'Boxe'
        ShowDisconnected='Arată dispozitivele deconectate'; Disconnected='deconectat'; NoDevice='Niciun dispozitiv ales'
        General='General'; Devices='Dispozitive'; Name='Nume afișat'; AudioDevice='Dispozitiv audio'; Custom='Personalizat'; Choose='Alege...'; Reset='Resetează'; Apply='Aplică'; DefaultDevice='Dispozitiv original'; AutoDevice='Comută automat când conectez {0}'; SameDevice='Alege dispozitive audio diferite pentru cele două butoane.'; EmptyName='Introdu un nume personalizat (maximum 24 caractere).'; Busy='Așteaptă finalizarea comutării înainte de a aplica setările.'
        Theme = 'Temă'; Light = 'Luminoasă'; Dark = 'Întunecată'; System = 'Sistem'
        Startup = 'Pornire cu Windows'; On = 'Pornit'; Off = 'Oprit'
        Auto = 'Comută automat când conectez EarPods'
        Follow = 'Urmează ieșirea aleasă din meniul Windows'
        Ready = 'Pregătit. Închiderea ferestrei o ascunde lângă ceas.'
        Missing = 'Rulează Instaleaza.cmd pentru a instala utilitarul audio.'
        SwitchingStatus = 'Comut la {0}... așteaptă circa 15 secunde.'
        Exiting = 'Ieșire după reactivarea dispozitivelor...'
        Open = 'Deschide'; Exit = 'Ieșire'; Settings = 'Setări'; Language = 'Limbă'; Close = 'Închide'
        Active = 'Activ'; Switching = 'Comutare'; Speakers = 'BOXE'
    }
}
function T([string]$key) { return $script:translations[$script:language][$key] }
function Localize-Result([string]$text) {
    $text = $text.Replace('Speakers',(Get-DeviceName 'Speakers')).Replace('EarPods',(Get-DeviceName 'EarPods'))
    if ($script:language -eq 'ro') { return $text }
    $pairs = @(
        @('Apasa Play daca melodia este oprita.', 'Press Play if playback is paused.'),
        @('EROARE:', 'ERROR:'),
        @('Dispozitivul ', 'Device '),
        @(' nu a fost identificat univoc.', ' could not be uniquely identified.'),
        @(' nu este activ. Conecteaza-l / activeaza-l.', ' is not active. Connect or enable it.'),
        @('Ruleaza Instaleaza.cmd pentru a descarca utilitarul audio.', 'Run Instaleaza.cmd to download the audio utility.'),
        @('Spotify nu s-a inchis complet.', 'Spotify did not close completely.'),
        @('Dezactivarea a esuat pentru ', 'Could not disable '),
        @('. Detalii in monitor.log.', '. See monitor.log for details.'),
        @('Spotify nu a pornit.', 'Spotify did not start.'),
        @('Nu pot citi starea dispozitivului ', 'Could not read the state of device '),
        @('reactiveaza manual cealalta iesire din mmsys.cpl.', 'manually enable the other output in mmsys.cpl.')
    )
    foreach ($pair in $pairs) { $text = $text.Replace($pair[0],$pair[1]) }
    return $text
}
