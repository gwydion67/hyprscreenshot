# hyprscreenshot — QuickShell wrapper for hyprshot

A Spectacle-style screenshot GUI for Hyprland, built with QuickShell.
Features dynamic theme synchronization with Caelestia/Material You and a clean, modular design.

```
┌─────────────────────────────────┐
│  ⊙  Screenshot   hyprshot wrpr  ✕ │
├─────────────────────────────────┤
│  CAPTURE MODE                   │
│  ┌──────────────────────────┐   │
│  │         Region           │   │
│  └──────────────────────────┘   │
│  ┌──────────┐  ┌──────────┐     │
│  │  Window  │  │  Full    │     │
│  └──────────┘  └──────────┘     │
│  DELAY                          │
│  [ − ]  [ 0 sec ]  [ + ]        │
│                                 │
│  ╔═══════════════════════════╗  │
│  ║        Capture Now        ║  │
│  ╚═══════════════════════════╝  │
└─────────────────────────────────┘
```

## Features

- **Modular Design**: Refactored into reusable QML components for easy modification.
- **Dynamic Theming**: Automatically reads colors from Caelestia's `scheme.json` (`~/.local/state/caelestia/scheme.json`).
- **Interactive UI**: Real-time delay adjustment and capture mode selection.
- **Countdown**: Visual countdown when a delay is set, with an option to cancel.
- **IPC Support**: Toggle, open, or close the GUI via `quickshell ipc`.

## Dependencies

```bash
# Required
hyprshot        # Screen capture backend
swappy          # Post-capture editor and annotation tool
bash            # Used to execute the capture command chain

# QuickShell
quickshell      # The engine running this GUI
```

## Installation

1. Create the configuration directory:
   ```bash
   mkdir -p ~/.config/quickshell/hyprscreenshot/components
   ```

2. Copy the files:
   - `shell.qml` to `~/.config/quickshell/hyprscreenshot/`
   - All files in `components/` to `~/.config/quickshell/hyprscreenshot/components/`

3. Test it:
   ```bash
   quickshell -p ~/.config/quickshell/hyprscreenshot
   ```

## Hyprland Integration

Add these to your Hyprland configuration (e.g., `~/.config/hypr/hyprland.conf`):

```ini
# Autostart the shell component
exec-once = quickshell -c hyprscreenshot

# Toggle the GUI (Super + Shift + S)
bind = $mainMod SHIFT, S, exec, qs ipc -c hyprscreenshot call hyprscreenshot toggle
```

## Architecture

The project is broken down into several parts:

- `shell.qml`: The main entry point and state controller.
- `components/Theme.qml`: Handles dynamic color loading and theme application.
- `components/Header.qml`: The window header with title and close button.
- `components/CaptureModeSelector.qml`: Selection grid for Region, Window, and Full Screen.
- `components/DelaySelector.qml`: UI for adjusting the capture delay.
- `components/CountdownView.qml`: Overlay shown during a timed capture.

## Theme Synchronization

The GUI watches `~/.local/state/caelestia/scheme.json` for changes. If you change your system theme via Caelestia or Matugen, the GUI will update its colors instantly without requiring a restart.

## Behavior

1. **Select Mode**: Choose between Region (drag), Window (click), or Full Screen.
2. **Set Delay**: Adjust the delay if you need time to set up your shot.
3. **Capture**:
   - If Delay is 0: Window hides and `hyprshot` triggers immediately.
   - If Delay > 0: A countdown appears. You can **Cancel** at any time.
4. **Annotate**: Once captured, `swappy` opens automatically for editing and saving.

> ⚠️ **Note**: Screenshots are passed to `swappy` via a raw pipe. You must save the file within `swappy` to keep it.
