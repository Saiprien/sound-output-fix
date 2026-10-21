# Changelog

## 1.2.0

- Added an optional tray-only startup preference for Windows sign-in, translated into all four interface languages.
- Replaced the startup button with a green/gray switch and distinct On/Off positions.
- Displayed the application version beside the creator credit in Settings.
- Fixed Windows Forms automatically displaying the startup window when a main form was attached to the application context. Tray startup now uses a context without a main form.
- Removed stale show requests when starting a new instance. Explicit manual launches can still reopen an existing instance.



## 1.1.0

### Added
- Optional automatic playback resumption after switching devices. Spotify resumes only if it was playing before the switch; otherwise, it remains paused. The option is disabled by default.
- Russian and Simplified Chinese translations.
- Added credits in Settings.

### Improved
- Clearer wording and tighter spacing for the playback-resumption option.

### Fixed
- Secondary status text now retains its muted color when the window is reopened, in both Light and Dark themes.

## 1.0.1

- Fixed startup error `0x80131515` when .NET Framework blocks downloaded helper libraries. The app now compiles the bundled source when this specific error occurs.

## 1.0.0 — Initial public release

- Switch between two configurable Windows audio outputs, with a workaround for Spotify output-switching issues.
- Switch automatically when the second device connects or the Windows output changes.
- Customize device names and button images, with default speaker and headphone icons.
- Choose English or Romanian and Light, Dark or System themes.
- View Switching, Finishing and Active indicators in the interface.
- Run in the system tray, with optional startup when signing in to Windows.
- Save device mappings, names, images, language and theme between sessions.
- Distribute the source under the PolyForm Noncommercial License 1.0.0, with commercial licensing available through a separate agreement.

I developed and tested these features privately before the first public release. The detailed [development history](docs/DEVELOPMENT_HISTORY.md) is available separately.

## Current limitations

- Playback may require pressing Play after Spotify restarts.
- Temporarily disabling the other output can affect applications using it.
- IPolicyConfig is undocumented and requires ongoing Windows compatibility testing.
- The unsigned executable may trigger a Windows SmartScreen warning.