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

    // ── Theme ──────────────────────────────────────────────────────────────
    Theme {
        id: theme
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
            if (!mainWindow.visible)
                theme.reload();
            mainWindow.visible = !mainWindow.visible;
        }
        function open() {
            theme.reload();
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
        implicitHeight: root.isCapturing ? 230 : 420

        color: "transparent"
        onVisibleChanged: {
            if (visible)
                theme.reload();
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

            // Rim light highlight
            Rectangle {
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: 1
                color: theme.rimLight
            }

            ColumnLayout {
                anchors { fill: parent; margins: 20 }
                spacing: 0

                // ── Header ──────────────────────────────────────────────
                Header {
                    theme: theme
                    onCloseClicked: mainWindow.visible = false
                }

                // ── Content Area Wrapper ─────────────────────────────────
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    // ── Setup UI ─────────────────────────────────────────
                    ColumnLayout {
                        anchors.fill: parent
                        visible: !root.isCapturing
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

                        // ── Capture Button ───────────────────────────────
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
                        visible: root.isCapturing
                        theme: theme
                        countdown: root.countdown
                        onCancelClicked: root.cancelCapture()
                    }
                }
            } // End ColumnLayout

            Keys.onEscapePressed: {
                if (root.isCapturing) root.cancelCapture();
                else mainWindow.visible = false;
            }
            focus: true
        } // Rectangle card
    }   // FloatingWindow
} // ShellRoot
