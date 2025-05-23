import QtQuick
import QtQuick.Effects

Rectangle {
    id: board
    color: "transparent"

    signal cellClicked(int row, int col)

    // Single wood texture for entire board
    Image {
        id: woodTexture
        anchors.fill: parent
        source: "qrc:/icons/wood_texture.png"
        fillMode: Image.PreserveAspectCrop
        visible: false  // We'll use this as source for MultiEffect
    }

    // Board squares with wood texture applied
    Grid {
        anchors.fill: parent
        rows: GameLogic.boardSize
        columns: GameLogic.boardSize

        Repeater {
            model: GameLogic.boardModel

            Rectangle {
                id: boardRec
                width: board.width / GameLogic.boardSize
                height: board.height / GameLogic.boardSize
                color: "transparent"
                required property var model

                // Clipped portion of the wood texture with square color
                Item {
                    anchors.fill: parent
                    clip: true

                    // Base color
                    Rectangle {
                        anchors.fill: parent
                        color: (boardRec.model.row + boardRec.model.col) % 2 === 0 ? "#F0D9B5" : "#B58863"
                    }

                    // Subtle wood texture overlay
                    MultiEffect {
                        source: woodTexture
                        width: board.width
                        height: board.height
                        x: -boardRec.model.col * boardRec.width
                        y: -boardRec.model.row * boardRec.height
                        colorization: 1.0
                        colorizationColor: (boardRec.model.row + boardRec.model.col) % 2 === 0 ? "#F0D9B5" : "#B58863"
                        opacity: 0.4
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    visible: {
                        // Don't show valid moves during AI chain capture
                        if (GameLogic.vsAI && !GameLogic.isPlayer1Turn && GameLogic.inChainCapture) {
                            return false
                        }

                        if (GameLogic.inChainCapture && GameLogic.chainCapturePosition) {
                            return GameLogic.isValidMove(GameLogic.chainCapturePosition.row, GameLogic.chainCapturePosition.col, boardRec.model.row, boardRec.model.col)
                        } else if (GameLogic.selectedPiece) {
                            return GameLogic.isValidMove(GameLogic.selectedPiece.row, GameLogic.selectedPiece.col, boardRec.model.row, boardRec.model.col)
                        }
                        return false
                    }
                    border.width: 3
                    border.color: GameLogic.inChainCapture ? "#E74C3C" : "#27AE60"

                    Rectangle {
                        anchors.centerIn: parent
                        width: 10
                        height: 10
                        radius: 5
                        color: GameLogic.inChainCapture ? "#E74C3C" : "#27AE60"
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: board.cellClicked(boardRec.model.row, boardRec.model.col)
                }
            }
        }
    }
}
