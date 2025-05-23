import QtQuick

Rectangle {
    id: board
    width: GameLogic.boardSize * GameLogic.cellSize
    height: GameLogic.boardSize * GameLogic.cellSize
    color: "transparent"

    signal cellClicked(int row, int col)

    // Board squares
    Grid {
        rows: GameLogic.boardSize
        columns: GameLogic.boardSize

        Repeater {
            model: GameLogic.boardModel

            Rectangle {
                id: boardRec
                width: GameLogic.cellSize
                height: GameLogic.cellSize
                color: (model.row + model.col) % 2 === 0 ? "#F0D9B5" : "#B58863"
                required property var model

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
