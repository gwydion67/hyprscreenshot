# hyprscreenshot — QuickShell wrapper for hyprshot

A Spectacle-style screenshot GUI for Hyprland, built with QuickShell.
Features dynamic theme synchronization with Caelestia/Material You, custom configuration support.

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

- **Dynamic Theming**: Automatically syncs with Caelestia's `scheme.json` or uses a custom config.
- **Dependency Awareness**: Checks for `hyprshot` and `swappy` on launch and displays warnings if missing.
- **Custom Configuration**: Change behavior and colors via `config.json`.
- **Interactive UI**: Real-time delay adjustment and mode selection.
- **IPC Support**: control via `quickshell ipc`.

## Dependencies

### Required
- **[quickshell](https://github.com/outfoxxed/quickshell)**: The UI engine.
- **[hyprshot](https://github.com/Gustash/Hyprshot)**: The screen capture backend.
- **[swappy](https://github.com/jpsurber/swappy)**: The annotation and save tool.

### Recommended
- **[Caelestia](https://github.com/v-for-vandal/caelestia)**: For automatic Material You theming.

## Installation

1. **Clone and Setup**:
   ```bash
2. git clone https://github.com/gwydion67/hyprscreenshot ~/.config/quickshell/hyprscreenshot
   ```

2. **First Run**:
   Launch the GUI to generate the default configuration:
   ```bash
   quickshell -p ~/.config/quickshell/hyprscreenshot
   ```

## Configuration

The configuration file is located at `~/.config/quickshell/hyprscreenshot/config.json`.

```json
{
    "forceConfigTheme": false,
    "customSchemePath": "",
    "colors": {
        "accent": "#82aaff",
        "onAccent": "#000000",
        "background": "#1e1e2e",
        "card": "#181825",
        "text": "#cdd6f4"
    }
}
```

- `forceConfigTheme`: Set to `true` to ignore Caelestia and use the colors defined in `config.json`.
- `customSchemePath`: Path to a custom `scheme.json` file (similar to Caelestia's format).
- `colors`: Fallback or override colors for the GUI.

## Hyprland Integration

Add these to your `hyprland.conf`:

```ini
# Autostart the shell component
exec-once = quickshell -c hyprscreenshot

# Toggle the GUI (Super + Shift + S)
bind = $mainMod SHIFT, S, exec, qs ipc -c hyprscreenshot call hyprscreenshot toggle
```

## Theming Priority

1. If `forceConfigTheme` is `true`, colors are loaded from `config.json`.
2. If `customSchemePath` is set, colors are loaded from that JSON file.
3. By default, it looks for Caelestia's scheme at `~/.local/state/caelestia/scheme.json`.
4. If no theme file is found, it falls back to the hardcoded defaults.

## Keyboard Shortcuts

- `Escape`: Close window or cancel active countdown.
- `Enter`: Trigger capture (when capture button is focused).
