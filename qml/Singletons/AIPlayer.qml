pragma Singleton
import QtQuick
import Odizinne.Checkers

QtObject {
    id: aiPlayer

    function makeMove() {
        let allMoves = []
        let captureMoves = []

        // Reset any lingering chain capture state when AI starts
        GameLogic.inChainCapture = false
        GameLogic.chainCapturePosition = null

        for (let i = 0; i < GameLogic.piecesModel.count; i++) {
            let piece = GameLogic.piecesModel.get(i)
            if (piece.isAlive && piece.player === 2) {
                // Check for captures first
                let captures = GameLogic.getCaptureMoves(piece.row, piece.col)
                for (let capture of captures) {
                    captureMoves.push({
                        from: {row: piece.row, col: piece.col},
                        to: capture,
                        isCapture: true,
                        piece: piece
                    })
                }

                // Regular moves only if no captures available
                if (captureMoves.length === 0) {
                    let directions = [[-1, -1], [-1, 1], [1, -1], [1, 1]]
                    for (let dir of directions) {
                        let newRow = piece.row + dir[0]
                        let newCol = piece.col + dir[1]
                        if (GameLogic.isValidMove(piece.row, piece.col, newRow, newCol)) {
                            allMoves.push({
                                from: {row: piece.row, col: piece.col},
                                to: {row: newRow, col: newCol},
                                isCapture: false,
                                piece: piece
                            })
                        }
                    }
                }
            }
        }

        let moveToMake = captureMoves.length > 0 ?
            selectBestCapture(captureMoves) :
            selectBestMove(allMoves)

        return moveToMake
    }

    function selectBestCapture(captureMoves) {
        if (captureMoves.length === 0) return null

        let promotionCaptures = captureMoves.filter(move => move.to.row === 0)
        if (promotionCaptures.length > 0) {
            return promotionCaptures[Math.floor(Math.random() * promotionCaptures.length)]
        }
        return captureMoves[Math.floor(Math.random() * captureMoves.length)]
    }

    function selectBestMove(allMoves) {
        if (allMoves.length === 0) return null

        let scoredMoves = allMoves.map(move => ({
            move: move,
            score: evaluateMove(move)
        }))

        scoredMoves.sort((a, b) => b.score - a.score)

        // Pick from top 3 moves to add some randomness
        let topMoves = scoredMoves.slice(0, Math.min(3, scoredMoves.length))
        let selectedMove = topMoves[Math.floor(Math.random() * topMoves.length)]
        return selectedMove.move
    }

    function evaluateMove(move) {
        let score = 0

        // Prefer moving toward center
        let centerDistance = Math.abs(move.to.row - 3.5) + Math.abs(move.to.col - 3.5)
        score += (7 - centerDistance) * 2

        // Prefer forward moves
        if (move.to.row < move.from.row) {
            score += 5
        }

        // High bonus for promotion
        if (move.to.row === 0) {
            score += 20
        }

        // Prefer moves that don't leave pieces vulnerable
        // Check if the destination would be safe
        let wouldBeSafe = true
        for (let i = 0; i < GameLogic.piecesModel.count; i++) {
            let enemyPiece = GameLogic.piecesModel.get(i)
            if (enemyPiece.isAlive && enemyPiece.player === 1) {
                // Check if enemy can capture at destination
                let captures = GameLogic.getCaptureMoves(enemyPiece.row, enemyPiece.col)
                if (captures.some(cap => cap.row === move.to.row && cap.col === move.to.col)) {
                    wouldBeSafe = false
                    break
                }
            }
        }

        if (wouldBeSafe) {
            score += 3
        } else {
            score -= 5
        }

        return score
    }

    function makeChainCaptureMove() {
        if (GameLogic.inChainCapture && GameLogic.chainCapturePosition) {
            let availableCaptures = GameLogic.getCaptureMoves(GameLogic.chainCapturePosition.row, GameLogic.chainCapturePosition.col)
            if (availableCaptures.length > 0) {
                let randomCapture = availableCaptures[Math.floor(Math.random() * availableCaptures.length)]
                return {
                    from: {row: GameLogic.chainCapturePosition.row, col: GameLogic.chainCapturePosition.col},
                    to: randomCapture,
                    isCapture: true
                }
            }
        }
        return null
    }
}
