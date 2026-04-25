import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: theme

    // ── Config Path ────────────────────────────────────────────────────────
    property string configDir: Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")
    property string configPath: configDir + "/quickshell/hyprscreenshot/config.json"
    
    // ── State ──────────────────────────────────────────────────────────────
    property int version: 0
    property string caelestiaPath: ((Quickshell.env("XDG_STATE_HOME") ? Quickshell.env("XDG_STATE_HOME") : ((Quickshell.env("HOME") || "") + "/.local/state")) + "/caelestia/scheme.json")
    
    // Config values
    property bool forceConfigTheme: false
    property string customSchemePath: ""

    // ── Colors ─────────────────────────────────────────────────────────────
    // Default Fallback Colors
    readonly property var defaults: {
        "accent": "#82aaff",
        "onAccent": "#000000",
        "background": "#1e1e2e",
        "card": "#181825",
        "text": "#cdd6f4"
    }

    property color accentColor: defaults.accent
    property color accentText: defaults.onAccent
    property color bgColor: defaults.background
    property color cardColor: defaults.card
    property color textColor: defaults.text

    // Derived colors
    property color mutedColor: Qt.rgba(textColor.r, textColor.g, textColor.b, 0.50)
    readonly property color dangerColor: Qt.rgba(0.95, 0.34, 0.41, 1.0)
    property color accentFaint: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.13)
    property color accentMed: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.22)
    property color accentBorder: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.50)
    readonly property color rimLight: Qt.rgba(1, 1, 1, 0.06)
    property color surfaceHover: Qt.rgba(textColor.r, textColor.g, textColor.b, 0.05)

    function normalizeHex(value, fallback) {
        if (typeof value !== "string" || value.length === 0)
            return fallback;
        return value.startsWith("#") ? value : ("#" + value);
    }

    function applyTheme(raw) {
        var text = (raw || "").toString().trim();
        if (text.length === 0) return;

        try {
            var json = JSON.parse(text);
            var c = json.colours || json.colors || json;

            if (c.primary)
                accentColor = normalizeHex(c.primary, accentColor.toString());
            else if (c.accent)
                accentColor = normalizeHex(c.accent, accentColor.toString());

            if (c.onPrimary)
                accentText = normalizeHex(c.onPrimary, accentText.toString());
            else if (c.onAccent)
                accentText = normalizeHex(c.onAccent, accentText.toString());

            if (c.background)
                bgColor = normalizeHex(c.background, bgColor.toString());

            if (c.surfaceContainerHigh)
                cardColor = normalizeHex(c.surfaceContainerHigh, cardColor.toString());
            else if (c.surface)
                cardColor = normalizeHex(c.surface, cardColor.toString());
            else if (c.card)
                cardColor = normalizeHex(c.card, cardColor.toString());

            if (c.onBackground)
                textColor = normalizeHex(c.onBackground, textColor.toString());
            else if (c.text)
                textColor = normalizeHex(c.text, textColor.toString());

            updateDerived();
        } catch (e) {
            console.log("[Theme] JSON parse failed:", e.message);
        }
    }

    function updateDerived() {
        mutedColor = Qt.rgba(textColor.r, textColor.g, textColor.b, 0.50);
        accentFaint = Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.13);
        accentMed = Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.22);
        accentBorder = Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.50);
        surfaceHover = Qt.rgba(textColor.r, textColor.g, textColor.b, 0.05);
        version++;
    }

    function loadConfig(text) {
        try {
            var cfg = JSON.parse(text);
            theme.forceConfigTheme = cfg.forceConfigTheme || false;
            theme.customSchemePath = cfg.customSchemePath || "";
            
            if (cfg.colors) {
                var c = cfg.colors;
                if (c.accent) accentColor = normalizeHex(c.accent, accentColor.toString());
                if (c.onAccent) accentText = normalizeHex(c.onAccent, accentText.toString());
                if (c.background) bgColor = normalizeHex(c.background, bgColor.toString());
                if (c.card) cardColor = normalizeHex(c.card, cardColor.toString());
                if (c.text) textColor = normalizeHex(c.text, textColor.toString());
                updateDerived();
            }
            
            updateSchemeWatching();
        } catch (e) {
            console.log("[Theme] Config parse failed:", e.message);
        }
    }

    function createDefaultConfig() {
        var defaultCfg = {
            "forceConfigTheme": false,
            "customSchemePath": "",
            "colors": theme.defaults
        };
        var text = JSON.stringify(defaultCfg, null, 4);
        
        // Escape single quotes for the bash command
        var escapedText = text.replace(/'/g, "'\\''");
        configWriterProc.command = ["bash", "-c", "mkdir -p $(dirname '" + theme.configPath + "') && echo '" + escapedText + "' > '" + theme.configPath + "'"];
        configWriterProc.running = true;
    }

    Process {
        id: configWriterProc
        onRunningChanged: if (!running && exitCode === 0) configFile.reload()
    }

    function updateSchemeWatching() {
        var target = "";
        if (theme.forceConfigTheme && theme.customSchemePath !== "") {
            target = theme.customSchemePath;
        } else {
            // Check if caelestia exists (implicitly handled by FileView's path)
            target = theme.caelestiaPath;
        }
        
        if (target !== schemeFile.path) {
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
        onLoadFailed: {
            console.log("[Theme] Config not found, creating default...");
            theme.createDefaultConfig();
        }
    }

    FileView {
        id: schemeFile
        path: theme.caelestiaPath
        watchChanges: true
        onLoaded: {
            if (!theme.forceConfigTheme) {
                theme.applyTheme(text());
            }
        }
    }

    Timer {
        id: reloadDebounce
        interval: 150
        repeat: false
        onTriggered: theme.reload()
    }

    Component.onCompleted: reload()
}
