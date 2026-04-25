import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: countdownView
    spacing: 10

    property var theme
    property int countdown: 0
    signal cancelClicked()

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 130
        radius: 12
        color: countdownView.theme.accentFaint
        border.color: countdownView.theme.accentBorder
        border.width: 1

        Column {
            anchors.centerIn: parent
            spacing: 6
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: countdownView.countdown > 0 ? countdownView.countdown.toString() : "…"
                color: countdownView.theme.accentColor
                font.pixelSize: 48
                font.weight: Font.Bold
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: countdownView.countdown > 0 ? "capturing in " + countdownView.countdown + (countdownView.countdown === 1 ? " second" : " seconds") : "capturing…"
                color: countdownView.theme.mutedColor
                font.pixelSize: 12
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 36
        radius: 8
        visible: countdownView.countdown > 0
        color: cxHov.containsMouse ? Qt.rgba(countdownView.theme.dangerColor.r, countdownView.theme.dangerColor.g, countdownView.theme.dangerColor.b, 0.18) : countdownView.theme.cardColor
        border.color: Qt.rgba(countdownView.theme.dangerColor.r, countdownView.theme.dangerColor.g, countdownView.theme.dangerColor.b, 0.35)
        border.width: 1
        Behavior on color { ColorAnimation { duration: 100 } }
        Text {
            anchors.centerIn: parent
            text: "Cancel"
            color: countdownView.theme.dangerColor
            font.pixelSize: 13
        }
        HoverHandler { id: cxHov }
        TapHandler {
            onTapped: countdownView.cancelClicked()
        }
    }

    Item {
        Layout.fillHeight: true
    }
}
