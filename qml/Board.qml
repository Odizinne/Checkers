pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Odizinne.Checkers

Rectangle {
    id: board
    color: "transparent"

    signal cellClicked(int row, int col)

    // Single wood texture for entire board
    Image {
        id: woodTexture
        anchors.fill: parent
        source: "qrc:/textures/wood.png"
        fillMode: Image.PreserveAspectCrop
        visible: false
    }

    // Pre-rendered wood texture effect (cached)
    MultiEffect {
        id: cachedWoodEffect
        source: woodTexture
        anchors.fill: parent
        colorization: 1
        colorizationColor: "#D4B896" // Neutral wood color
        opacity: 0.3
        visible: false
        layer.enabled: true // Cache the effect
    }

    // Board squares
    Grid {
        id: grid
        rows: GameLogic.boardSize
        columns: GameLogic.boardSize

        readonly property int cellSize: Math.floor(board.width / GameLogic.boardSize)
        width: cellSize * GameLogic.boardSize
        height: cellSize * GameLogic.boardSize
        anchors.centerIn: parent

        Repeater {
            model: GameLogic.boardModel

            Item {
                id: boardRec
                width: grid.cellSize
                height: grid.cellSize
                required property var model

                Rectangle {
                    anchors.fill: parent
                    color: (boardRec.model.row + boardRec.model.col) % 2 === 0 ? "#F0D9B5" : "#B58863"

                    // Simplified wood texture overlay using ShaderEffectSource
                    ShaderEffectSource {
                        anchors.fill: parent
                        sourceItem: cachedWoodEffect
                        sourceRect: Qt.rect(
                            boardRec.model.col * grid.cellSize,
                            boardRec.model.row * grid.cellSize,
                            grid.cellSize,
                            grid.cellSize
                        )
                        opacity: 0.4
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    visible: {
                        if (UserSettings.vsAI && !GameLogic.isPlayer1Turn && GameLogic.inChainCapture) {
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
