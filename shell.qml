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
    
    // Dependency State
    property bool hyprshotInstalled: true
    property bool swappyInstalled: true
    readonly property bool dependenciesMet: hyprshotInstalled && swappyInstalled

    // ── Theme ──────────────────────────────────────────────────────────────
    Theme {
        id: theme
    }

    // ── Dependency Check ──────────────────────────────────────────────────
    Process {
        id: checkHyprshot
        command: ["which", "hyprshot"]
        onRunningChanged: if (!running) root.hyprshotInstalled = (checkHyprshot.exitCode === 0)
    }
    Process {
        id: checkSwappy
        command: ["which", "swappy"]
        onRunningChanged: if (!running) root.swappyInstalled = (checkSwappy.exitCode === 0)
    }

    Component.onCompleted: {
        checkHyprshot.running = true;
        checkSwappy.running = true;
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
        implicitHeight: !root.dependenciesMet ? 250 : (root.isCapturing ? 230 : 420)

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

                    // ── Dependency Error UI ──────────────────────────────
                    ColumnLayout {
                        anchors.fill: parent
                        visible: !root.dependenciesMet
                        spacing: 15

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 120
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
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "Please install them to continue"
                                    color: theme.mutedColor
                                    font.pixelSize: 10
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
                        visible: root.dependenciesMet && root.isCapturing
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
