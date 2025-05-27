import QtQuick
import QtQuick.Controls.Material
import QtSensors
import Odizinne.Checkers

Page {
    id: easterEggPage
    Material.background: UserSettings.darkMode ? "#1C1C1C" : "#E3E3E3"

    property real friction: 0.98
    property real bounceDamping: 0.7
    property bool accelActive: false

    onVisibleChanged: {
        if (!visible) {
            resetEasterEgg()
        }
    }

    function resetEasterEgg() {
        accelActive = false
        frameAnimation.stop()
        bouncingPiece.anchors.centerIn = gameContainer
        bouncingPiece.velocityX = 0
        bouncingPiece.velocityY = 0
    }

    Accelerometer {
        id: accelerometer
        active: easterEggPage.visible
        dataRate: 60

        onReadingChanged: {
            if (reading && easterEggPage.accelActive) {
                // Fixed axis mapping
                let tiltX = -reading.x * 0.1
                let tiltY = reading.y * 0.1

                // Apply tilt as force
                bouncingPiece.velocityX += tiltX
                bouncingPiece.velocityY += tiltY

                // Cap velocity
                bouncingPiece.velocityX = Math.max(-6, Math.min(6, bouncingPiece.velocityX))
                bouncingPiece.velocityY = Math.max(-6, Math.min(6, bouncingPiece.velocityY))
            }
        }
    }

    Rectangle {
        id: gameContainer
        anchors.fill: parent
        color: "transparent"

        Rectangle {
            id: bouncingPiece
            width: 60
            height: 60
            radius: 30
            color: UserSettings.darkMode ? "#F5F5F5" : "#3C3C3C"
            border.width: 2
            border.color: UserSettings.darkMode ? "#E0E0E0" : "#2C2C2C"

            anchors.centerIn: parent

            property real velocityX: 0
            property real velocityY: 0

            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 0.7
                height: width
                radius: width / 2
                color: UserSettings.darkMode ? "#D0D0D0" : "#1F1F1F"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (!easterEggPage.accelActive) {
                        // Start accelerometer physics
                        bouncingPiece.anchors.centerIn = undefined
                        bouncingPiece.x = easterEggPage.width / 2 - bouncingPiece.width / 2
                        bouncingPiece.y = easterEggPage.height / 2 - bouncingPiece.height / 2

                        easterEggPage.accelActive = true
                        frameAnimation.start()
                        AudioEngine.playMove()
                    }
                }
            }

            FrameAnimation {
                id: frameAnimation
                running: false

                onTriggered: {
                    // Apply friction
                    bouncingPiece.velocityX *= easterEggPage.friction
                    bouncingPiece.velocityY *= easterEggPage.friction

                    // Move piece
                    bouncingPiece.x += bouncingPiece.velocityX
                    bouncingPiece.y += bouncingPiece.velocityY

                    // Bounce off walls
                    if (bouncingPiece.x <= 0) {
                        bouncingPiece.x = 0
                        bouncingPiece.velocityX = -bouncingPiece.velocityX * easterEggPage.bounceDamping
                    }

                    if (bouncingPiece.x >= easterEggPage.width - bouncingPiece.width) {
                        bouncingPiece.x = easterEggPage.width - bouncingPiece.width
                        bouncingPiece.velocityX = -bouncingPiece.velocityX * easterEggPage.bounceDamping
                    }

                    if (bouncingPiece.y <= 0) {
                        bouncingPiece.y = 0
                        bouncingPiece.velocityY = -bouncingPiece.velocityY * easterEggPage.bounceDamping
                    }

                    if (bouncingPiece.y >= easterEggPage.height - bouncingPiece.height) {
                        bouncingPiece.y = easterEggPage.height - bouncingPiece.height
                        bouncingPiece.velocityY = -bouncingPiece.velocityY * easterEggPage.bounceDamping
                    }
                }
            }
        }
    }
}
