import QtQuick 2.0
import QtQuick.Controls 2.0

Item {
    id: presentation
    anchors.fill: parent

    Rectangle {
        anchors.fill: parent
        color: "#0D1117"

        Column {
            anchors.centerIn: parent
            spacing: 16

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "TaaOS 2.0"
                font.pixelSize: 32
                font.bold: true
                color: "#D40000"
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Developer Distribution — Deterministic, Fast, Modular"
                font.pixelSize: 14
                color: "#E5E9F0"
            }
        }
    }
}
