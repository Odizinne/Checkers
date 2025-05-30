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

    property int currentBoardSize: GameLogic.boardSize
    property bool modelClearing: false

    // Drag state
    property bool isDragging: false
    property var draggedPiece: null
    property point dragStartPos: Qt.point(0, 0)

    // Watch for board size changes
    Connections {
        target: GameLogic
        function onBoardSizeChanged() {
            board.modelClearing = true
        }
    }

    // Watch for model changes
    Connections {
        target: GameLogic.boardModel
        function onCountChanged() {
            if (GameLogic.boardModel.count === 0 && board.modelClearing) {
                board.currentBoardSize = GameLogic.boardSize
                board.modelClearing = false
            }
        }
    }

    // Smart detection function
    function findBestCell(clickX, clickY, excludeRow, excludeCol) {
        if (!UserSettings.missClickCorrection) {
            return Qt.point(-1, -1)
        }

        var clickedRow = Math.floor(clickY / GameLogic.cellSize)
        var clickedCol = Math.floor(clickX / GameLogic.cellSize)

        // Check if clicked cell is valid and not the excluded cell
        if (isValidDestination(clickedRow, clickedCol, excludeRow, excludeCol)) {
            return Qt.point(clickedCol, clickedRow)
        }

        // Look for nearby valid cells (only adjacent - 1 step away)
        var validCells = []
        var directions = [
            [-1, -1], [-1, 0], [-1, 1],
            [0, -1],           [0, 1],
            [1, -1],  [1, 0],  [1, 1]
        ]

        for (var i = 0; i < directions.length; i++) {
            var dir = directions[i]
            var checkRow = clickedRow + dir[0]
            var checkCol = clickedCol + dir[1]

            if (checkRow >= 0 && checkRow < board.currentBoardSize &&
                checkCol >= 0 && checkCol < board.currentBoardSize) {

                if (isValidDestination(checkRow, checkCol, excludeRow, excludeCol)) {
                    var cellCenterX = checkCol * GameLogic.cellSize + GameLogic.cellSize / 2
                    var cellCenterY = checkRow * GameLogic.cellSize + GameLogic.cellSize / 2
                    var distance = Math.sqrt(Math.pow(clickX - cellCenterX, 2) + Math.pow(clickY - cellCenterY, 2))

                    validCells.push({
                        row: checkRow,
                        col: checkCol,
                        distance: distance
                    })
                }
            }
        }

        // Return closest valid cell
        if (validCells.length > 0) {
            validCells.sort(function(a, b) { return a.distance - b.distance })
            return Qt.point(validCells[0].col, validCells[0].row)
        }

        return Qt.point(-1, -1)
    }

    function isValidDestination(row, col, excludeRow, excludeCol) {
        if (row < 0 || row >= board.currentBoardSize || col < 0 || col >= board.currentBoardSize) {
            return false
        }

        // Don't consider the piece's current position as valid destination
        if (excludeRow !== undefined && excludeCol !== undefined &&
            row === excludeRow && col === excludeCol) {
            return false
        }

        // Check if this would be a valid move
        if (GameLogic.inChainCapture && GameLogic.chainCapturePosition) {
            return GameLogic.isValidMove(GameLogic.chainCapturePosition.row, GameLogic.chainCapturePosition.col, row, col)
        } else if (GameLogic.selectedPiece) {
            return GameLogic.isValidMove(GameLogic.selectedPiece.row, GameLogic.selectedPiece.col, row, col)
        } else {
            var piece = GameLogic.getPieceAt(row, col)
            if (piece) {
                var currentPlayer = GameLogic.isPlayer1Turn ? 1 : 2
                return piece.player === currentPlayer
            }
        }

        return false
    }

    function getPieceAt(x, y) {
        // Get pieces from the repeater in GamePage
        var piecesContainer = parent.children[1] // The Item containing pieces in GamePage
        if (!piecesContainer || !piecesContainer.children) return null

        for (var i = 0; i < piecesContainer.children.length; i++) {
            var pieceItem = piecesContainer.children[i]
            if (pieceItem && pieceItem.model && pieceItem.model.isAlive) {
                var pieceX = pieceItem.x
                var pieceY = pieceItem.y
                var pieceWidth = pieceItem.width
                var pieceHeight = pieceItem.height

                if (x >= pieceX && x <= pieceX + pieceWidth &&
                    y >= pieceY && y <= pieceY + pieceHeight) {
                    return pieceItem
                }
            }
        }
        return null
    }

    function canDragPiece(piece) {
        if (GameLogic.gameOver || GameLogic.animating || GameLogic.isResetting) return false

        // During chain capture, only the capturing piece can be moved
        if (GameLogic.inChainCapture) {
            return GameLogic.chainCapturePosition &&
                    GameLogic.chainCapturePosition.row === piece.model.row &&
                    GameLogic.chainCapturePosition.col === piece.model.col
        }

        // vs AI mode - only player 1 (white pieces) can be dragged on player 1's turn
        if (UserSettings.vsAI) {
            return GameLogic.isPlayer1Turn && piece.model.player === 1
        }

        // 2 player mode - current player can drag their pieces
        return (GameLogic.isPlayer1Turn && piece.model.player === 1) ||
                (!GameLogic.isPlayer1Turn && piece.model.player === 2)
    }

    // Single wood texture for entire board
    Image {
        id: woodTexture
        anchors.fill: parent
        source: "qrc:/textures/wood.jpg"
        fillMode: Image.PreserveAspectCrop
        visible: false
    }

    // Pre-rendered wood texture effect (cached)
    MultiEffect {
        id: cachedWoodEffect
        source: woodTexture
        anchors.fill: parent
        colorization: 1
        colorizationColor: "#D4B896"
        opacity: 0.3
        visible: false
        enabled: UserSettings.enableWood
        layer.enabled: true
    }

    Image {
        id: cakeBoard
        source: "qrc:/textures/cake_board.png"
        anchors.fill: grid
        visible: {
            //
            return true
            //
            var today = new Date()
            return today.getMonth() === 5 && today.getDate() === 16
        }
    }

    // Board squares
    Grid {
        id: grid
        rows: board.currentBoardSize
        columns: board.currentBoardSize

        readonly property int cellSize: Math.floor(board.width / board.currentBoardSize)
        width: cellSize * board.currentBoardSize
        height: cellSize * board.currentBoardSize
        anchors.centerIn: parent

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
                    visible: !cakeBoard.visible
                    anchors.fill: parent
                    color: (boardRec.model.row + boardRec.model.col) % 2 === 0 ? "#F0D9B5" : "#B58863"

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
                        visible: UserSettings.enableWood
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
            }
        }
    }

    // Single mouse area for everything
    MouseArea {
        anchors.fill: parent

        property point startPos: Qt.point(0, 0)
        property bool hasDragged: false

        onPressed: function(mouse) {
            startPos = Qt.point(mouse.x, mouse.y)
            hasDragged = false

            var piece = board.getPieceAt(mouse.x, mouse.y)
            if (piece && board.canDragPiece(piece)) {
                board.draggedPiece = piece
                piece.isDragging = true
                piece.z = 10

                // Select this piece
                var pieceData = GameLogic.getPieceAt(piece.model.row, piece.model.col)
                if (pieceData) {
                    GameLogic.selectedPiece = {
                        row: piece.model.row,
                        col: piece.model.col,
                        index: pieceData.index
                    }
                }
            }
        }

        onPositionChanged: function(mouse) {
            if (pressed) {
                var dragDistance = Math.sqrt(
                    Math.pow(mouse.x - startPos.x, 2) +
                    Math.pow(mouse.y - startPos.y, 2)
                )

                if (dragDistance > 10) {
                    hasDragged = true
                }

                if (board.draggedPiece) {
                    board.draggedPiece.x = mouse.x - board.draggedPiece.width/2
                    board.draggedPiece.y = mouse.y - board.draggedPiece.height/2
                }
            }
        }

        onReleased: function(mouse) {
            if (board.draggedPiece) {
                var piece = board.draggedPiece
                piece.isDragging = false
                piece.z = 0

                var fromRow = piece.model.row
                var fromCol = piece.model.col

                var targetCol = Math.floor(mouse.x / GameLogic.cellSize)
                var targetRow = Math.floor(mouse.y / GameLogic.cellSize)

                var success = false

                // If releasing on the original position, don't apply smart detection
                if (targetRow === fromRow && targetCol === fromCol) {
                    success = GameLogic.handlePieceDrop(fromRow, fromCol, targetRow, targetCol)
                } else if (UserSettings.missClickCorrection) {
                    // Apply smart detection only if not on original position
                    var targetCell = board.findBestCell(mouse.x, mouse.y, fromRow, fromCol)
                    if (targetCell.x >= 0 && targetCell.y >= 0) {
                        success = GameLogic.handlePieceDrop(fromRow, fromCol, targetCell.y, targetCell.x)
                    } else {
                        // Try original position as fallback
                        if (targetRow >= 0 && targetRow < GameLogic.boardSize &&
                            targetCol >= 0 && targetCol < GameLogic.boardSize) {
                            success = GameLogic.handlePieceDrop(fromRow, fromCol, targetRow, targetCol)
                        }
                    }
                } else {
                    // No smart detection - use exact position
                    if (targetRow >= 0 && targetRow < GameLogic.boardSize &&
                        targetCol >= 0 && targetCol < GameLogic.boardSize) {
                        success = GameLogic.handlePieceDrop(fromRow, fromCol, targetRow, targetCol)
                    }
                }

                if (!success) {
                    // Return to original position
                    piece.x = piece.originalX
                    piece.y = piece.originalY
                }

                board.draggedPiece = null
            } else if (!hasDragged) {
                // Handle click
                var originalRow = Math.floor(mouse.y / GameLogic.cellSize)
                var originalCol = Math.floor(mouse.x / GameLogic.cellSize)

                if (originalRow >= 0 && originalRow < board.currentBoardSize &&
                    originalCol >= 0 && originalCol < board.currentBoardSize) {

                    var excludeRow = -1
                    var excludeCol = -1

                    if (GameLogic.inChainCapture && GameLogic.chainCapturePosition) {
                        excludeRow = GameLogic.chainCapturePosition.row
                        excludeCol = GameLogic.chainCapturePosition.col
                    } else if (GameLogic.selectedPiece) {
                        excludeRow = GameLogic.selectedPiece.row
                        excludeCol = GameLogic.selectedPiece.col
                    }

                    // If clicking exactly on the selected piece, handle normally
                    if (originalRow === excludeRow && originalCol === excludeCol) {
                        board.cellClicked(originalRow, originalCol)
                    } else if (UserSettings.missClickCorrection) {
                        var targetCell = board.findBestCell(mouse.x, mouse.y, excludeRow, excludeCol)
                        if (targetCell.x >= 0 && targetCell.y >= 0) {
                            board.cellClicked(targetCell.y, targetCell.x)
                        } else {
                            board.cellClicked(originalRow, originalCol)
                        }
                    } else {
                        board.cellClicked(originalRow, originalCol)
                    }
                }
            }

            hasDragged = false
        }
    }

    Component.onCompleted: {
        currentBoardSize = GameLogic.boardSize
    }
}
