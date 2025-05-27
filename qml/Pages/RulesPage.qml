pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Material
import Odizinne.Checkers

Page {
    id: rulesPage
    Material.background: UserSettings.darkMode ? "#1C1C1C" : "#E3E3E3"

    signal navigateBack()

    header: ToolBar {
        Material.elevation: 6
        Material.background: UserSettings.darkMode ? "#2B2B2B" : "#FFFFFF"

        ToolButton {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            icon.source: "qrc:/icons/back.svg"
            icon.color: UserSettings.darkMode ? "white" : "black"
            onClicked: rulesPage.navigateBack()
            icon.width: 18
            icon.height: 18
        }

        Label {
            text: qsTr("How to play Checkers")
            color: UserSettings.darkMode ? "white" : "black"
            anchors.centerIn: parent
            font.pixelSize: 18
            font.bold: true
        }
    }

    ScrollingArea {
        id: scrollArea
        anchors.fill: parent
        contentWidth: width
        contentHeight: textContainer.height + 20

        Item {
            id: textContainer
            width: scrollArea.width
            height: rulesText.height + 20
            anchors.top: parent.top
            anchors.topMargin: 10

            Text {
                id: rulesText
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 15
                anchors.rightMargin: 15
                anchors.top: parent.top
                anchors.topMargin: 10
                wrapMode: Text.WordWrap
                textFormat: Text.StyledText
                lineHeight: 1.2
                font.pixelSize: 14
                color: Material.foreground
                text: qsTr(`<h2>Objective</h2>
                           <p>Capture all of your opponent's pieces or block them so they cannot move.</p>
                           <h3>Game Elements</h3>
                           <p><b>• Regular Pieces:</b> Move diagonally forward one square at a time. When they reach the opposite end of the board, they become kings.
                           <br><b>• Kings:</b> Can move diagonally in any direction (forward or backward).
                           <br><b>• Captures:</b> Jump over an opponent's piece diagonally to capture it. The captured piece is removed from the board.
                           <br><b>• Multiple Captures:</b> If you can capture another piece after your first capture, you must continue capturing with the same piece.</p>
                           <h3>Basic Rules</h3>
                           <p><b>• Movement:</b> Pieces move diagonally on dark squares only.
                           <br><b>• Mandatory Captures:</b> If you can capture an opponent's piece, you must do so.
                           <br><b>• Turn Order:</b> Players alternate turns, with white typically moving first.
                           <br><b>• Promotion:</b> When a regular piece reaches the far end of the board, it becomes a king.</p>
                           <h3>Game Strategies</h3>
                           <p><b>• Control the center:</b> Central squares give you more movement options and control.
                           <br><b>• Protect your back row:</b> Keep pieces on your back row to prevent opponent pieces from becoming kings.
                           <br><b>• Force trades when ahead:</b> If you have more pieces, trading pieces equally benefits you.
                           <br><b>• Look for multiple captures:</b> Set up moves that force your opponent into positions where you can capture multiple pieces.</p>
                           <h3>Winning the Game</h3>
                           <p>You win by capturing all opponent pieces or blocking all their possible moves. The game is a draw if neither player can make progress.</p>
                           <p>Good luck and enjoy the game!</p>`)
            }
        }
    }
}
