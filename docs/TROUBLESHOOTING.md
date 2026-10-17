# Troubleshooting

## A device is missing

Check its connection and enable **Show disconnected devices** in Settings → Devices. A microphone under Input is separate from its headphone playback output.

If needed, press Win + R, enter `mmsys.cpl`, select Playback and display disabled/disconnected devices. Enable the playback device if disabled.

## Spotify is paused after switching

Press Play. Automatic playback resumption is not guaranteed. The alternate output is restored after a four-second initialization delay once the Spotify process is detected. Overall timing varies by computer; process detection does not guarantee playback is ready.

## The window disappeared

Closing the window hides it in the tray. Double-click its tray icon to reopen it. Use tray → Exit to close the app fully.

## Startup did not work

Check Start with Windows in Settings, the Windows Startup Apps list and the application's folder location. Windows may delay startup applications after sign-in.

Turn startup off before moving the application, then enable it again from the new location.

## Switching fails

Check that the configured output is connected and enabled. Keep the displayed error and `monitor.log` for investigation. Check diagnostics for personal paths or device information before sharing them.

Do not forcibly terminate the application during switching: its worker may be restoring a temporarily disabled output.

## Local files

| Location | Purpose |
| --- | --- |
| `settings.json` | Preferences and device configuration |
| `assets/custom/` | Copies of custom button images |
| `monitor.log` | Audio-operation diagnostics |
| `result.txt` | Latest switching result |
| `launch-error.txt` | Startup errors, when present |
| `show.flag` / `stop.flag` | Instance coordination |

These files are stored in the application folder. The app does not require Spotify account authorization or use the Spotify Web API.
