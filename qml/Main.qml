pragma ComponentBehavior: Bound

import QtQuick 2.15
import QtQuick.Window 2.15
import QtMultimedia
import Odizinne.Checkers

Window {
    id: root
    width: 840
    height: 840
    visible: true
    title: "Checkers"
    color: "#2C3E50"

    Column {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 20
        spacing: 10
        z: 1

        Row {
            spacing: 10
            anchors.horizontalCenter: parent.horizontalCenter

            Rectangle {
                width: 100
                height: 40
                color: "#3498DB"
                radius: 5

                Text {
                    anchors.centerIn: parent
                    text: "New Game"
                    color: "white"
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: GameLogic.initializeBoard()
                }
            }

            Rectangle {
                width: 120
                height: 40
                color: GameLogic.vsAI ? "#E74C3C" : "#27AE60"
                radius: 5

                Text {
                    anchors.centerIn: parent
                    text: GameLogic.vsAI ? "vs AI" : "vs Human"
                    color: "white"
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        GameLogic.vsAI = !GameLogic.vsAI
                        GameLogic.initializeBoard()
                    }
                }
            }
        }
    }

    Column {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 20
        spacing: 10
        z: 1

        Text {
            text: GameLogic.gameOver ? ("winner: Player " + GameLogic.winner) :
                  (GameLogic.inChainCapture ? "Continue capturing!" :
                   ("Player " + (GameLogic.isPlayer1Turn ? "1" : "2") + "'s Turn"))
            color: "white"
            font.pixelSize: 24
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    SoundEffect {
        id: captureFX
        source: "qrc:/sounds/capture.wav"
    }

    SoundEffect {
        id: moveFX
        source: "qrc:/sounds/move.wav"
    }

    Rectangle {
        id: table
        width: 800
        height: 800
        color: "#2C3E50"
        anchors.centerIn: parent

        ListModel {
            id: boardModel
        }

        ListModel {
            id: piecesModel
        }

        Component.onCompleted: {
            GameLogic.boardModel = boardModel
            GameLogic.piecesModel = piecesModel
            GameLogic.captureFX = captureFX
            GameLogic.moveFX = moveFX
            GameLogic.initializeBoard()
        }

        function handleCellClick(row, col) {
            if (GameLogic.gameOver || GameLogic.animating) return

            // During chain capture, only allow clicking on valid capture squares
            if (GameLogic.inChainCapture && GameLogic.chainCapturePosition) {
                if (GameLogic.isValidMove(GameLogic.chainCapturePosition.row, GameLogic.chainCapturePosition.col, row, col)) {
                    GameLogic.animating = true
                    let result = GameLogic.movePiece(GameLogic.chainCapturePosition.row, GameLogic.chainCapturePosition.col, row, col)
                    if (result) {
                        animationTimer.wasCapture = result.wasCapture
                        animationTimer.toRow = result.toRow
                        animationTimer.toCol = result.toCol
                        animationTimer.pieceIndex = result.pieceIndex
                        animationTimer.start()
                    }
                }
                return
            }

            if (GameLogic.selectedPiece !== null) {
                if (GameLogic.isValidMove(GameLogic.selectedPiece.row, GameLogic.selectedPiece.col, row, col)) {
                    GameLogic.animating = true
                    let result = GameLogic.movePiece(GameLogic.selectedPiece.row, GameLogic.selectedPiece.col, row, col)
                    if (result) {
                        animationTimer.wasCapture = result.wasCapture
                        animationTimer.toRow = result.toRow
                        animationTimer.toCol = result.toCol
                        animationTimer.pieceIndex = result.pieceIndex
                        animationTimer.start()
                    }
                } else {
                    let piece = GameLogic.getPieceAt(row, col)
                    if (piece && piece.player === (GameLogic.isPlayer1Turn ? 1 : 2)) {
                        GameLogic.selectedPiece = { row: row, col: col, index: piece.index }
                    } else {
                        GameLogic.selectedPiece = null
                    }
                }
            } else {
                let piece = GameLogic.getPieceAt(row, col)
                if (piece && piece.player === (GameLogic.isPlayer1Turn ? 1 : 2)) {
                    GameLogic.selectedPiece = { row: row, col: col, index: piece.index }
                }
            }
        }

        Timer {
            id: animationTimer
            interval: 300
            property bool wasCapture: false
            property int toRow: 0
            property int toCol: 0
            property int pieceIndex: -1

            onTriggered: {
                GameLogic.animating = false

                // Check for chain capture
                if (wasCapture) {
                    let availableCaptures = GameLogic.getCaptureMoves(toRow, toCol)
                    if (availableCaptures.length > 0) {
                        GameLogic.inChainCapture = true
                        GameLogic.chainCapturePosition = { row: toRow, col: toCol }
                        GameLogic.selectedPiece = { row: toRow, col: toCol, index: pieceIndex }

                        // If it's AI's turn and AI made the capture, continue with AI immediately
                        if (GameLogic.vsAI && !GameLogic.isPlayer1Turn) {
                            aiChainCaptureTimer.start()
                        }
                        return
                    }
                }

                // Turn ends
                GameLogic.inChainCapture = false
                GameLogic.chainCapturePosition = null
                GameLogic.isPlayer1Turn = !GameLogic.isPlayer1Turn
                GameLogic.selectedPiece = null

                GameLogic.checkGameState()

                if (!GameLogic.gameOver && GameLogic.vsAI && !GameLogic.isPlayer1Turn) {
                    aiTimer.start()
                }
            }
        }

        Timer {
            id: aiTimer
            interval: 500
            onTriggered: {
                let move = AIPlayer.makeMove()
                if (move) {
                    GameLogic.animating = true
                    let result = GameLogic.movePiece(move.from.row, move.from.col, move.to.row, move.to.col)
                    if (result) {
                        animationTimer.wasCapture = result.wasCapture
                        animationTimer.toRow = result.toRow
                        animationTimer.toCol = result.toCol
                        animationTimer.pieceIndex = result.pieceIndex
                        animationTimer.start()
                    }
                } else {
                    // AI has no valid moves - trigger game over
                    GameLogic.checkGameState()
                }
            }
        }

        Timer {
            id: aiChainCaptureTimer
            interval: 400
            onTriggered: {
                let move = AIPlayer.makeChainCaptureMove()
                if (move) {
                    GameLogic.animating = true
                    let result = GameLogic.movePiece(move.from.row, move.from.col, move.to.row, move.to.col)
                    if (result) {
                        animationTimer.wasCapture = result.wasCapture
                        animationTimer.toRow = result.toRow
                        animationTimer.toCol = result.toCol
                        animationTimer.pieceIndex = result.pieceIndex
                        animationTimer.start()
                    }
                }
            }
        }

        Board {
            anchors.centerIn: parent
            onCellClicked: (row, col) => table.handleCellClick(row, col)
        }

        // Pieces layer
        Item {
            anchors.centerIn: parent
            width: GameLogic.boardSize * GameLogic.cellSize
            height: GameLogic.boardSize * GameLogic.cellSize

            Repeater {
                model: piecesModel
                Piece {}
            }
        }
    }
}
