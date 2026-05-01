import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: selector
    spacing: 0
    property var theme
    property string selectedAnnotator: "swappy"
    property bool swappyAvailable: true
    property bool sattyAvailable: true

    Text {
        Layout.fillWidth: true; Layout.bottomMargin: 8
        text: "ANNOTATION TOOL"
        color: selector.theme.mutedColor
        font { pixelSize: 10; weight: Font.Medium; letterSpacing: 1.5 }
    }

    RowLayout {
        Layout.fillWidth: true; Layout.bottomMargin: 16
        spacing: 8

        Repeater {
            model: [
                { key: "swappy", label: "Swappy", sub: "simple edit", available: selector.swappyAvailable },
                { key: "satty", label: "Satty", sub: "modern UI", available: selector.sattyAvailable }
            ]

            delegate: Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 52
                radius: 9
                property bool sel: selector.selectedAnnotator === modelData.key
                property bool enabled: modelData.available
                
                color: sel ? selector.theme.accentMed : (mHov.containsMouse && enabled ? selector.theme.surfaceHover : selector.theme.cardColor)
                border { color: sel ? selector.theme.accentBorder : "transparent"; width: 1 }
                opacity: enabled ? 1.0 : 0.4
                
                Behavior on color { ColorAnimation { duration: 110 } }
                Behavior on opacity { NumberAnimation { duration: 110 } }

                Column {
                    anchors.centerIn: parent; spacing: 2
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.label
                        color: sel ? selector.theme.accentColor : selector.theme.textColor
                        font { pixelSize: 12; weight: sel ? Font.Medium : Font.Normal }
                        Behavior on color { ColorAnimation { duration: 110 } }
                    }
                    Text { 
                        anchors.horizontalCenter: parent.horizontalCenter; 
                        text: enabled ? modelData.sub : "not installed"; 
                        color: selector.theme.mutedColor; 
                        font.pixelSize: 9 
                    }
                }
                HoverHandler { id: mHov; enabled: parent.enabled }
                TapHandler { 
                    enabled: parent.enabled
                    onTapped: {
                        selector.selectedAnnotator = modelData.key
                    }
                }
            }
        }
    }
}
