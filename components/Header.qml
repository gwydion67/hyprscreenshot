import QtQuick
import QtQuick.Layouts

RowLayout {
    id: header
    Layout.fillWidth: true
    Layout.bottomMargin: 18
    spacing: 10

    property var theme
    signal closeClicked()

    Rectangle {
        Layout.preferredWidth: 32
        Layout.preferredHeight: 32
        radius: 8
        color: header.theme.accentFaint
        border.color: header.theme.accentBorder
        border.width: 1
        Text {
            anchors.centerIn: parent
            text: "⊙"
            color: header.theme.accentColor
            font.pixelSize: 15
        }
    }

    Column {
        spacing: 1
        Text {
            text: "Screenshot"
            color: header.theme.textColor
            font.pixelSize: 15
            font.weight: Font.Medium
        }
        Text {
            text: "hyprshot · swappy"
            color: header.theme.mutedColor
            font.pixelSize: 10
        }
    }

    Item {
        Layout.fillWidth: true
    }

    Rectangle {
        Layout.preferredWidth: 26
        Layout.preferredHeight: 26
        radius: 6
        color: xHov.containsMouse ? Qt.rgba(header.theme.dangerColor.r, header.theme.dangerColor.g, header.theme.dangerColor.b, 0.18) : "transparent"
        Behavior on color {
            ColorAnimation {
                duration: 100
            }
        }
        Text {
            anchors.centerIn: parent
            text: "✕"
            color: xHov.containsMouse ? header.theme.dangerColor : header.theme.mutedColor
            font.pixelSize: 11
        }
        HoverHandler {
            id: xHov
        }
        TapHandler {
            onTapped: header.closeClicked()
        }
    }
}
