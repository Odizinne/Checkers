pragma Singleton
import QtQuick

QtObject {
    id: gameLogic

    // Game state properties
    property int boardSize: 8
    property int cellSize: 80
    property bool gameOver: false
    property int winner: 0
    property bool isPlayer1Turn: true
    property bool vsAI: true
    property bool animating: false
    property bool inChainCapture: false
    property var chainCapturePosition: null
    property var selectedPiece: null
    property bool isResetting: false

    // Captured pieces tracking
    property var capturedWhitePieces: []
    property var capturedBlackPieces: []
    property int capturedWhiteCount: 0
    property int capturedBlackCount: 0

    // Models - will be set from Main.qml
    property var boardModel: null
    property var piecesModel: null

    // Animation handling
    property int animationDuration: 300
    property Timer animationTimer: Timer {
        interval: gameLogic.animationDuration
        property bool wasCapture: false
        property int toRow: 0
        property int toCol: 0
        property int pieceIndex: -1

        onTriggered: {
            gameLogic.animating = false
            gameLogic.handlePostMoveLogic(wasCapture, toRow, toCol, pieceIndex)
        }
    }

    property Timer resetTimer: Timer {
        interval: 350
        repeat: false
        onTriggered: rebuildBoard()
    }

    // AI timers
    property Timer aiTimer: Timer {
        interval: 500
        onTriggered: gameLogic.executeAIMove()
    }

    property Timer aiChainCaptureTimer: Timer {
        interval: 400
        onTriggered: gameLogic.executeAIChainCapture()
    }

    function initializeBoard() {
        if (!boardModel || !piecesModel) return

        // Start reset animation
        isResetting = true

        // Clear captured pieces immediately so footer fades out
        capturedWhitePieces = []
        capturedBlackPieces = []
        capturedWhiteCount = 0
        capturedBlackCount = 0

        // After fade out completes, rebuild the board
        resetTimer.start()
    }

    function rebuildBoard() {
        boardModel.clear()
        piecesModel.clear()

        for (let row = 0; row < boardSize; row++) {
            for (let col = 0; col < boardSize; col++) {
                boardModel.append({
                    row: row,
                    col: col
                })

                if ((row + col) % 2 === 1) {
                    if (row < 3) {
                        piecesModel.append({
                            id: "piece_" + row + "_" + col,
                            row: row,
                            col: col,
                            player: 2,
                            isKing: false,
                            isAlive: true,
                            x: col * cellSize + cellSize / 2,
                            y: row * cellSize + cellSize / 2
                        })
                    } else if (row > 4) {
                        piecesModel.append({
                            id: "piece_" + row + "_" + col,
                            row: row,
                            col: col,
                            player: 1,
                            isKing: false,
                            isAlive: true,
                            x: col * cellSize + cellSize / 2,
                            y: row * cellSize + cellSize / 2
                        })
                    }
                }
            }
        }

        gameOver = false
        winner = 0
        isPlayer1Turn = true
        selectedPiece = null
        animating = false
        inChainCapture = false
        chainCapturePosition = null

        // End reset animation
        isResetting = false
    }

    function addCapturedPiece(piece) {
        if (piece.player === 1) {
            capturedWhitePieces = capturedWhitePieces.concat([piece])
            capturedWhiteCount = capturedWhitePieces.length
        } else {
            capturedBlackPieces = capturedBlackPieces.concat([piece])
            capturedBlackCount = capturedBlackPieces.length
        }
    }

    function executeMove(fromRow, fromCol, toRow, toCol) {
        if (gameOver || animating) return false

        if (!isValidMove(fromRow, fromCol, toRow, toCol)) return false

        animating = true
        let result = movePiece(fromRow, fromCol, toRow, toCol)
        if (result) {
            animationTimer.wasCapture = result.wasCapture
            animationTimer.toRow = result.toRow
            animationTimer.toCol = result.toCol
            animationTimer.pieceIndex = result.pieceIndex
            animationTimer.start()
            return true
        }

        animating = false
        return false
    }

    function movePiece(fromRow, fromCol, toRow, toCol) {
        let piece = getPieceAt(fromRow, fromCol)
        if (!piece || !piecesModel) return null

        let currentPiece = piecesModel.get(piece.index)
        let wasCapture = Math.abs(toRow - fromRow) === 2

        // Update piece position
        piecesModel.set(piece.index, {
            id: currentPiece.id,
            row: toRow,
            col: toCol,
            player: currentPiece.player,
            isKing: currentPiece.isKing,
            isAlive: currentPiece.isAlive,
            x: toCol * cellSize + cellSize / 2,
            y: toRow * cellSize + cellSize / 2
        })

        // Handle capture
        if (wasCapture) {
            AudioEngine.playCapture()
            let rowDiff = toRow - fromRow
            let colDiff = toCol - fromCol
            let middleRow = fromRow + rowDiff / 2
            let middleCol = fromCol + colDiff / 2
            let capturedPiece = getPieceAt(middleRow, middleCol)
            if (capturedPiece) {
                let capturedData = piecesModel.get(capturedPiece.index)

                // Store captured piece data before marking as not alive
                let capturedPieceInfo = {
                    player: capturedData.player,
                    isKing: capturedData.isKing,
                    id: capturedData.id
                }

                piecesModel.set(capturedPiece.index, {
                    id: capturedData.id,
                    row: capturedData.row,
                    col: capturedData.col,
                    player: capturedData.player,
                    isKing: capturedData.isKing,
                    isAlive: false,
                    x: capturedData.x,
                    y: capturedData.y
                })

                // Add captured piece to the collection after fade animation completes
                let captureTimer = Qt.createQmlObject('
                    import QtQuick 2.15
                    Timer {
                        interval: 350
                        repeat: false
                    }
                ', gameLogic)

                captureTimer.triggered.connect(function() {
                    addCapturedPiece(capturedPieceInfo)
                    captureTimer.destroy()
                })
                captureTimer.start()
            }
        } else {
            AudioEngine.playMove()
        }

        // Check for king promotion
        if ((currentPiece.player === 1 && toRow === 0) ||
            (currentPiece.player === 2 && toRow === boardSize - 1)) {
            let updatedPiece = piecesModel.get(piece.index)
            piecesModel.set(piece.index, {
                id: updatedPiece.id,
                row: updatedPiece.row,
                col: updatedPiece.col,
                player: updatedPiece.player,
                isKing: true,
                isAlive: updatedPiece.isAlive,
                x: updatedPiece.x,
                y: updatedPiece.y
            })
        }

        // Update selected piece position for chain captures
        if (selectedPiece) {
            selectedPiece.row = toRow
            selectedPiece.col = toCol
        }

        return {
            wasCapture: wasCapture,
            toRow: toRow,
            toCol: toCol,
            pieceIndex: piece.index
        }
    }

    function handlePostMoveLogic(wasCapture, toRow, toCol, pieceIndex) {
        if (wasCapture) {
            let availableCaptures = getCaptureMoves(toRow, toCol)
            if (availableCaptures.length > 0) {
                inChainCapture = true
                chainCapturePosition = { row: toRow, col: toCol }
                selectedPiece = { row: toRow, col: toCol, index: pieceIndex }

                if (vsAI && !isPlayer1Turn) {
                    aiChainCaptureTimer.start()
                }
                return
            }
        }

        inChainCapture = false
        chainCapturePosition = null
        isPlayer1Turn = !isPlayer1Turn
        selectedPiece = null

        checkGameState()

        if (!gameOver && vsAI && !isPlayer1Turn) {
            aiTimer.start()
        }
    }

    function executeAIMove() {
        let move = AIPlayer.makeMove()
        if (move) {
            executeMove(move.from.row, move.from.col, move.to.row, move.to.col)
        } else {
            checkGameState()
        }
    }

    function executeAIChainCapture() {
        let move = AIPlayer.makeChainCaptureMove()
        if (move) {
            executeMove(move.from.row, move.from.col, move.to.row, move.to.col)
        }
    }

    function handleCellClick(row, col) {
        if (gameOver || animating) return

        if (inChainCapture && chainCapturePosition) {
            if (isValidMove(chainCapturePosition.row, chainCapturePosition.col, row, col)) {
                executeMove(chainCapturePosition.row, chainCapturePosition.col, row, col)
            }
            return
        }

        if (selectedPiece !== null) {
            if (isValidMove(selectedPiece.row, selectedPiece.col, row, col)) {
                executeMove(selectedPiece.row, selectedPiece.col, row, col)
            } else {
                let piece = getPieceAt(row, col)
                if (piece && piece.player === (isPlayer1Turn ? 1 : 2)) {
                    selectedPiece = { row: row, col: col, index: piece.index }
                } else {
                    selectedPiece = null
                }
            }
        } else {
            let piece = getPieceAt(row, col)
            if (piece && piece.player === (isPlayer1Turn ? 1 : 2)) {
                selectedPiece = { row: row, col: col, index: piece.index }
            }
        }
    }

    function handlePieceDrop(fromRow, fromCol, targetRow, targetCol) {
        if (gameOver || animating) return false

        let isValidDrop = false

        if (inChainCapture && chainCapturePosition) {
            isValidDrop = isValidMove(
                chainCapturePosition.row,
                chainCapturePosition.col,
                targetRow, targetCol
            )
            if (isValidDrop) {
                return executeMove(chainCapturePosition.row, chainCapturePosition.col, targetRow, targetCol)
            }
        } else {
            isValidDrop = isValidMove(fromRow, fromCol, targetRow, targetCol)
            if (isValidDrop) {
                return executeMove(fromRow, fromCol, targetRow, targetCol)
            }
        }

        return false
    }

    function getPieceAt(row, col) {
        if (!piecesModel) return null

        for (let i = 0; i < piecesModel.count; i++) {
            let piece = piecesModel.get(i)
            if (piece.row === row && piece.col === col && piece.isAlive) {
                return {
                    player: piece.player,
                    isKing: piece.isKing,
                    index: i
                }
            }
        }
        return null
    }

    function getCaptureMoves(row, col) {
        let moves = []
        let piece = getPieceAt(row, col)
        if (!piece) return moves

        let directions = []
        if (piece.isKing) {
            directions = [[-1, -1], [-1, 1], [1, -1], [1, 1]]
        } else if (piece.player === 1) {
            directions = [[-1, -1], [-1, 1]]
        } else {
            directions = [[1, -1], [1, 1]]
        }

        for (let dir of directions) {
            let captureRow = row + dir[0] * 2
            let captureCol = col + dir[1] * 2
            let middleRow = row + dir[0]
            let middleCol = col + dir[1]

            if (captureRow >= 0 && captureRow < boardSize &&
                captureCol >= 0 && captureCol < boardSize &&
                !getPieceAt(captureRow, captureCol)) {
                let middlePiece = getPieceAt(middleRow, middleCol)
                if (middlePiece && middlePiece.player !== piece.player) {
                    moves.push({row: captureRow, col: captureCol})
                }
            }
        }

        return moves
    }

    function hasAnyCaptures(player) {
        if (!piecesModel) return false

        for (let i = 0; i < piecesModel.count; i++) {
            let piece = piecesModel.get(i)
            if (piece.isAlive && piece.player === player) {
                if (getCaptureMoves(piece.row, piece.col).length > 0) {
                    return true
                }
            }
        }
        return false
    }

    function hasValidMoves(player) {
        if (!piecesModel) return false

        for (let i = 0; i < piecesModel.count; i++) {
            let piece = piecesModel.get(i)
            if (piece.isAlive && piece.player === player) {
                // Check for captures first
                if (getCaptureMoves(piece.row, piece.col).length > 0) {
                    return true
                }

                // If no captures available, check regular moves
                if (!hasAnyCaptures(player)) {
                    let directions = piece.isKing ?
                        [[-1, -1], [-1, 1], [1, -1], [1, 1]] :
                        (piece.player === 1 ? [[-1, -1], [-1, 1]] : [[1, -1], [1, 1]])

                    for (let dir of directions) {
                        let newRow = piece.row + dir[0]
                        let newCol = piece.col + dir[1]
                        if (isValidMove(piece.row, piece.col, newRow, newCol)) {
                            return true
                        }
                    }
                }
            }
        }
        return false
    }

    function isValidMove(fromRow, fromCol, toRow, toCol) {
        if (toRow < 0 || toRow >= boardSize || toCol < 0 || toCol >= boardSize)
            return false

        if (getPieceAt(toRow, toCol))
            return false

        let piece = getPieceAt(fromRow, fromCol)
        if (!piece) return false

        // If in chain capture, only capture moves are valid
        if (inChainCapture) {
            let captureMoves = getCaptureMoves(fromRow, fromCol)
            return captureMoves.some(m => m.row === toRow && m.col === toCol)
        }

        let rowDiff = toRow - fromRow
        let colDiff = Math.abs(toCol - fromCol)

        // Regular move
        if (colDiff === 1 && Math.abs(rowDiff) === 1) {
            // Check if any captures are available for current player
            if (hasAnyCaptures(piece.player)) {
                return false // Must capture if possible
            }

            if (piece.isKing) {
                return true
            } else {
                return (piece.player === 1 && rowDiff === -1) ||
                       (piece.player === 2 && rowDiff === 1)
            }
        }

        // Capture move
        if (colDiff === 2 && Math.abs(rowDiff) === 2) {
            let middleRow = fromRow + rowDiff / 2
            let middleCol = fromCol + (toCol - fromCol) / 2
            let middlePiece = getPieceAt(middleRow, middleCol)

            if (middlePiece && middlePiece.player !== piece.player) {
                if (piece.isKing) {
                    return true
                } else {
                    return (piece.player === 1 && rowDiff === -2) ||
                           (piece.player === 2 && rowDiff === 2)
                }
            }
        }

        return false
    }

    function checkGameState() {
        if (!piecesModel) return

        let player1Count = 0
        let player2Count = 0

        for (let i = 0; i < piecesModel.count; i++) {
            let piece = piecesModel.get(i)
            if (piece.isAlive) {
                if (piece.player === 1) player1Count++
                else player2Count++
            }
        }

        // Check for no pieces left
        if (player1Count === 0) {
            gameOver = true
            winner = 2
            return
        } else if (player2Count === 0) {
            gameOver = true
            winner = 1
            return
        }

        // Check for no valid moves (stalemate = defeat)
        let currentPlayer = isPlayer1Turn ? 1 : 2
        if (!hasValidMoves(currentPlayer)) {
            gameOver = true
            winner = currentPlayer === 1 ? 2 : 1
        }
    }
}
