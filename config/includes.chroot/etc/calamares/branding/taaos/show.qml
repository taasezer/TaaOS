import QtQuick 2.5

Presentation {
    id: presentation

    Slide {
        anchors.fill: parent
        
        Text {
            anchors.centerIn: parent
            text: "Welcome to TaaOS Installation"
            font.pixelSize: 32
            font.bold: true
            color: "#ffffff"
        }
        
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.verticalCenter
            anchors.topMargin: 50
            text: "Fault-Tolerant Debian for Engineering"
            font.pixelSize: 18
            color: "#cccccc"
        }
    }
    
    Slide {
        anchors.fill: parent
        
        Text {
            anchors.centerIn: parent
            text: "Installing System Files..."
            font.pixelSize: 28
            color: "#ffffff"
        }
        
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.verticalCenter
            anchors.topMargin: 40
            text: "This may take several minutes"
            font.pixelSize: 16
            color: "#aaaaaa"
        }
    }
    
    Slide {
        anchors.fill: parent
        
        Text {
            anchors.centerIn: parent
            text: "Configuring Your System..."
            font.pixelSize: 28
            color: "#ffffff"
        }
        
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.verticalCenter
            anchors.topMargin: 40
            text: "Setting up bootloader and user accounts"
            font.pixelSize: 16
            color: "#aaaaaa"
        }
    }
}
