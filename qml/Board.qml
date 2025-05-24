pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Odizinne.Checkers

Rectangle {
    id: board
    color: "transparent"

    signal cellClicked(int row, int col)

    property bool allItemsCreated: false
    property int createdItemsCount: 0
    readonly property int totalItems: GameLogic.boardModel ? GameLogic.boardModel.count : 0

    // Add state management to prevent Grid size changes during model updates
    property int currentBoardSize: GameLogic.boardSize
    property bool modelClearing: false

    // Watch for board size changes
    Connections {
        target: GameLogic
        function onBoardSizeChanged() {
            // Mark that we're about to clear the model
            board.modelClearing = true
        }
    }

    // Watch for model changes
    Connections {
        target: GameLogic.boardModel
        function onCountChanged() {
            if (GameLogic.boardModel.count === 0 && board.modelClearing) {
                // Model is now empty, safe to update board size
                board.currentBoardSize = GameLogic.boardSize
                board.modelClearing = false
            }
        }
    }

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
        enabled: UserSettings.enableWood // Disable processing when not needed
        layer.enabled: true // Cache the effect
    }

    // Board squares
    Grid {
        id: grid
        rows: board.currentBoardSize    // Use the stable board size
        columns: board.currentBoardSize // Use the stable board size
        opacity: board.allItemsCreated ? 1 : 0

        readonly property int cellSize: Math.floor(board.width / board.currentBoardSize)
        width: cellSize * board.currentBoardSize
        height: cellSize * board.currentBoardSize
        anchors.centerIn: parent

        Behavior on opacity {
            NumberAnimation {
                duration: 400
                easing.type: Easing.OutQuad
            }
        }

        Repeater {
            model: GameLogic.boardModel

            onItemAdded: (index, item) => {
                board.createdItemsCount++
                if (board.createdItemsCount >= board.totalItems) {
                    board.allItemsCreated = true
                }
            }

            onItemRemoved: (index, item) => {
                board.createdItemsCount--
                board.allItemsCreated = false
            }

            // Reset counter when model changes
            onModelChanged: {
                board.createdItemsCount = 0
                board.allItemsCreated = false
            }

            delegate: Item {
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
                        visible: UserSettings.enableWood // Hide when wood texture is disabled
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    visible: {
                        if (!UserSettings.showHints) return false
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

    // Initialize current board size
    Component.onCompleted: {
        currentBoardSize = GameLogic.boardSize
    }
}
