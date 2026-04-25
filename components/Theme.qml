import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: theme

    // ── State ──────────────────────────────────────────────────────────────
    property int version: 0
    property string schemePath: ((Quickshell.env("XDG_STATE_HOME") ? Quickshell.env("XDG_STATE_HOME") : ((Quickshell.env("HOME") || "") + "/.local/state")) + "/caelestia/scheme.json")

    // ── Colors ─────────────────────────────────────────────────────────────
    property color accentColor: "#82aaff"
    property color accentText: "#000000"
    property color bgColor: "#1e1e2e"
    property color cardColor: "#181825"
    property color textColor: "#cdd6f4"

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
            if (c.onPrimary)
                accentText = normalizeHex(c.onPrimary, accentText.toString());
            if (c.background)
                bgColor = normalizeHex(c.background, bgColor.toString());

            if (c.surfaceContainerHigh)
                cardColor = normalizeHex(c.surfaceContainerHigh, cardColor.toString());
            else if (c.surface)
                cardColor = normalizeHex(c.surface, cardColor.toString());

            if (c.onBackground)
                textColor = normalizeHex(c.onBackground, textColor.toString());

            // Recompute derived
            mutedColor = Qt.rgba(textColor.r, textColor.g, textColor.b, 0.50);
            accentFaint = Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.13);
            accentMed = Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.22);
            accentBorder = Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.50);
            surfaceHover = Qt.rgba(textColor.r, textColor.g, textColor.b, 0.05);

            version++;
        } catch (e) {
            console.log("[Theme] JSON parse failed:", e.message);
        }
    }

    function reload() {
        schemeFile.reload();
    }

    Timer {
        id: reloadDebounce
        interval: 150
        repeat: false
        onTriggered: schemeFile.reload()
    }

    FileView {
        id: schemeFile
        path: theme.schemePath
        blockLoading: true
        watchChanges: true

        onLoaded: theme.applyTheme(text())
        onFileChanged: reloadDebounce.restart()
    }

    Component.onCompleted: reload()
}
