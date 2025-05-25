pragma Singleton

import QtQuick

QtObject {
    id: gameLogic

    // Game state properties
    property int boardSize: UserSettings.boardSize
    property int cellSize: 80
    property bool gameOver: false
    property int winner: 0
    property bool isPlayer1Turn: true
    property bool animating: false
    property bool inChainCapture: false
    property var chainCapturePosition: null
    property var selectedPiece: null
    property bool isResetting: false
    property int consecutiveGames: 0
    // Captured pieces tracking
    property var capturedWhitePieces: []
    property var capturedBlackPieces: []
    property int capturedWhiteCount: 0
    property int capturedBlackCount: 0
    property bool isResizing: false

    // Models - will be set from Main.qml
    property var boardModel: null
    property var piecesModel: null

    signal showGameOverPopup()
    property var lastMove: null
    property bool canUndo: false

    signal showDonatePopup()

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
        onTriggered: gameLogic.rebuildBoard()
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

        // Clear undo state
        lastMove = null
        canUndo = false

        // Start reset animation
        isResetting = true

        // Clear captured pieces immediately so footer fades out
        capturedWhitePieces = []
        capturedBlackPieces = []
        capturedWhiteCount = 0
        capturedBlackCount = 0

        boardModel.clear()
        piecesModel.clear()

        // After fade out completes, rebuild the board
        resetTimer.start()
    }

    function rebuildBoard() {
        boardModel.clear()
        piecesModel.clear()

        let player1Count = 0
        let player2Count = 0

        for (let row = 0; row < boardSize; row++) {
            for (let col = 0; col < boardSize; col++) {
                boardModel.append({
                    row: row,
                    col: col
                })

                // Only place pieces on dark squares (where row + col is odd)
                if ((row + col) % 2 === 1) {
                    // 8x8 board setup (3 rows each side, 12 pieces per player)
                    if (boardSize === 8) {
                        if (row < 3) {
                            // Player 2 pieces (top)
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
                            player2Count++
                        } else if (row >= 5) {
                            // Player 1 pieces (bottom)
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
                            player1Count++
                        }
                    }
                    // 10x10 board setup (4 rows each side, 20 pieces per player)
                    else if (boardSize === 10) {
                        if (row < 4) {
                            // Player 2 pieces (top)
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
                            player2Count++
                        } else if (row >= 6) {
                            // Player 1 pieces (bottom)
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
                            player1Count++
                        }
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

        // Save current state before making the move
        lastMove = saveGameState()
        canUndo = true

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
        let wasCapture = false

        // Check if it's a capture move
        if (currentPiece.isKing && UserSettings.kingFastForward) {
            // King fast forward capture detection
            let rowDir = toRow > fromRow ? 1 : -1
            let colDir = toCol > fromCol ? 1 : -1

            for (let i = 1; i < Math.abs(toRow - fromRow); i++) {
                let checkRow = fromRow + (rowDir * i)
                let checkCol = fromCol + (colDir * i)
                let checkPiece = getPieceAt(checkRow, checkCol)
                if (checkPiece && checkPiece.player !== currentPiece.player) {
                    wasCapture = true

                    // Remove the captured piece
                    let capturedData = piecesModel.get(checkPiece.index)
                    let capturedPieceInfo = {
                        player: capturedData.player,
                        isKing: capturedData.isKing,
                        id: capturedData.id
                    }

                    piecesModel.set(checkPiece.index, {
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
                    break
                }
            }
        } else {
            // Regular capture detection
            wasCapture = Math.abs(toRow - fromRow) === 2
        }

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

        // Handle regular capture
        if (wasCapture && (!currentPiece.isKing || !UserSettings.kingFastForward)) {
            AudioEngine.playMove()
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
        } else if (!wasCapture) {
            AudioEngine.playMove()
        } else if (wasCapture) {
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

                if (UserSettings.vsAI && !isPlayer1Turn) {
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

        if (!gameOver && UserSettings.vsAI && !isPlayer1Turn) {
            aiTimer.start()
        }
    }

    function executeAIMove() {
        let move = AIPlayer.makeMove()
        if (move && move.from && move.to) {
            executeMove(move.from.row, move.from.col, move.to.row, move.to.col)
        } else {
            checkGameState()
        }
    }

    function executeAIChainCapture() {
        let move = AIPlayer.makeChainCaptureMove()
        if (move && move.from && move.to) {
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

        // First, check if we're clicking on a piece
        let clickedPiece = getPieceAt(row, col)

        if (selectedPiece !== null) {
            // We have a piece selected, try to move
            if (isValidMove(selectedPiece.row, selectedPiece.col, row, col)) {
                executeMove(selectedPiece.row, selectedPiece.col, row, col)
            } else if (clickedPiece && clickedPiece.player === (isPlayer1Turn ? 1 : 2)) {
                // Clicking on another valid piece - select it instead
                selectedPiece = { row: row, col: col, index: clickedPiece.index }
            } else {
                // Invalid move and not clicking on a valid piece - deselect
                selectedPiece = null
            }
        } else {
            // No piece selected, try to select one
            if (clickedPiece && clickedPiece.player === (isPlayer1Turn ? 1 : 2)) {
                selectedPiece = { row: row, col: col, index: clickedPiece.index }
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

    function getKingFastForwardMoves(row, col) {
        let moves = []
        if (!UserSettings.kingFastForward) return moves

        let piece = getPieceAt(row, col)
        if (!piece || !piece.isKing) return moves

        let directions = [[-1, -1], [-1, 1], [1, -1], [1, 1]]

        for (let dir of directions) {
            let foundEnemy = false
            let enemyRow = -1
            let enemyCol = -1

            // Check each square in this direction
            for (let distance = 1; distance < boardSize; distance++) {
                let newRow = row + (dir[0] * distance)
                let newCol = col + (dir[1] * distance)

                if (newRow < 0 || newRow >= boardSize || newCol < 0 || newCol >= boardSize)
                    break

                let targetPiece = getPieceAt(newRow, newCol)

                if (targetPiece) {
                    if (!foundEnemy && targetPiece.player !== piece.player) {
                        // Found first enemy piece in this direction
                        foundEnemy = true
                        enemyRow = newRow
                        enemyCol = newCol
                    } else {
                        // Hit another piece (friendly or second enemy), stop here
                        break
                    }
                } else if (foundEnemy) {
                    // Empty square after enemy piece - valid capture landing spot
                    moves.push({row: newRow, col: newCol, isCapture: true})
                } else {
                    // Empty square with no enemy to capture - regular move
                    moves.push({row: newRow, col: newCol, isCapture: false})
                }
            }
        }

        return moves
    }

    function getCaptureMoves(row, col) {
        let moves = []
        let piece = getPieceAt(row, col)
        if (!piece) return moves

        // King fast forward captures - no restrictions when rule is enabled
        if (piece.isKing && UserSettings.kingFastForward) {
            let fastMoves = getKingFastForwardMoves(row, col)
            return fastMoves.filter(move => move.isCapture).map(move => ({row: move.row, col: move.col}))
        }

        let directions = []
        if (piece.isKing) {
            directions = [[-1, -1], [-1, 1], [1, -1], [1, 1]]
        } else if (piece.player === 1) {
            // Normal forward directions for player 1
            directions = [[-1, -1], [-1, 1]]
            // Add backward directions if custom rule is enabled
            if (UserSettings.allowBackwardCaptures) {
                directions.push([1, -1], [1, 1])
            }
        } else {
            // Normal forward directions for player 2
            directions = [[1, -1], [1, 1]]
            // Add backward directions if custom rule is enabled
            if (UserSettings.allowBackwardCaptures) {
                directions.push([-1, -1], [-1, 1])
            }
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

                // If no captures available OR optional captures is enabled, check regular moves
                if (!hasAnyCaptures(player) || UserSettings.optionalCaptures) {
                    // King fast forward moves
                    if (piece.isKing && UserSettings.kingFastForward) {
                        let fastMoves = getKingFastForwardMoves(piece.row, piece.col)
                        if (fastMoves.length > 0) {
                            return true
                        }
                    } else {
                        // Regular moves
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

        // King fast forward moves
        if (piece.isKing && UserSettings.kingFastForward) {
            let fastMoves = getKingFastForwardMoves(fromRow, fromCol)
            let validFastMove = fastMoves.some(m => m.row === toRow && m.col === toCol)
            if (validFastMove) {
                // Check if it's a capture move when captures are mandatory
                if (!UserSettings.optionalCaptures && hasAnyCaptures(piece.player)) {
                    return fastMoves.some(m => m.row === toRow && m.col === toCol && m.isCapture)
                }
                return true
            }
        }

        let rowDiff = toRow - fromRow
        let colDiff = Math.abs(toCol - fromCol)

        // Regular move
        if (colDiff === 1 && Math.abs(rowDiff) === 1) {
            // Check if any captures are available for current player (unless optional captures is enabled)
            if (!UserSettings.optionalCaptures && hasAnyCaptures(piece.player)) {
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
                    // Check if backward captures are allowed
                    let isForwardCapture = (piece.player === 1 && rowDiff === -2) ||
                                         (piece.player === 2 && rowDiff === 2)
                    let isBackwardCapture = UserSettings.allowBackwardCaptures &&
                                          ((piece.player === 1 && rowDiff === 2) ||
                                           (piece.player === 2 && rowDiff === -2))

                    return isForwardCapture || isBackwardCapture
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
            AudioEngine.playWin()
            if (UserSettings.showDonate) {
                consecutiveGames++
                UserSettings.totalGames++
                if (consecutiveGames === 3 || UserSettings.totalGames === 5) {
                    showDonatePopup()
                    return
                }
            }
            showGameOverPopup()

            return
        } else if (player2Count === 0) {
            gameOver = true
            winner = 1
            AudioEngine.playWin()
            if (UserSettings.showDonate) {
                consecutiveGames++
                UserSettings.totalGames++
                if (consecutiveGames === 3 || UserSettings.totalGames === 5) {
                    showDonatePopup()
                    UserSettings.showDonate = false
                    return
                }
            }
            showGameOverPopup()
            return
        }

        // Check for no valid moves (stalemate = defeat)
        let currentPlayer = isPlayer1Turn ? 1 : 2
        if (!hasValidMoves(currentPlayer)) {
            gameOver = true
            winner = currentPlayer === 1 ? 2 : 1
            AudioEngine.playWin()
            if (UserSettings.showDonate) {
                consecutiveGames++
                UserSettings.totalGames++
                if (consecutiveGames === 3 || UserSettings.totalGames === 5) {
                    showDonatePopup()
                    UserSettings.showDonate = false
                    return
                }
            }
            showGameOverPopup()
        }
    }

    function saveGameState() {
        if (!piecesModel) return null

        let state = {
            pieces: [],
            gameState: {
                isPlayer1Turn: isPlayer1Turn,
                capturedWhiteCount: capturedWhiteCount,
                capturedBlackCount: capturedBlackCount,
                capturedWhitePieces: capturedWhitePieces.slice(),
                capturedBlackPieces: capturedBlackPieces.slice(),
                inChainCapture: inChainCapture,
                chainCapturePosition: chainCapturePosition ? {
                    row: chainCapturePosition.row,
                    col: chainCapturePosition.col
                } : null,
                selectedPiece: selectedPiece ? {
                    row: selectedPiece.row,
                    col: selectedPiece.col,
                    index: selectedPiece.index
                } : null
            }
        }

        // Save all pieces
        for (let i = 0; i < piecesModel.count; i++) {
            let piece = piecesModel.get(i)
            state.pieces.push({
                id: piece.id,
                row: piece.row,
                col: piece.col,
                player: piece.player,
                isKing: piece.isKing,
                isAlive: piece.isAlive,
                x: piece.x,
                y: piece.y
            })
        }

        return state
    }

    function restoreGameState(state) {
        if (!state || !piecesModel) return

        // Restore pieces
        for (let i = 0; i < state.pieces.length && i < piecesModel.count; i++) {
            let piece = state.pieces[i]
            piecesModel.set(i, piece)
        }

        // Restore game state
        isPlayer1Turn = state.gameState.isPlayer1Turn
        capturedWhiteCount = state.gameState.capturedWhiteCount
        capturedBlackCount = state.gameState.capturedBlackCount
        capturedWhitePieces = state.gameState.capturedWhitePieces.slice()
        capturedBlackPieces = state.gameState.capturedBlackPieces.slice()
        inChainCapture = state.gameState.inChainCapture
        chainCapturePosition = state.gameState.chainCapturePosition ? {
            row: state.gameState.chainCapturePosition.row,
            col: state.gameState.chainCapturePosition.col
        } : null
        selectedPiece = state.gameState.selectedPiece ? {
            row: state.gameState.selectedPiece.row,
            col: state.gameState.selectedPiece.col,
            index: state.gameState.selectedPiece.index
        } : null

        canUndo = false
        lastMove = null
    }

    function undoLastMove() {
        if (lastMove && canUndo) {
            restoreGameState(lastMove)
        }
    }
}
