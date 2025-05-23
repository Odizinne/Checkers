pragma ComponentBehavior: Bound

import QtQuick 2.15
import QtQuick.Window 2.15
import Odizinne.Checkers

Window {
    id: root
    width: 850
    minimumWidth: 850
    height: 600
    minimumHeight: 600
    visible: true
    title: "Checkers"
    color: "#2C3E50"
    //visibility: Window.FullScreen

    Shortcut {
        sequence: "F11"
        onActivated: {
            if (root.visibility !== Window.FullScreen) {
                root.visibility = Window.FullScreen
            } else {
                root.visibility = Window.Windowed
            }
        }
    }

    readonly property bool isPortrait: height > width
    readonly property real scaleFactor: Math.max(Screen.pixelDensity / 6, 1.2)

    // Simple margins - just a bit of padding
    readonly property int margin: Math.round(20 * scaleFactor)

    // Use window size directly
    readonly property int availableSpace: isPortrait ?
        (width - margin * 2) : (height - margin * 2)
    readonly property int boardSize: availableSpace
    readonly property int cellSize: boardSize / 8

    readonly property int buttonWidth: Math.round(80 * scaleFactor)
    readonly property int buttonHeight: Math.round(32 * scaleFactor)
    readonly property int buttonSpacing: Math.round(8 * scaleFactor)
    property real compOpacity: 0

    Timer {
        id: audioInitTimer
        interval: 50
        onTriggered: {
            AudioEngine.playSilent()
            // Show the UI with a nice fade-in
            root.compOpacity = 1.0
        }
    }

    Component.onCompleted: {
        audioInitTimer.start()
    }

    // Portrait layout - top buttons
    Row {
        Behavior on opacity {
            NumberAnimation {
                duration: 800
                easing.type: Easing.OutCubic
            }
        }
        opacity: root.compOpacity
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: margin
        spacing: buttonSpacing
        z: 1
        visible: root.isPortrait

        Rectangle {
            width: buttonWidth
            height: buttonHeight
            color: "#3498DB"
            radius: 5
            Text {
                anchors.centerIn: parent
                text: "New Game"
                color: "white"
                font.pixelSize: Math.round(10 * scaleFactor)
            }
            MouseArea {
                anchors.fill: parent
                onClicked: GameLogic.initializeBoard()
            }
        }

        Rectangle {
            width: buttonWidth
            height: buttonHeight
            color: GameLogic.vsAI ? "#E74C3C" : "#27AE60"
            radius: 5
            Text {
                anchors.centerIn: parent
                text: GameLogic.vsAI ? "vs AI" : "vs Human"
                color: "white"
                font.pixelSize: Math.round(10 * scaleFactor)
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
            width: buttonWidth
            height: buttonHeight
            color: "#95A5A6"
            radius: 5
            Text {
                anchors.centerIn: parent
                text: "Quit"
                color: "white"
                font.pixelSize: Math.round(10 * scaleFactor)
            }
            MouseArea {
                anchors.fill: parent
                onClicked: Qt.quit()
            }
        }
    }

    // Portrait layout - bottom status
    Column {
        Behavior on opacity {
            NumberAnimation {
                duration: 800
                easing.type: Easing.OutCubic
            }
        }
        opacity: root.compOpacity
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: margin
        spacing: buttonSpacing
        z: 1
        visible: root.isPortrait

        Text {
            text: GameLogic.gameOver ? ("Winner: " + (GameLogic.winner === 1 ? "White" : "Black")) :
                  (GameLogic.inChainCapture ? "Continue capturing!" :
                   ((GameLogic.isPlayer1Turn ? "White" : "Black") + "'s Turn"))
            color: "white"
            font.pixelSize: Math.round(18 * scaleFactor)
            anchors.horizontalCenter: parent.horizontalCenter
            horizontalAlignment: Text.AlignHCenter
        }
    }

    // Landscape layout - left buttons
    Column {
        Behavior on opacity {
            NumberAnimation {
                duration: 800
                easing.type: Easing.OutCubic
            }
        }
        opacity: root.compOpacity
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: margin
        spacing: Math.round(12 * scaleFactor)
        z: 1
        visible: !root.isPortrait

        Rectangle {
            width: buttonWidth
            height: buttonHeight
            color: "#3498DB"
            radius: 5

            Text {
                anchors.centerIn: parent
                text: "New Game"
                color: "white"
                font.pixelSize: Math.round(10 * scaleFactor)
            }

            MouseArea {
                anchors.fill: parent
                onClicked: GameLogic.initializeBoard()
            }
        }

        Rectangle {
            width: buttonWidth
            height: buttonHeight
            color: GameLogic.vsAI ? "#E74C3C" : "#27AE60"
            radius: 5

            Text {
                anchors.centerIn: parent
                text: GameLogic.vsAI ? "vs AI" : "vs Human"
                color: "white"
                font.pixelSize: Math.round(10 * scaleFactor)
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
            width: buttonWidth
            height: buttonHeight
            color: "#95A5A6"
            radius: 5

            Text {
                anchors.centerIn: parent
                text: "Quit"
                color: "white"
                font.pixelSize: Math.round(10 * scaleFactor)
            }

            MouseArea {
                anchors.fill: parent
                onClicked: Qt.quit()
            }
        }
    }

    // Landscape layout - right status
    Column {
        Behavior on opacity {
            NumberAnimation {
                duration: 800
                easing.type: Easing.OutCubic
            }
        }
        opacity: root.compOpacity
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: margin
        spacing: buttonSpacing
        z: 1
        visible: !root.isPortrait

        Text {
            text: GameLogic.gameOver ? ("Winner:\n" + (GameLogic.winner === 1 ? "White" : "Black")) :
                  (GameLogic.inChainCapture ? "Continue\ncapturing!" :
                   ((GameLogic.isPlayer1Turn ? "White" : "Black") + "'s\nTurn"))
            color: "white"
            font.pixelSize: Math.round(16 * scaleFactor)
            horizontalAlignment: Text.AlignHCenter
            width: Math.round(100 * scaleFactor)
            wrapMode: Text.WordWrap
        }
    }

    Rectangle {
        Behavior on opacity {
            NumberAnimation {
                duration: 800
                easing.type: Easing.OutCubic
            }
        }
        opacity: root.compOpacity
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

        onWidthChanged: {
            GameLogic.cellSize = root.cellSize
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

                if (wasCapture) {
                    let availableCaptures = GameLogic.getCaptureMoves(toRow, toCol)
                    if (availableCaptures.length > 0) {
                        GameLogic.inChainCapture = true
                        GameLogic.chainCapturePosition = { row: toRow, col: toCol }
                        GameLogic.selectedPiece = { row: toRow, col: toCol, index: pieceIndex }

                        if (GameLogic.vsAI && !GameLogic.isPlayer1Turn) {
                            aiChainCaptureTimer.start()
                        }
                        return
                    }
                }

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

        Item {
            anchors.fill: parent

            Repeater {
                model: piecesModel
                Piece {}
            }
        }
    }
}
