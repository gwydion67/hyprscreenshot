import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: delaySelector
    spacing: 0
    property var theme
    property int selectedDelay: 0

    Text {
        Layout.fillWidth: true; Layout.bottomMargin: 8
        text: "DELAY"
        color: theme.mutedColor
        font { pixelSize: 10; weight: Font.Medium; letterSpacing: 1.5 }
    }

    RowLayout {
        Layout.fillWidth: true; spacing: 8

        Rectangle {
            Layout.preferredWidth: 36; Layout.preferredHeight: 36; radius: 8
            color: minHov.containsMouse ? theme.surfaceHover : theme.cardColor
            Text { anchors.centerIn: parent; text: "−"; color: selectedDelay > 0 ? theme.textColor : theme.mutedColor; font.pixelSize: 20 }
            HoverHandler { id: minHov }
            TapHandler { onTapped: if (selectedDelay > 0) selectedDelay-- }
        }

        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 36; radius: 8
            color: delayInput.activeFocus ? theme.accentFaint : theme.cardColor
            border { color: delayInput.activeFocus ? theme.accentBorder : "transparent"; width: 1 }

            Row {
                anchors.centerIn: parent; spacing: 4
                TextInput {
                    id: delayInput
                    text: selectedDelay.toString()
                    color: theme.textColor
                    font { pixelSize: 14; weight: Font.Medium }
                    width: 28; horizontalAlignment: TextInput.AlignHCenter
                    selectByMouse: true; validator: IntValidator { bottom: 0; top: 999 }
                    onEditingFinished: {
                        var v = parseInt(text);
                        selectedDelay = isNaN(v) ? 0 : v;
                        text = selectedDelay.toString();
                    }
                    onTextChanged: {
                        var v = parseInt(text);
                        if (!isNaN(v) && v >= 0) selectedDelay = v;
                    }
                    Binding { target: delayInput; property: "text"; value: selectedDelay.toString(); when: !delayInput.activeFocus }
                }
                Text { anchors.verticalCenter: parent.verticalCenter; text: "sec"; color: theme.mutedColor; font.pixelSize: 11 }
            }
        }

        Rectangle {
            Layout.preferredWidth: 36; Layout.preferredHeight: 36; radius: 8
            color: plusHov.containsMouse ? theme.surfaceHover : theme.cardColor
            Text { anchors.centerIn: parent; text: "+"; color: theme.textColor; font.pixelSize: 20 }
            HoverHandler { id: plusHov }
            TapHandler { onTapped: selectedDelay++ }
        }
    }
}
