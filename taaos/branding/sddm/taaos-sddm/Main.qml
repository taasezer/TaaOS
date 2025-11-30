import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    width: 1920
    height: 1080
    color: "#0A0A0A"
    
    Image {
        id: background
        source: "background.png"
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
    }
    
    Image {
        id: logo
        source: "taaos-logo.png"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 100
        width: 300
        height: 100
        fillMode: Image.PreserveAspectFit
    }
    
    Rectangle {
        id: loginBox
        width: 400
        height: 300
        color: "#1A1A1A"
        border.color: "#D40000"
        border.width: 2
        radius: 10
        anchors.centerIn: parent
        
        Column {
            anchors.centerIn: parent
            spacing: 20
            
            TextField {
                id: usernameField
                width: 350
                placeholderText: "Username"
                color: "#F5F5F0"
                background: Rectangle {
                    color: "#2B2B2B"
                    border.color: "#D40000"
                    radius: 5
                }
            }
            
            TextField {
                id: passwordField
                width: 350
                placeholderText: "Password"
                echoMode: TextInput.Password
                color: "#F5F5F0"
                background: Rectangle {
                    color: "#2B2B2B"
                    border.color: "#D40000"
                    radius: 5
                }
            }
            
            Button {
                text: "Login"
                width: 350
                background: Rectangle {
                    color: "#D40000"
                    radius: 5
                }
                contentItem: Text {
                    text: parent.text
                    color: "#F5F5F0"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }
}
