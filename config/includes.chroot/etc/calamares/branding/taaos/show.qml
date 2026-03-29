import QtQuick 2.0;
import calamares.slideshow 1.0;

Presentation {
    id: presentation

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: presentation.goToNextSlide()
    }
    
    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#1a1a2e"
            
            Text {
                anchors.centerIn: parent
                text: "Welcome to TaaOS"
                color: "#00d4ff"
                font.pixelSize: 48
                font.bold: true
            }
            
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.verticalCenter
                anchors.topMargin: 60
                text: "Engineering Excellence in Every Byte"
                color: "#ffffff"
                font.pixelSize: 24
            }
        }
    }

    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#1a1a2e"

            Text {
                anchors.centerIn: parent
                text: "Custom Kernel + AI-Powered"
                color: "#00d4ff"
                font.pixelSize: 32
                font.bold: true
            }
        }
    }
}
