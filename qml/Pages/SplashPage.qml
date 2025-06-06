import QtQuick
import QtQuick.Controls.Material
import Odizinne.Checkers

Page {
    id: splashPage
    Material.background: UserSettings.darkMode ? "#1C1C1C" : "#E3E3E3"
    
    signal navigateToGame()

    FontLoader {
        id: jbBold
        source: "qrc:/fonts/JetBrainsMonoNL-Bold.ttf"
    }

    FontLoader {
        id: jbLight
        source: "qrc:/fonts/JetBrainsMonoNL-Light.ttf"
    }

    Rectangle {
        color: UserSettings.darkMode ? "#1C1C1C" : "#E3E3E3"
        anchors.fill: parent

        Rectangle {
            id: circle
            width: 250
            height: 250
            radius: width / 2
            color: "transparent"
            border.width: 3
            border.color: UserSettings.darkMode ? "#E3E3E3" : "#1C1C1C"
            anchors.centerIn: parent

            Column {
                anchors.centerIn: parent
                spacing: 20

                Column {
                    spacing: 3
                    anchors.horizontalCenter: parent.horizontalCenter

                    Label {
                        text: "Odizinne"
                        color: UserSettings.darkMode ? "#E3E3E3" : "#1C1C1C"
                        font.family: jbBold.name
                        font.letterSpacing: -2
                        font.pixelSize: 36
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Label {
                        id: subtitleLabel
                        text: "Crafted in the Open"
                        color: UserSettings.darkMode ? "#CCCCCC" : "#333333"
                        font.family: jbLight.name
                        font.pixelSize: 14
                        anchors.horizontalCenter: parent.horizontalCenter
                        opacity: 0.8
                    }
                }

                Rectangle {
                    id: progressContainer
                    width: subtitleLabel.width
                    height: 3
                    radius: 1.5
                    color: UserSettings.darkMode ? "#333333" : "#CCCCCC"
                    anchors.horizontalCenter: parent.horizontalCenter

                    Rectangle {
                        id: progressFill
                        height: parent.height
                        radius: parent.radius
                        color: UserSettings.darkMode ? "#E3E3E3" : "#1C1C1C"
                        width: 0

                        NumberAnimation {
                            id: progressAnimation
                            target: progressFill
                            property: "width"
                            from: 0
                            to: progressContainer.width
                            duration: hideTimer.interval
                            easing.type: Easing.OutQuad
                        }
                    }
                }
            }
        }
    }

    Timer {
        id: hideTimer
        interval: 2000
        repeat: false
        running: true
        onTriggered: {
            splashPage.navigateToGame()
        }
    }

    Component.onCompleted: {
        hideTimer.start()
        progressAnimation.start()
    }
}
