import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick
import Odizinne.Checkers

Popup {
    id: gameoverpopup
    modal: true
    visible: false

    ColumnLayout {
        anchors.fill: parent
        spacing: 15

        Label {
            text: (GameLogic.winner === 1 ? "White" : "Black") + " won"
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 20
            font.bold: true
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 15
            property int buttonWidth: Math.max(newGameButton.implicitWidth, closeButton.implicitWidth) + 30
            Button {
                id: newGameButton
                Layout.preferredWidth: parent.buttonWidth
                text: qsTr("Restart")
                onClicked: {
                    GameLogic.initializeBoard()
                    gameoverpopup.close()
                }
            }

            Button {
                id: closeButton
                text: qsTr("Close")
                Layout.preferredWidth: parent.buttonWidth
                onClicked: {
                    gameoverpopup.close()
                }

            }
        }
    }
}
