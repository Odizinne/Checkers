pragma Singleton

import QtQuick
import Odizinne.Checkers

QtObject {
    id: aiPlayer

    property int maxDepth: 4 // How many moves to look ahead
    property var transpositionTable: ({}) // Cache for evaluated positions

    function makeMove() {
        let bestMove = null

        // Reset any lingering chain capture state when AI starts
        GameLogic.inChainCapture = false
        GameLogic.chainCapturePosition = null

        // Get current board state
        let boardState = getBoardState()

        // Use minimax to find best move
        let result = minimax(boardState, maxDepth, -Infinity, Infinity, true)
        bestMove = result.move

        return bestMove
    }

    function makeChainCaptureMove() {
        if (GameLogic.inChainCapture && GameLogic.chainCapturePosition) {
            let boardState = getBoardState()
            let captures = getCaptureMoves(boardState, GameLogic.chainCapturePosition.row, GameLogic.chainCapturePosition.col, 2)

            if (captures.length > 0) {
                // Evaluate each capture
                let bestCapture = null
                let bestScore = -Infinity

                for (let capture of captures) {
                    let newState = applyMove(boardState, {
                        from: {row: GameLogic.chainCapturePosition.row, col: GameLogic.chainCapturePosition.col},
                        to: capture,
                        isCapture: true
                    })
                    let score = evaluateBoard(newState)
                    if (score > bestScore) {
                        bestScore = score
                        bestCapture = capture
                    }
                }

                return {
                    from: {row: GameLogic.chainCapturePosition.row, col: GameLogic.chainCapturePosition.col},
                    to: bestCapture,
                    isCapture: true
                }
            }
        }
        return null
    }

    function minimax(boardState, depth, alpha, beta, maximizingPlayer) {
        let boardKey = getBoardKey(boardState)

        // Check transposition table
        if (transpositionTable[boardKey] && transpositionTable[boardKey].depth >= depth) {
            return transpositionTable[boardKey]
        }

        // Terminal node or depth reached
        if (depth === 0 || isGameOver(boardState)) {
            let score = evaluateBoard(boardState)
            return { score: score, move: null }
        }

        let moves = getAllPossibleMoves(boardState, maximizingPlayer ? 2 : 1)

        if (moves.length === 0) {
            // No moves available means loss
            return { score: maximizingPlayer ? -10000 : 10000, move: null }
        }

        let bestMove = null
        let bestScore = maximizingPlayer ? -Infinity : Infinity

        // Order moves to improve alpha-beta pruning
        moves = orderMoves(moves, boardState)

        for (let move of moves) {
            let newBoardState = applyMove(boardState, move)
            let result = minimax(newBoardState, depth - 1, alpha, beta, !maximizingPlayer)

            if (maximizingPlayer) {
                if (result.score > bestScore) {
                    bestScore = result.score
                    bestMove = move
                }
                alpha = Math.max(alpha, bestScore)
            } else {
                if (result.score < bestScore) {
                    bestScore = result.score
                    bestMove = move
                }
                beta = Math.min(beta, bestScore)
            }

            if (beta <= alpha) {
                break // Alpha-beta pruning
            }
        }

        // Store in transposition table
        transpositionTable[boardKey] = { score: bestScore, move: bestMove, depth: depth }

        return { score: bestScore, move: bestMove }
    }

    function getBoardState() {
        let state = {
            pieces: [],
            board: Array(GameLogic.boardSize).fill(null).map(() => Array(GameLogic.boardSize).fill(null))
        }

        for (let i = 0; i < GameLogic.piecesModel.count; i++) {
            let piece = GameLogic.piecesModel.get(i)
            if (piece.isAlive) {
                let pieceData = {
                    row: piece.row,
                    col: piece.col,
                    player: piece.player,
                    isKing: piece.isKing
                }
                state.pieces.push(pieceData)
                state.board[piece.row][piece.col] = pieceData
            }
        }

        return state
    }

    function getBoardKey(boardState) {
        // Create a unique key for the board position
        let key = ""
        for (let row = 0; row < GameLogic.boardSize; row++) {
            for (let col = 0; col < GameLogic.boardSize; col++) {
                let piece = boardState.board[row][col]
                if (piece) {
                    key += piece.player + (piece.isKing ? "K" : "") + ","
                } else {
                    key += "0,"
                }
            }
        }
        return key
    }

    function getAllPossibleMoves(boardState, player) {
        let allMoves = []
        let captureMoves = []

        for (let piece of boardState.pieces) {
            if (piece.player === player) {
                let captures = getCaptureMoves(boardState, piece.row, piece.col, player)
                for (let capture of captures) {
                    captureMoves.push({
                        from: {row: piece.row, col: piece.col},
                        to: capture,
                        isCapture: true
                    })
                }

                // If optional captures is enabled OR no captures available, include regular moves
                if (UserSettings.optionalCaptures || captureMoves.length === 0) {
                    let regularMoves = getRegularMoves(boardState, piece.row, piece.col, piece.player, piece.isKing)
                    for (let move of regularMoves) {
                        allMoves.push({
                            from: {row: piece.row, col: piece.col},
                            to: move,
                            isCapture: false
                        })
                    }
                }
            }
        }

        // If optional captures is disabled, prioritize captures
        if (!UserSettings.optionalCaptures && captureMoves.length > 0) {
            return captureMoves
        }

        return captureMoves.concat(allMoves)
    }

    function getCaptureMoves(boardState, row, col, player) {
        let moves = []
        let piece = boardState.board[row][col]
        if (!piece) return moves

        // King fast forward captures
        if (piece.isKing && UserSettings.kingFastForward) {
            let directions = [[-1, -1], [-1, 1], [1, -1], [1, 1]]

            for (let dir of directions) {
                for (let distance = 1; distance < GameLogic.boardSize; distance++) {
                    let targetRow = row + (dir[0] * distance)
                    let targetCol = col + (dir[1] * distance)

                    if (targetRow < 0 || targetRow >= GameLogic.boardSize || targetCol < 0 || targetCol >= GameLogic.boardSize)
                        break

                    let targetPiece = boardState.board[targetRow][targetCol]
                    if (targetPiece) {
                        if (targetPiece.player !== player) {
                            let captureRow = targetRow + dir[0]
                            let captureCol = targetCol + dir[1]
                            if (captureRow >= 0 && captureRow < GameLogic.boardSize &&
                                captureCol >= 0 && captureCol < GameLogic.boardSize &&
                                !boardState.board[captureRow][captureCol]) {
                                moves.push({row: captureRow, col: captureCol})
                            }
                        }
                        break
                    }
                }
            }
            return moves
        }

        let directions = []
        if (piece.isKing) {
            directions = [[-1, -1], [-1, 1], [1, -1], [1, 1]]
        } else if (player === 1) {
            directions = [[-1, -1], [-1, 1]]
            if (UserSettings.allowBackwardCaptures) {
                directions.push([1, -1], [1, 1])
            }
        } else {
            directions = [[1, -1], [1, 1]]
            if (UserSettings.allowBackwardCaptures) {
                directions.push([-1, -1], [-1, 1])
            }
        }

        for (let dir of directions) {
            let captureRow = row + dir[0] * 2
            let captureCol = col + dir[1] * 2
            let middleRow = row + dir[0]
            let middleCol = col + dir[1]

            if (captureRow >= 0 && captureRow < GameLogic.boardSize && captureCol >= 0 && captureCol < GameLogic.boardSize &&
                !boardState.board[captureRow][captureCol]) {
                let middlePiece = boardState.board[middleRow][middleCol]
                if (middlePiece && middlePiece.player !== player) {
                    moves.push({row: captureRow, col: captureCol})
                }
            }
        }

        return moves
    }

    function getRegularMoves(boardState, row, col, player, isKing) {
        let moves = []

        // King fast forward moves
        if (isKing && UserSettings.kingFastForward) {
            let directions = [[-1, -1], [-1, 1], [1, -1], [1, 1]]

            for (let dir of directions) {
                for (let distance = 1; distance < GameLogic.boardSize; distance++) {
                    let newRow = row + (dir[0] * distance)
                    let newCol = col + (dir[1] * distance)

                    if (newRow < 0 || newRow >= GameLogic.boardSize || newCol < 0 || newCol >= GameLogic.boardSize)
                        break

                    if (boardState.board[newRow][newCol])
                        break

                    moves.push({row: newRow, col: newCol})
                }
            }
            return moves
        }

        let directions = []
        if (isKing) {
            directions = [[-1, -1], [-1, 1], [1, -1], [1, 1]]
        } else if (player === 1) {
            directions = [[-1, -1], [-1, 1]]
        } else {
            directions = [[1, -1], [1, 1]]
        }

        for (let dir of directions) {
            let newRow = row + dir[0]
            let newCol = col + dir[1]
            if (newRow >= 0 && newRow < GameLogic.boardSize && newCol >= 0 && newCol < GameLogic.boardSize &&
                !boardState.board[newRow][newCol]) {
                moves.push({row: newRow, col: newCol})
            }
        }

        return moves
    }

    function applyMove(boardState, move) {
        // Destructure to satisfy static analysis
        const { from, to, isCapture } = move || {}
        if (!from || !to) return boardState

        // Create deep copy of board state
        let newState = {
            pieces: [],
            board: Array(GameLogic.boardSize).fill(null).map(() => Array(GameLogic.boardSize).fill(null))
        }

        // Copy pieces
        for (let piece of boardState.pieces) {
            let newPiece = {
                row: piece.row,
                col: piece.col,
                player: piece.player,
                isKing: piece.isKing
            }
            newState.pieces.push(newPiece)
            newState.board[piece.row][piece.col] = newPiece
        }

        // Apply move
        let movingPiece = newState.board[from.row][from.col]
        newState.board[from.row][from.col] = null

        // Update piece position
        for (let i = 0; i < newState.pieces.length; i++) {
            if (newState.pieces[i].row === from.row && newState.pieces[i].col === from.col) {
                newState.pieces[i].row = to.row
                newState.pieces[i].col = to.col

                // Check for promotion - updated for dynamic board size
                if ((newState.pieces[i].player === 1 && to.row === 0) ||
                    (newState.pieces[i].player === 2 && to.row === GameLogic.boardSize - 1)) {
                    newState.pieces[i].isKing = true
                }

                movingPiece = newState.pieces[i]
                break
            }
        }

        newState.board[to.row][to.col] = movingPiece

        // Handle capture
        if (isCapture) {
            // King fast forward capture
            if (movingPiece.isKing && UserSettings.kingFastForward) {
                let rowDir = to.row > from.row ? 1 : -1
                let colDir = to.col > from.col ? 1 : -1

                for (let i = 1; i < Math.abs(to.row - from.row); i++) {
                    let checkRow = from.row + (rowDir * i)
                    let checkCol = from.col + (colDir * i)
                    let capturedPiece = newState.board[checkRow][checkCol]
                    if (capturedPiece && capturedPiece.player !== movingPiece.player) {
                        newState.board[checkRow][checkCol] = null
                        newState.pieces = newState.pieces.filter(p =>
                            !(p.row === checkRow && p.col === checkCol)
                        )
                        break
                    }
                }
            } else {
                // Regular capture
                let middleRow = from.row + (to.row - from.row) / 2
                let middleCol = from.col + (to.col - from.col) / 2
                newState.board[middleRow][middleCol] = null

                // Remove captured piece
                newState.pieces = newState.pieces.filter(p =>
                    !(p.row === middleRow && p.col === middleCol)
                )
            }
        }

        return newState
    }

    function evaluateBoard(boardState) {
        let score = 0
        let player1Pieces = 0
        let player2Pieces = 0
        let player1Kings = 0
        let player2Kings = 0

        for (let piece of boardState.pieces) {
            if (piece.player === 1) {
                player1Pieces++
                if (piece.isKing) player1Kings++
            } else {
                player2Pieces++
                if (piece.isKing) player2Kings++
            }

            // Positional scoring
            let positionScore = evaluatePiecePosition(piece)
            if (piece.player === 2) {
                score += positionScore
            } else {
                score -= positionScore
            }
        }

        // Material advantage
        score += (player2Pieces - player1Pieces) * 100
        score += (player2Kings - player1Kings) * 50

        // Back row protection bonus for AI - updated for dynamic board size
        let backRowBonus = 0
        for (let col = 1; col < GameLogic.boardSize; col += 2) {
            if (boardState.board[GameLogic.boardSize - 1][col] &&
                boardState.board[GameLogic.boardSize - 1][col].player === 2 &&
                !boardState.board[GameLogic.boardSize - 1][col].isKing) {
                backRowBonus += 10
            }
        }
        score += backRowBonus

        // Mobility
        let player1Mobility = getAllPossibleMoves(boardState, 1).length
        let player2Mobility = getAllPossibleMoves(boardState, 2).length
        score += (player2Mobility - player1Mobility) * 5

        return score
    }

    function evaluatePiecePosition(piece) {
        let score = 0

        // Base value
        score += piece.isKing ? 150 : 100

        // Center control is valuable - adjusted for dynamic board size
        let centerDistance = Math.abs(piece.row - (GameLogic.boardSize - 1) / 2) +
                           Math.abs(piece.col - (GameLogic.boardSize - 1) / 2)
        score += ((GameLogic.boardSize * 2) - centerDistance) * 3

        // Advanced position bonus
        if (piece.player === 1) {
            score += (GameLogic.boardSize - 1 - piece.row) * 5
        } else {
            score += piece.row * 5
        }

        // Side pieces are slightly less valuable (easier to trap)
        if (piece.col === 0 || piece.col === GameLogic.boardSize - 1) {
            score -= 5
        }

        return score
    }

    function orderMoves(moves, boardState) {
        // Order moves to improve alpha-beta pruning efficiency
        return moves.sort((a, b) => {
            // Captures first
            if (a.isCapture && !b.isCapture) return -1
            if (!a.isCapture && b.isCapture) return 1

            // Then by piece value (kings move first)
            let pieceA = boardState.board[a.from.row][a.from.col]
            let pieceB = boardState.board[b.from.row][b.from.col]
            if (pieceA.isKing && !pieceB.isKing) return -1
            if (!pieceA.isKing && pieceB.isKing) return 1

            return 0
        })
    }

    function isGameOver(boardState) {
        let player1Count = 0
        let player2Count = 0

        for (let piece of boardState.pieces) {
            if (piece.player === 1) player1Count++
            else player2Count++
        }

        return player1Count === 0 || player2Count === 0
    }
}
