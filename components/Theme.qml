import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: theme

    // ── Paths ─────────────────────────────────────────────────────────────
    readonly property string configPath: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/quickshell/hyprscreenshot/config.json"
    readonly property string caelestiaPath: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/caelestia/scheme.json"
    
    // ── State ──────────────────────────────────────────────────────────────
    property int version: 0
    property bool forceConfigTheme: false
    property string customSchemePath: ""

    // ── Colors ─────────────────────────────────────────────────────────────
    readonly property var defaults: ({
        "accent": "#82aaff",
        "onAccent": "#000000",
        "background": "#1e1e2e",
        "card": "#181825",
        "text": "#cdd6f4"
    })

    property color accentColor: defaults.accent
    property color accentText: defaults.onAccent
    property color bgColor: defaults.background
    property color cardColor: defaults.card
    property color textColor: defaults.text

    // Derived colors
    property color mutedColor: Qt.rgba(textColor.r, textColor.g, textColor.b, 0.5)
    readonly property color dangerColor: "#f25769"
    property color accentFaint: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.13)
    property color accentMed: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.22)
    property color accentBorder: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.5)
    readonly property color rimLight: Qt.rgba(1, 1, 1, 0.06)
    property color surfaceHover: Qt.rgba(textColor.r, textColor.g, textColor.b, 0.05)

    function normalizeHex(v, fallback) {
        return (typeof v === "string" && v.length > 0) ? (v.startsWith("#") ? v : "#" + v) : fallback;
    }

    function updateColors(c) {
        if (!c) return;
        console.log("[Debug - Theme] Updating colors with primary:", c.primary || c.accent);
        accentColor = normalizeHex(c.primary || c.accent, accentColor);
        accentText  = normalizeHex(c.onPrimary || c.onAccent, accentText);
        bgColor     = normalizeHex(c.background, bgColor);
        cardColor   = normalizeHex(c.surfaceContainerHigh || c.surface || c.card, cardColor);
        textColor   = normalizeHex(c.onBackground || c.text, textColor);

        // Recompute derived
        mutedColor   = Qt.rgba(textColor.r, textColor.g, textColor.b, 0.5);
        accentFaint  = Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.13);
        accentMed    = Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.22);
        accentBorder = Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.5);
        surfaceHover = Qt.rgba(textColor.r, textColor.g, textColor.b, 0.05);
        version++;
    }

    function loadConfig(text) {
        try {
            var cfg = JSON.parse(text);
            console.log("[Debug - Theme] Config loaded. forceConfigTheme:", !!cfg.forceConfigTheme);
            theme.forceConfigTheme = !!cfg.forceConfigTheme;
            theme.customSchemePath = cfg.customSchemePath || "";
            if (cfg.colors) updateColors(cfg.colors);
            updateSchemeWatching();
        } catch (e) { console.log("[Error - Theme] Config error:", e.message); }
    }

    function createDefaultConfig() {
        console.log("[Debug - Theme] Creating default config...");
        var text = JSON.stringify({ "forceConfigTheme": false, "customSchemePath": "", "colors": defaults }, null, 4);
        var esc = text.replace(/'/g, "'\\''");
        configWriter.command = ["bash", "-c", "mkdir -p $(dirname '" + configPath + "') && echo '" + esc + "' > '" + configPath + "'"];
        configWriter.running = true;
    }

    Process { id: configWriter; onRunningChanged: if (!running && exitCode === 0) configFile.reload() }

    function updateSchemeWatching() {
        var target = (theme.forceConfigTheme && theme.customSchemePath) ? theme.customSchemePath : theme.caelestiaPath;
        if (target !== schemeFile.path) {
            console.log("[Debug - Theme] Switching scheme source to:", target);
            schemeFile.path = target;
            schemeFile.reload();
        }
    }

    function reload() {
        configFile.reload();
        schemeFile.reload();
    }

    FileView {
        id: configFile
        path: theme.configPath
        watchChanges: true
        onLoaded: theme.loadConfig(text())
        onLoadFailed: theme.createDefaultConfig()
    }

    FileView {
        id: schemeFile
        path: theme.caelestiaPath
        watchChanges: true
        onLoaded: {
            if (!theme.forceConfigTheme) {
                console.log("[Debug - Theme] Scheme file loaded");
                theme.updateColors(JSON.parse(text()).colours || JSON.parse(text()).colors || JSON.parse(text()));
            }
        }
    }

    Component.onCompleted: reload()
}
