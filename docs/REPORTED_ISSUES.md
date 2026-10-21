# Reported issues to investigate

Recorded on 2026-10-21. These are my observations, not confirmed diagnoses. No behavior change has been made for these reports.

## Brief stutter during audio switching under heavy gaming load

- Sometimes, while I am playing a demanding game, switching the audio output coincides with a stutter lasting about one second.
- It is not yet clear whether this affects the game image, audio, or both, or which switching stage coincides with it.
- [ ] Record the running app version, game, switch trigger and switching stage.
- [ ] Distinguish audio interruption from a game/frame-time stall.
- [ ] Compare behavior under load with idle behavior and with a manual Windows output change.

## Audio split between outputs after boot with EarPods already connected

- EarPods are connected before I start the PC.
- EarPods were also selected before the previous restart.
- After startup, audio is split between two outputs; the exact application/output mapping still needs to be recorded.
- Switching Speakers → EarPods restores the expected behavior, acting as a reset.
- The existing no-op for clicking an already active output means clicking EarPods alone may not run the workaround. This is a hypothesis to verify, not a confirmed cause.
- [ ] Record which applications play through which output and the default output shown by Windows.
- [ ] Record whether Spotify starts before or after Sound Output Fix and whether Follow Windows output is enabled.
- [ ] Test Windows restart and cold startup separately with EarPods connected throughout.
- [ ] Capture logs before and after the Speakers → EarPods workaround and preserve the original settings.

## Temporary workaround

For split output after startup, switch Speakers → EarPods when both devices are available. This is a reported workaround, not a permanent fix.