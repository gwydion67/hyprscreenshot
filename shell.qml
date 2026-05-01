// ┌─────────────────────────────────────────────────────────────────────────┐
// │  hyprscreenshot — QuickShell wrapper for hyprshot                       │
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
    property bool hyprshotInstalled: false
    property bool swappyInstalled: false
    property bool sattyInstalled: false
    readonly property bool dependenciesMet: hyprshotInstalled && (swappyInstalled || sattyInstalled)

    onHyprshotInstalledChanged: console.log("[Debug] hyprshotInstalled:", hyprshotInstalled)
    onSwappyInstalledChanged: console.log("[Debug] swappyInstalled:", swappyInstalled)
    onSattyInstalledChanged: console.log("[Debug] sattyInstalled:", sattyInstalled)
    onDependenciesMetChanged: console.log("[Debug] dependenciesMet:", dependenciesMet)

    Theme { id: theme }

    // ── Dependency Check ──────────────────────────────────────────────────
    function runDepCheck() { 
        console.log("[Debug] Triggering dependency check...");
        depChecker.running = true; 
    }

    Process {
        id: depChecker
        command: ["bash", "-c", "echo \"{\\\"h\\\": $(which hyprshot >/dev/null 2>&1 && echo true || echo false), \\\"s\\\": $(which swappy >/dev/null 2>&1 && echo true || echo false), \\\"sat\\\": $(which satty >/dev/null 2>&1 && echo true || echo false)}\" > /tmp/hss_deps.json"]
        onRunningChanged: if (!running) depFileReader.reload()
    }

    FileView {
        id: depFileReader
        path: "/tmp/hss_deps.json"
        onLoaded: {
            try {
                var res = JSON.parse(text());
                root.hyprshotInstalled = !!res.h;
                root.swappyInstalled = !!res.s;
                root.sattyInstalled = !!res.sat;
                
                // Fallback if selected annotator is not installed
                if (theme.annotator === "swappy" && !root.swappyInstalled && root.sattyInstalled) {
                    theme.annotator = "satty";
                    theme.saveConfig();
                } else if (theme.annotator === "satty" && !root.sattyInstalled && root.swappyInstalled) {
                    theme.annotator = "swappy";
                    theme.saveConfig();
                }

                console.log("[Debug] Dependency file loaded:", text().trim());
            } catch(e) {
                console.log("[Error] Dependency parse failed");
            }
        }
    }

    // ── Capture Logic ──────────────────────────────────────────────────────
    Process { 
        id: captureProc
        onRunningChanged: if (!running) {
            console.log("[Debug] Capture process finished");
            root.isCapturing = false;
        }
    }

    Timer {
        id: countdownTimer
        interval: 1000
        repeat: true
        onTriggered: {
            if (--root.countdown <= 0) {
                stop();
                mainWindow.visible = false;
                freezeDelay.start();
            }
        }
    }

    Timer { 
        id: freezeDelay
        interval: 380
        onTriggered: runHyprshot() 
    }

    function startCapture() {
        if (!dependenciesMet) return;
        console.log("[Debug] Starting capture with mode:", selectedMode, "delay:", selectedDelay);
        if (selectedDelay === 0) {
            mainWindow.visible = false;
            freezeDelay.start();
        } else {
            root.countdown = selectedDelay;
            root.isCapturing = true;
            countdownTimer.start();
        }
    }

    function runHyprshot() {
        var modeFlags = "-m " + selectedMode;
        if (selectedMode === "output") modeFlags += " -m active";
        
        var cursorFlag = theme.showCursor ? " --cursor" : "";
        var annotatorCmd = theme.annotator === "satty" ? "satty --filename -" : "swappy -f -";
        var cmd = "hyprshot " + modeFlags + cursorFlag + " --freeze --raw | " + annotatorCmd;
        
        console.log("[Debug] Running command:", cmd);
        captureProc.command = ["bash", "-c", cmd];
        captureProc.running = true;
    }

    function cancelCapture() {
        console.log("[Debug] Capture cancelled");
        countdownTimer.stop();
        root.isCapturing = false;
        root.countdown = 0;
    }

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
            if (isCapturing) cancelCapture();
            mainWindow.visible = false;
        }
    }

    FloatingWindow {
        id: mainWindow
        visible: false
        implicitWidth: 420
        implicitHeight: !dependenciesMet ? 280 : (isCapturing ? 230 : 500)
        color: "transparent"
        onVisibleChanged: {
            if (visible) {
                theme.reload();
                runDepCheck();
            }
        }

        Rectangle {
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

                    // Error UI
                    ColumnLayout {
                        anchors.fill: parent
                        visible: !dependenciesMet
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
                                    font { pixelSize: 12; weight: Font.Bold; letterSpacing: 1.2 } 
                                }
                                Text { 
                                    Layout.alignment: Qt.AlignHCenter
                                    text: (hyprshotInstalled ? "" : "• hyprshot\n") + 
                                          ((!swappyInstalled && !sattyInstalled) ? "• swappy or satty" : "")
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
                                    border { color: theme.mutedColor; width: 1 }
                                    Text { 
                                        anchors.centerIn: parent
                                        text: "Check Again"
                                        color: theme.textColor
                                        font.pixelSize: 11 
                                    }
                                    HoverHandler { id: retryHov }
                                    TapHandler { onTapped: runDepCheck() }
                                }
                            }
                        }
                        Item { Layout.fillHeight: true }
                    }

                    // Main UI
                    ColumnLayout {
                        anchors.fill: parent
                        visible: dependenciesMet && !isCapturing
                        spacing: 0
                        
                        CaptureModeSelector { 
                            theme: theme
                            selectedMode: root.selectedMode
                            onSelectedModeChanged: root.selectedMode = selectedMode 
                        }

                        AnnotatorSelector {
                            theme: theme
                            selectedAnnotator: theme.annotator
                            swappyAvailable: root.swappyInstalled
                            sattyAvailable: root.sattyInstalled
                            onSelectedAnnotatorChanged: {
                                theme.annotator = selectedAnnotator;
                                theme.saveConfig();
                            }
                        }
                        
                        DelaySelector { 
                            theme: theme
                            selectedDelay: root.selectedDelay
                            onSelectedDelayChanged: root.selectedDelay = selectedDelay 
                        }

                        // Cursor Toggle
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: 12
                            Layout.bottomMargin: 16
                            spacing: 8
                            
                            Text {
                                text: "CAPTURE CURSOR"
                                color: theme.mutedColor
                                font { pixelSize: 10; weight: Font.Medium; letterSpacing: 1.5 }
                                Layout.fillWidth: true
                            }
                            
                            Rectangle {
                                width: 34; height: 18; radius: 9
                                color: theme.showCursor ? theme.accentColor : theme.cardColor
                                border { color: theme.showCursor ? "transparent" : theme.mutedColor; width: 1 }
                                Behavior on color { ColorAnimation { duration: 150 } }
                                
                                Rectangle {
                                    width: 12; height: 12; radius: 6
                                    color: theme.showCursor ? theme.accentText : theme.mutedColor
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: theme.showCursor ? 18 : 4
                                    Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                                }
                                
                                TapHandler { 
                                    onTapped: {
                                        theme.showCursor = !theme.showCursor;
                                        theme.saveConfig();
                                    }
                                }
                            }
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
                                text: selectedDelay > 0 ? "Capture in " + selectedDelay + "s" : "Capture Now"
                                color: theme.accentText
                                font { pixelSize: 14; weight: Font.Medium } 
                            }
                            
                            HoverHandler { id: capHov }
                            TapHandler { onTapped: startCapture() }
                        }
                    }

                    CountdownView { 
                        anchors.fill: parent
                        visible: dependenciesMet && isCapturing
                        theme: theme
                        countdown: root.countdown
                        onCancelClicked: cancelCapture() 
                    }
                }
            }
            Keys.onEscapePressed: isCapturing ? cancelCapture() : (mainWindow.visible = false)
            Keys.onReturnPressed: if (dependenciesMet && !isCapturing) startCapture()
            Keys.onEnterPressed: if (dependenciesMet && !isCapturing) startCapture()
            focus: true
        }
    }
    Component.onCompleted: runDepCheck()
}
