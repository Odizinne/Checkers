pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import Odizinne.Checkers

Popup {
    id: control
    width: 350
    height: 500
    modal: true
    visible: false
    Material.background: UserSettings.darkMode ? "#1C1C1C" : "#E3E3E3"
    Material.roundedScale: Material.SmallScale

    ColumnLayout {
        anchors.fill: parent
        anchors.rightMargin: 6
        anchors.leftMargin: 6
        spacing: 18

        Label {
            text: qsTr("How to play Checkers")
            font.pixelSize: 22
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        Pane {
            Layout.fillWidth: true
            Layout.preferredHeight: 370
            Material.roundedScale: Material.SmallScale
            Material.elevation: 6
            Material.background: UserSettings.darkMode ? "#2B2B2B" : "#FFFFFF"
            ScrollingArea {
                id: scrollArea
                anchors.fill: parent
                contentWidth: width - 12
                contentHeight: textContainer.height

                Item {
                    id: textContainer
                    anchors.centerIn: parent
                    width: scrollArea.width - 12
                    height: rulesText.height

                    Text {
                        id: rulesText
                        anchors.centerIn: parent
                        width: textContainer.width
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

        Button {
            text: qsTr("Close")
            Layout.alignment: Qt.AlignRight
            Layout.bottomMargin: 10
            onClicked: control.visible = false
            Material.roundedScale: Material.SmallScale
        }
    }
}

