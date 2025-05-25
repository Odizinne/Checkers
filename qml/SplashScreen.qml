import QtQuick
import Odizinne.Checkers

Item {
    opacity: 0
    id: splashScreen
    layer.enabled: true
    z: 1000
    onOpacityChanged: {
        if (splashScreen.opacity === 1) {
            hideTimer.start()
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: 400
            easing.type: Easing.OutQuad
        }
    }

    Rectangle {
        color: "#040504"
        anchors.fill: parent

        Image {
            source: "qrc:/images/splash.png"
            sourceSize.width: 192
            sourceSize.height: 192
            anchors.centerIn: parent
            height: 192
            width: 192
        }
    }

    Timer {
        id: hideTimer
        interval: 2000
        repeat: false
        running: false
        onTriggered: {
            splashScreen.opacity = 0
            GameLogic.initializeBoard()
        }
    }
}
