pragma ComponentBehavior: Bound

import QtQuick 2.15
import QtQuick.Window 2.15
import Odizinne.Checkers
import QtQuick.Effects

Window {
    id: root
    width: 840
    height: 840
    visible: true
    title: "Checkers"
    color: "#2C3E50"
    visibility: Window.FullScreen

    readonly property bool isPortrait: height > width
    readonly property int availableSpace: isPortrait ? (width - 80) : (height - 80) // 40px margin on each side
    readonly property int boardSize: availableSpace
    readonly property int cellSize: boardSize / 8

    Component.onCompleted: {
        AudioEngine.playSilent()
    }

    Row {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 20
        spacing: 10
        z: 1
        visible: root.isPortrait

        Rectangle {
            width: 100
            height: 40
            color: "#3498DB"
            radius: 5
            Text {
                anchors.centerIn: parent
                text: "New Game"
                color: "white"
                font.pixelSize: 12
            }
            MouseArea {
                anchors.fill: parent
                onClicked: GameLogic.initializeBoard()
            }
        }

        Rectangle {
            width: 100
            height: 40
            color: GameLogic.vsAI ? "#E74C3C" : "#27AE60"
            radius: 5
            Text {
                anchors.centerIn: parent
                text: GameLogic.vsAI ? "vs AI" : "vs Human"
                color: "white"
                font.pixelSize: 12
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    GameLogic.vsAI = !GameLogic.vsAI
                    GameLogic.initializeBoard()
                }
            }
        }

        Rectangle {
            width: 100
            height: 40
            color: "#95A5A6"
            radius: 5
            Text {
                anchors.centerIn: parent
                text: "Quit"
                color: "white"
                font.pixelSize: 12
            }
            MouseArea {
                anchors.fill: parent
                onClicked: Qt.quit()
            }
        }
    }

    Column {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 20
        spacing: 10
        z: 1
        visible: root.isPortrait

        Text {
            text: GameLogic.gameOver ? ("Winner: Player " + GameLogic.winner) :
                  (GameLogic.inChainCapture ? "Continue capturing!" :
                   ("Player " + (GameLogic.isPlayer1Turn ? "1" : "2") + "'s Turn"))
            color: "white"
            font.pixelSize: Math.min(24, root.width / 20)
            anchors.horizontalCenter: parent.horizontalCenter
            horizontalAlignment: Text.AlignHCenter
        }
    }

    // Landscape layout - buttons on left, status on right
    Column {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 20
        spacing: 15
        z: 1
        visible: !root.isPortrait

        Rectangle {
            width: 100
            height: 40
            color: "#3498DB"
            radius: 5

            Text {
                anchors.centerIn: parent
                text: "New Game"
                color: "white"
                font.pixelSize: 12
            }

            MouseArea {
                anchors.fill: parent
                onClicked: GameLogic.initializeBoard()
            }
        }

        Rectangle {
            width: 100
            height: 40
            color: GameLogic.vsAI ? "#E74C3C" : "#27AE60"
            radius: 5

            Text {
                anchors.centerIn: parent
                text: GameLogic.vsAI ? "vs AI" : "vs Human"
                color: "white"
                font.pixelSize: 12
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    GameLogic.vsAI = !GameLogic.vsAI
                    GameLogic.initializeBoard()
                }
            }
        }

        Rectangle {
            width: 100
            height: 40
            color: "#95A5A6"
            radius: 5

            Text {
                anchors.centerIn: parent
                text: "Quit"
                color: "white"
                font.pixelSize: 12
            }

            MouseArea {
                anchors.fill: parent
                onClicked: Qt.quit()
            }
        }
    }

    Column {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 20
        spacing: 10
        z: 1
        visible: !root.isPortrait

        Text {
            text: GameLogic.gameOver ? ("Winner:\nPlayer " + GameLogic.winner) :
                  (GameLogic.inChainCapture ? "Continue\ncapturing!" :
                   ("Player " + (GameLogic.isPlayer1Turn ? "1" : "2") + "'s\nTurn"))
            color: "white"
            font.pixelSize: Math.min(20, root.height / 25)
            horizontalAlignment: Text.AlignHCenter
            width: 120
            wrapMode: Text.WordWrap
        }
    }

    Rectangle {
        id: table
        width: root.boardSize
        height: root.boardSize
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
            GameLogic.cellSize = root.cellSize
            GameLogic.initializeBoard()
        }

        // Update cell size when window is resized
        onWidthChanged: {
            GameLogic.cellSize = root.cellSize
            // Update piece positions
            for (let i = 0; i < piecesModel.count; i++) {
                let piece = piecesModel.get(i)
                piecesModel.set(i, {
                    id: piece.id,
                    row: piece.row,
                    col: piece.col,
                    player: piece.player,
                    isKing: piece.isKing,
                    isAlive: piece.isAlive,
                    x: piece.col * GameLogic.cellSize + GameLogic.cellSize / 2,
                    y: piece.row * GameLogic.cellSize + GameLogic.cellSize / 2
                })
            }
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
            anchors.fill: parent
            onCellClicked: (row, col) => table.handleCellClick(row, col)
        }

        // Pieces layer
        Item {
            anchors.fill: parent

            Repeater {
                model: piecesModel
                Piece {}
            }
        }
    }
}
