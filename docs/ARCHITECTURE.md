# Architecture

The interface uses Windows Forms. A small C# GUI executable hosts Windows PowerShell 5.1 in an STA runspace and invokes App.ps1 from the application folder.

| Module | Responsibility |
| --- | --- |
| App.ps1 | Window, tray, timers and switch coordination |
| SettingsWindow.ps1 / DeviceSettings.ps1 | General and Devices settings |
| DeviceConfig.ps1 / Localization.ps1 / Theme.ps1 | Configuration and presentation |
| ModernControls.ps1 | Custom Windows Forms controls |
| Switch.ps1 | Isolated switching worker and Spotify restart |
| AudioCore.ps1 / WindowsAudio.cs | Windows audio operations |
| Startup.ps1 | Current-user startup shortcut |

Documented IMMDeviceEnumerator and IMMDevice interfaces read the default output and endpoint state. Render-device labels are read from Windows endpoint metadata. The isolated IPolicyConfig ABI calls set defaults and endpoint visibility; this interface is undocumented and has no guaranteed compatibility contract.

COM references are released after calls. HRESULT failures are reported. The worker restores the other output in a finally block with up to three retries. Restoration cannot be guaranteed after forced process termination or a system crash.

The window and worker share local result and diagnostic files. A named mutex prevents concurrent instances, including the preceding edition.

## API references

- [IMMDeviceEnumerator](https://learn.microsoft.com/en-us/windows/win32/api/mmdeviceapi/nn-mmdeviceapi-immdeviceenumerator)
- [IMMDevice](https://learn.microsoft.com/en-us/windows/win32/api/mmdeviceapi/nn-mmdeviceapi-immdevice)
- [Endpoint visibility discussion](https://learn.microsoft.com/en-gb/answers/questions/1617393/how-to-enable-disable-audio-devices)

Switching progress is published using an atomic file replacement with an explicit backup path. Initial progress errors are caught by the worker error handler.
