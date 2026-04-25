import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: delaySelector
    spacing: 0

    property var theme
    property int selectedDelay: 0

    Text {
        Layout.fillWidth: true
        Layout.bottomMargin: 8
        text: "DELAY"
        color: delaySelector.theme.mutedColor
        font.pixelSize: 10
        font.weight: Font.Medium
        font.letterSpacing: 1.5
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Rectangle {
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36
            radius: 8
            color: minHov.containsMouse ? delaySelector.theme.surfaceHover : delaySelector.theme.cardColor
            Behavior on color { ColorAnimation { duration: 100 } }
            Text {
                anchors.centerIn: parent
                text: "−"
                color: delaySelector.selectedDelay > 0 ? delaySelector.theme.textColor : delaySelector.theme.mutedColor
                font.pixelSize: 20
            }
            HoverHandler { id: minHov }
            TapHandler {
                onTapped: if (delaySelector.selectedDelay > 0) delaySelector.selectedDelay--
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            radius: 8
            color: delayInput.activeFocus ? delaySelector.theme.accentFaint : delaySelector.theme.cardColor
            border.color: delayInput.activeFocus ? delaySelector.theme.accentBorder : "transparent"
            border.width: 1
            Behavior on color { ColorAnimation { duration: 100 } }
            Behavior on border.color { ColorAnimation { duration: 100 } }

            Row {
                anchors.centerIn: parent
                spacing: 4

                TextInput {
                    id: delayInput
                    text: delaySelector.selectedDelay.toString()
                    color: delaySelector.theme.textColor
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    width: 28
                    horizontalAlignment: TextInput.AlignHCenter
                    selectByMouse: true
                    validator: IntValidator { bottom: 0; top: 999 }

                    onEditingFinished: {
                        var v = parseInt(text);
                        delaySelector.selectedDelay = isNaN(v) ? 0 : v;
                        text = delaySelector.selectedDelay.toString();
                    }
                    onTextChanged: {
                        var v = parseInt(text);
                        if (!isNaN(v) && v >= 0) delaySelector.selectedDelay = v;
                    }
                    Connections {
                        target: delaySelector
                        function onSelectedDelayChanged() {
                            if (!delayInput.activeFocus)
                                delayInput.text = delaySelector.selectedDelay.toString();
                        }
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "sec"
                    color: delaySelector.theme.mutedColor
                    font.pixelSize: 11
                }
            }
        }

        Rectangle {
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36
            radius: 8
            color: plusHov.containsMouse ? delaySelector.theme.surfaceHover : delaySelector.theme.cardColor
            Behavior on color { ColorAnimation { duration: 100 } }
            Text {
                anchors.centerIn: parent
                text: "+"
                color: delaySelector.theme.textColor
                font.pixelSize: 20
            }
            HoverHandler { id: plusHov }
            TapHandler {
                onTapped: delaySelector.selectedDelay++
            }
        }
    }
}
