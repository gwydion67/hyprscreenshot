import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: selector
    spacing: 0
    property var theme
    property string selectedMode: "region"

    Text {
        Layout.fillWidth: true; Layout.bottomMargin: 8
        text: "CAPTURE MODE"
        color: selector.theme.mutedColor
        font { pixelSize: 10; weight: Font.Medium; letterSpacing: 1.5 }
    }

    GridLayout {
        Layout.fillWidth: true; Layout.bottomMargin: 16
        columns: 2; columnSpacing: 8; rowSpacing: 8

        Repeater {
            model: [
                { key: "region", label: "Region", sub: "drag to select", span: 2 },
                { key: "window", label: "Window", sub: "click a window", span: 1 },
                { key: "output", label: "Full Screen", sub: "whole display", span: 1 }
            ]

            delegate: Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 58; Layout.columnSpan: modelData.span
                radius: 9
                property bool sel: selector.selectedMode === modelData.key
                color: sel ? selector.theme.accentMed : (mHov.containsMouse ? selector.theme.surfaceHover : selector.theme.cardColor)
                border { color: sel ? selector.theme.accentBorder : "transparent"; width: 1 }
                Behavior on color { ColorAnimation { duration: 110 } }

                Column {
                    anchors.centerIn: parent; spacing: 3
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.label
                        color: sel ? selector.theme.accentColor : selector.theme.textColor
                        font { pixelSize: 13; weight: sel ? Font.Medium : Font.Normal }
                        Behavior on color { ColorAnimation { duration: 110 } }
                    }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.sub; color: selector.theme.mutedColor; font.pixelSize: 10 }
                }
                HoverHandler { id: mHov }; TapHandler { onTapped: selector.selectedMode = modelData.key }
            }
        }
    }
}
