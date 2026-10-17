# Troubleshooting

## A device is missing

Check its connection and enable **Show disconnected devices** in Settings → Devices. A microphone listed under Input is separate from the headphones' playback output.

If needed, press Win + R, enter `mmsys.cpl`, open the Playback tab and show disabled and disconnected devices. Enable the playback device if disabled.

## Spotify is paused after switching

Press Play if needed. Automatic resumption requires an accessible Spotify Windows media session that was playing before switching. If the session is unavailable, the app skips automatic playback. The alternate output is restored after a four-second initialization delay once the Spotify process is detected. Overall timing varies by computer; process detection does not guarantee playback is ready.

## The window disappeared

Closing the window hides it in the tray. Double-click its tray icon to reopen it. Right-click the tray icon and choose Exit to close the app completely.

## Startup did not work

Check the Start with Windows option in Settings, the Startup Apps list in Windows and the location of the application folder. Windows may delay startup applications after sign-in.

Turn startup off before moving the application, then enable it again from the new location.

## Switching fails

Check that the configured output is connected and enabled. Save the displayed error message and the `monitor.log` file for troubleshooting. Check diagnostics for personal paths or device information before sharing them.

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

## Downloaded libraries cannot be loaded

Version 1.0.1 handles .NET Framework error 0x80131515 by compiling the bundled source if a downloaded helper DLL is blocked. Keep the source files included in the package. This does not remove SmartScreen warnings for an unsigned executable.
