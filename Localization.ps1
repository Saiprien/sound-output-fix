$script:language = 'en'
$script:theme = 'system'
$script:resumePlayback = $false
$script:settingsPath = Join-Path $root 'settings.json'
if (Test-Path $script:settingsPath) {
    try {
        $saved = Get-Content $script:settingsPath -Raw | ConvertFrom-Json
        if ($saved.theme -in @('light','dark','system')) { $script:theme = $saved.theme }
        if ($saved.language -in @('en','ro','ru','zh-CN')) { $script:language = $saved.language }
        if ($saved.resumePlayback -is [bool]) { $script:resumePlayback = $saved.resumePlayback }
    } catch { }
}
$script:translations = @{
    en = @{
        ResumePlayback = 'Automatically resume playback after switching devices'
        ResumePlaybackHint = 'Resumes Spotify if it was playing; leaves it paused otherwise.'
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
        ResumePlayback = 'Reia automat redarea după schimbarea dispozitivului'
        ResumePlaybackHint = 'Reia Spotify dacă reda înainte; altfel, îl lasă pe pauză.'
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
$script:translations.ru = @{
 ResumePlayback='Автоматически возобновлять воспроизведение при смене устройства'
 ResumePlaybackHint='Возобновляет Spotify, если музыка играла; иначе оставляет на паузе.'
 HeadphonesNormal='Наушники'; SpeakersNormal='Динамики'; Speakers='ДИНАМИКИ'
 Finishing='Завершение'; Restarting='Перезапуск Spotify…'; FinishingStatus='Spotify открыт. Восстановление выхода…'; ActiveStatus='{0}: активен.'
 DeviceUnavailable='{0}: отключён или недоступен. Подключите или включите его.'
 ShowDisconnected='Показать отключённые устройства'; Disconnected='отключено'; NoDevice='Устройство не выбрано'
 General='Общие'; Devices='Устройства'; Name='Название'; AudioDevice='Устройство'; Custom='Своё'; Choose='Выбрать…'; Reset='Сбросить'; Apply='Применить'; DefaultDevice='Исходное устройство'
 AutoDevice='Переключать при подключении {0}'; SameDevice='Выберите разные устройства для двух кнопок.'; EmptyName='Введите название (не более 24 символов).'; Busy='Дождитесь завершения переключения.'
 Theme='Тема'; Light='Светлая'; Dark='Тёмная'; System='Системная'; Startup='Запускать с Windows'; On='Вкл.'; Off='Выкл.'
 Auto='Переключать при подключении EarPods'; Follow='Следовать выбору выхода в Windows'
 Ready='Готово. При закрытии окна приложение остаётся в трее.'; Missing='Отсутствует аудиокомпонент. Распакуйте приложение заново.'
 SwitchingStatus='Переключение на {0}…'; Exiting='Выход после восстановления устройств…'
 Open='Открыть'; Exit='Выход'; Settings='Настройки'; Language='Язык'; Close='Закрыть'; Active='Активен'; Switching='Переключение'
}
$script:translations.'zh-CN' = @{
 ResumePlayback='切换设备后自动恢复播放'
 ResumePlaybackHint='若 Spotify 在切换前正在播放，则恢复播放；否则保持暂停。'
 HeadphonesNormal='耳机'; SpeakersNormal='扬声器'; Speakers='扬声器'
 Finishing='即将完成'; Restarting='正在重启 Spotify…'; FinishingStatus='Spotify 已打开，正在恢复另一输出…'; ActiveStatus='{0} 已启用。'
 DeviceUnavailable='{0} 未连接或已禁用。请先连接或启用。'
 ShowDisconnected='显示未连接的设备'; Disconnected='未连接'; NoDevice='未选择设备'
 General='常规'; Devices='设备'; Name='显示名称'; AudioDevice='音频设备'; Custom='自定义'; Choose='选择…'; Reset='重置'; Apply='应用'; DefaultDevice='原始设备'
 AutoDevice='连接 {0} 时自动切换'; SameDevice='请为两个按钮选择不同的音频设备。'; EmptyName='请输入自定义名称（最多 24 个字符）。'; Busy='请等待切换完成后再应用设备设置。'
 Theme='主题'; Light='浅色'; Dark='深色'; System='跟随系统'; Startup='随 Windows 启动'; On='开启'; Off='关闭'
 Auto='连接 EarPods 时自动切换'; Follow='跟随 Windows 选择的输出'
 Ready='就绪。关闭窗口后，应用仍在系统托盘中运行。'; Missing='缺少音频组件。请重新解压应用。'
 SwitchingStatus='正在切换到 {0}…'; Exiting='恢复音频设备后退出…'
 Open='打开'; Exit='退出'; Settings='设置'; Language='语言'; Close='关闭'; Active='已启用'; Switching='正在切换'
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
    $localizedErrors = @{
        ru = @{
            'Press Play if playback is paused.'='Нажмите Play, если воспроизведение приостановлено.'
            'ERROR:'='ОШИБКА:'; 'Device '='Устройство '; ' could not be uniquely identified.'=' не удалось однозначно определить.'
            ' is not active. Connect or enable it.'=' не активно. Подключите или включите его.'
            'Run Instaleaza.cmd to download the audio utility.'='Распакуйте приложение заново: отсутствует аудиокомпонент.'
            'Spotify did not close completely.'='Spotify не закрылся полностью.'; 'Could not disable '='Не удалось отключить '
            '. See monitor.log for details.'='. Подробности в monitor.log.'; 'Spotify did not start.'='Spotify не запустился.'
            'Could not read the state of device '='Не удалось прочитать состояние устройства '
            'manually enable the other output in mmsys.cpl.'='включите другой выход вручную в mmsys.cpl.'
        }
        'zh-CN' = @{
            'Press Play if playback is paused.'='如果播放已暂停，请按播放。'
            'ERROR:'='错误：'; 'Device '='设备 '; ' could not be uniquely identified.'=' 无法唯一识别。'
            ' is not active. Connect or enable it.'=' 未启用。请连接或启用。'
            'Run Instaleaza.cmd to download the audio utility.'='缺少音频组件，请重新解压应用。'
            'Spotify did not close completely.'='Spotify 未完全关闭。'; 'Could not disable '='无法禁用 '
            '. See monitor.log for details.'='。详情请查看 monitor.log。'; 'Spotify did not start.'='Spotify 未能启动。'
            'Could not read the state of device '='无法读取设备状态：'
            'manually enable the other output in mmsys.cpl.'='请在 mmsys.cpl 中手动启用另一输出。'
        }
    }
    if ($localizedErrors.ContainsKey($script:language)) {
        foreach ($entry in $localizedErrors[$script:language].GetEnumerator()) { $text = $text.Replace($entry.Key,$entry.Value) }
    }
    return $text
}
