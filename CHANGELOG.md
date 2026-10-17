# Changelog

## 1.0.1

- Fixed startup error 0x80131515 when .NET Framework blocks downloaded audio or UI libraries. The app compiles the bundled source when this specific error occurs, without changing Windows security settings.
- Verified loading with internet-marked DLLs and normal local DLLs.

## 1.0.0 — Initial public release

- This is my first public release. It includes the features and fixes developed during private testing.
- Features include configurable audio outputs, a workaround for Spotify output-switching issues, automatic switching, English and Romanian translations, Light, Dark and System themes, custom names and images, and startup in the system tray.

All features and fixes below are included in 1.0.0. I developed and tested them privately before publication.

### Licensing

- I make Sound Output Fix available under the PolyForm Noncommercial License 1.0.0. My copyright notice must be preserved, and commercial licensing is available through a separate agreement.

### Final polish

- Reduced the initialization delay before restoring the alternate output from eight to four seconds after Spotify process detection. I tested the shorter delay and confirmed improved switching time on 2026-10-17.
- Renamed the primary license file to LICENSE.

- A startup launch no longer opens the window when another instance is already running.

#### Changes

- Windows startup now opens only the tray icon; manual launches still open the window. Re-enable startup in Settings once to refresh an existing shortcut.

- Precompiled audio and UI helper libraries to avoid compiling them at each launch. Source-only folders retain a compilation fallback.

- Removed customized product-photo screenshots from distribution documentation.

- Split switching feedback into Switching, Finishing and Active stages. Switching uses a 1 px yellow border, Finishing uses a 2 px yellow border, and Active uses a 2 px green border.
- Added short status messages for Spotify restart and restoration of the other output.
- Positioned default icons above button labels to prevent overlap and adjusted headphone alignment.

- Replaced bundled product photos with original speaker/headphone outline icons, adapted for Light and Dark themes. Custom images remain optional; Reset restores the default icon.

- Added a yellow outline to the target button: 1 px during Switching and 2 px during Finishing.

#### Resolved bugs

- Smoothed the animated switching dots using elapsed time, double-buffered drawing and a shorter redraw interval. Deferred endpoint enumeration while the switching worker runs.

- Translated display-name presets in Settings while keeping saved preset identifiers compatible across languages.
- Kept the taskbar icon light when using Light mode, independently of the title-bar icon.

- Fixed an invalid backup-path error when updating switching progress, which interrupted the transition to Finishing. Added a regression check for repeated progress writes.

- Clicking the output already selected in Windows no longer restarts Spotify. External Windows output changes still apply the Spotify workaround.

- Fixed an issue where Active briefly appeared before Switching after an output was selected in Windows. The indicator now shows Switching while confirming and applying the change, followed by Active when the switch is complete.

### Windows audio backend


- Replaced NirSoft SoundVolumeCommandLine with independent Windows audio COM calls.
- Removed the NirSoft binary dependency.
- Added retries when restoring the temporarily disabled output.
- Preserved the existing interface, settings and switching workflow.
- Prepared versioned portable and documentation archives.

### Portable executable and documentation

- Added a Windows GUI executable hosting the PowerShell application in-process.
- Named the application Sound Output Fix.
- Prepared portable packages, README, screenshots and third-party notices.
- Documented installation, usage, troubleshooting and technical limitations.

### Reliability and code cleanup

- Separated settings, audio, theme, localization and verification code.
- Improved cleanup of image and font resources.
- Preserved unapplied device edits when changing the settings language.
- Rejected disconnected or disabled outputs before starting a switch.
- Made device-error messages temporary, returning the status to Ready.
- Restored button availability if the worker failed to start.
- Fixed startup checks when an optional Windows registry value was absent.
- Added checks for UI construction, themes, languages, settings persistence, device mapping and list filtering.

### Interface polish

- Updated the interface font and made audio-button labels bold.
- Added rounded buttons and improved border smoothing.
- Replaced the bright settings frame with themed borders and tab indicators.
- Refined spacing, the status text and the settings cog's size and position.
- Kept a permanent background on the settings button.
- Made tray checkmarks readable in both themes.
- Kept main button names uppercase and tray names in normal case.

### Device customization

- Split Settings into General and Devices tabs.
- Added independent audio-device selection for both buttons.
- Added Speakers, EarPods, Headphones and Custom name presets.
- Used configured names in the window, tray and status messages.
- Added PNG/JPG image selection, thumbnails and Reset controls.
- Copied custom images into the application folder and saved device preferences.
- Filtered device lists to show connected devices by default, with a Show disconnected devices option.
- Kept the selected output visible if disconnected and replaced the generic original-device label with its actual name.
- Prevented selection of the same output for both buttons.

### Light and Dark themes

- Added Light, Dark and System themes with a neutral palette.
- Applied theme changes immediately and saved the choice.
- Adapted title-bar icons and menu colors to the selected theme.
- Removed the white background around the speaker image.

### Windows startup

- Added an option to enable or disable Start with Windows in Settings.
- Read the existing startup shortcut state.
- Later refined startup handling to recognize Windows-disabled entries and launch the executable when available.

### Settings and languages

- Added the settings cog and a settings window.
- Added English as the default interface language and Romanian as an option.
- Applied language changes immediately and saved the selection.
- Translated tray commands, indicators and common status messages.

### Icons and switching feedback

- Integrated the custom icon into the window, tray and taskbar.
- Added application identity to separate taskbar grouping from PowerShell.
- Added a subtle active-button border and grey inactive borders.
- Added green Active labels with checkmarks below the buttons.
- Added yellow Switching text with sequential bouncing dots.
- Added active-device checkmarks to the tray menu.
- Adjusted image visibility in the output buttons.

### Initial application

- Created the Windows desktop interface with Speakers and EarPods buttons.
- Added Windows default-output switching and a Spotify restart workaround.
- Kept Spotify closed if it was not running before a switch.
- Added automatic switching when EarPods connect and detection of output changes made in Windows.
- Added tray behavior: close-to-tray, reopen, switch and exit.
- Added single-instance protection, prevention of overlapping switches and filtering to avoid repeated restarts.
- Used SoundVolumeCommandLine for the initial audio implementation.

## Current limitations

- Playback may require pressing Play after Spotify restarts.
- Temporarily disabling the other output can affect applications using it.
- IPolicyConfig is undocumented and requires ongoing Windows compatibility testing.
