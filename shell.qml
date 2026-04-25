// ┌─────────────────────────────────────────────────────────────────────────┐
// │  hyprscreenshot — QuickShell wrapper for hyprshot                       │
// │  Place at:  ~/.config/quickshell/hyprscreenshot/shell.qml               │
// │  Autostart: exec-once = qs -c hyprscreenshot                            │
// │  Toggle:    qs ipc -c hyprscreenshot call hyprscreenshot toggle         │
// └─────────────────────────────────────────────────────────────────────────┘

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components"

ShellRoot {
    id: root

    // ── State ──────────────────────────────────────────────────────────────
    property string selectedMode: "region"
    property int selectedDelay: 0
    property bool isCapturing: false
    property int countdown: 0
    
    // Dependency State (Explicitly reactive)
    property bool hyprshotInstalled: false
    property bool swappyInstalled: false
    property bool dependenciesMet: hyprshotInstalled && swappyInstalled

    onHyprshotInstalledChanged: console.log("[Debug] HS property updated:", hyprshotInstalled)
    onSwappyInstalledChanged: console.log("[Debug] SW property updated:", swappyInstalled)
    onDependenciesMetChanged: console.log("[Debug] dependenciesMet updated:", dependenciesMet)

    // ── Theme ──────────────────────────────────────────────────────────────
    Theme {
        id: theme
    }

    // ── Dependency Check (Reliable File-Based Method) ──────────────────────
    property string depFilePath: "/tmp/hyprscreenshot_deps.json"
    
    function runDepCheck() {
        console.log("[Debug] Running dependency check...");
        depChecker.running = true;
    }

    Process {
        id: depChecker
        command: ["bash", "-c", "HS=$(which hyprshot >/dev/null 2>&1 && echo true || echo false); SW=$(which swappy >/dev/null 2>&1 && echo true || echo false); echo \"{\\\"hyprshot\\\": $HS, \\\"swappy\\\": $SW}\" > " + root.depFilePath]
        onRunningChanged: {
            if (!running) {
                depFileReader.reload();
            }
        }
    }

    FileView {
        id: depFileReader
        path: root.depFilePath
        onLoaded: {
            try {
                var res = JSON.parse(text());
                // Force boolean type casting
                root.hyprshotInstalled = !!res.hyprshot;
                root.swappyInstalled = !!res.swappy;
                console.log("[Debug] File read: hyprshot=" + root.hyprshotInstalled + ", swappy=" + root.swappyInstalled);
            } catch(e) {
                console.log("[Error] JSON parse failed for dependencies");
            }
        }
    }

    Component.onCompleted: {
        runDepCheck();
    }

    // ── Processes ──────────────────────────────────────────────────────────
    Process {
        id: captureProc
        onRunningChanged: {
            if (!running) {
                root.isCapturing = false;
            }
        }
    }

    // ── Countdown → hide → capture chain ──────────────────────────────────
    Timer {
        id: countdownTimer
        interval: 1000
        repeat: true
        onTriggered: {
            root.countdown--;
            if (root.countdown <= 0) {
                stop();
                mainWindow.visible = false;
                freezeDelay.start();
            }
        }
    }

    Timer {
        id: freezeDelay
        interval: 380
        repeat: false
        onTriggered: runHyprshot()
    }

    function startCapture() {
        if (!root.dependenciesMet) return;
        root.isCapturing = true;
        if (root.selectedDelay === 0) {
            mainWindow.visible = false;
            freezeDelay.start();
        } else {
            root.countdown = root.selectedDelay;
            countdownTimer.start();
        }
    }

    function cancelCapture() {
        countdownTimer.stop();
        root.isCapturing = false;
        root.countdown = 0;
    }

    function runHyprshot() {
        var cmd = "hyprshot -m " + root.selectedMode + " --freeze --raw | swappy -f -";
        captureProc.command = ["bash", "-c", cmd];
        captureProc.running = true;
    }

    // ── IPC ────────────────────────────────────────────────────────────────
    IpcHandler {
        target: "hyprscreenshot"
        function toggle() {
            if (!mainWindow.visible) {
                theme.reload();
                runDepCheck();
            }
            mainWindow.visible = !mainWindow.visible;
        }
        function open() {
            theme.reload();
            runDepCheck();
            mainWindow.visible = true;
        }
        function close() {
            if (root.isCapturing)
                root.cancelCapture();
            mainWindow.visible = false;
        }
    }

    // ── Window ─────────────────────────────────────────────────────────────
    FloatingWindow {
        id: mainWindow
        visible: false

        implicitWidth: 420
        implicitHeight: !root.dependenciesMet ? 280 : (root.isCapturing ? 230 : 420)

        color: "transparent"
        onVisibleChanged: {
            if (visible) {
                theme.reload();
                runDepCheck();
            }
        }

        Rectangle {
            id: card
            property int _forceUpdate: theme.version

            anchors.fill: parent
            radius: 14
            color: theme.bgColor
            border.color: theme.rimLight
            border.width: 1
            clip: true

            Rectangle {
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: 1
                color: theme.rimLight
            }

            ColumnLayout {
                anchors { fill: parent; margins: 20 }
                spacing: 0

                Header {
                    theme: theme
                    onCloseClicked: mainWindow.visible = false
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    // ── Dependency Error UI ──────────────────────────────
                    ColumnLayout {
                        anchors.fill: parent
                        visible: !root.dependenciesMet
                        spacing: 12

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 140
                            radius: 12
                            color: Qt.rgba(theme.dangerColor.r, theme.dangerColor.g, theme.dangerColor.b, 0.1)
                            border.color: theme.dangerColor
                            border.width: 1

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 8
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "MISSING DEPENDENCIES"
                                    color: theme.dangerColor
                                    font.pixelSize: 12
                                    font.weight: Font.Bold
                                    font.letterSpacing: 1.2
                                }
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: (root.hyprshotInstalled ? "" : "• hyprshot\n") + (root.swappyInstalled ? "" : "• swappy")
                                    color: theme.textColor
                                    font.pixelSize: 13
                                    horizontalAlignment: Text.AlignHCenter
                                }
                                
                                Rectangle {
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.preferredWidth: 100
                                    Layout.preferredHeight: 28
                                    radius: 6
                                    color: retryHov.containsMouse ? theme.surfaceHover : "transparent"
                                    border.color: theme.mutedColor
                                    border.width: 1
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: "Check Again"
                                        color: theme.textColor
                                        font.pixelSize: 11
                                    }
                                    
                                    HoverHandler { id: retryHov }
                                    TapHandler {
                                        onTapped: root.runDepCheck()
                                    }
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }

                    // ── Setup UI ─────────────────────────────────────────
                    ColumnLayout {
                        anchors.fill: parent
                        visible: root.dependenciesMet && !root.isCapturing
                        spacing: 0

                        CaptureModeSelector {
                            theme: theme
                            selectedMode: root.selectedMode
                            onSelectedModeChanged: root.selectedMode = selectedMode
                        }

                        DelaySelector {
                            theme: theme
                            selectedDelay: root.selectedDelay
                            onSelectedDelayChanged: root.selectedDelay = selectedDelay
                        }

                        Item { Layout.fillHeight: true }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 44
                            radius: 10
                            color: capHov.containsMouse ? Qt.darker(theme.accentColor, 1.08) : theme.accentColor
                            scale: capHov.containsMouse ? 0.975 : 1.0

                            Behavior on color { ColorAnimation { duration: 110 } }
                            Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }

                            Text {
                                anchors.centerIn: parent
                                text: root.selectedDelay > 0 ? "Capture in " + root.selectedDelay + "s" : "Capture Now"
                                color: theme.accentText
                                font.pixelSize: 14
                                font.weight: Font.Medium
                            }

                            HoverHandler { id: capHov }
                            TapHandler { onTapped: root.startCapture() }
                        }
                    }

                    // ── Countdown UI ───────────────────────────────────────
                    CountdownView {
                        anchors.fill: parent
                        visible: root.dependenciesMet && root.isCapturing
                        theme: theme
                        countdown: root.countdown
                        onCancelClicked: root.cancelCapture()
                    }
                }
            }
            Keys.onEscapePressed: {
                if (root.isCapturing) root.cancelCapture();
                else mainWindow.visible = false;
            }
            focus: true
        }
    }
}
