pragma ComponentBehavior: Bound

import QtQuick 2.15
import QtQuick.Window 2.15
import Odizinne.Checkers
import QtQuick.Controls.Material

ApplicationWindow {
    id: root
    width: 600
    minimumWidth: 600
    height: 680
    minimumHeight: 680
    visible: true
    title: "Checkers"
    color: isDarkTheme ? "#1C1C1C" : "#E3E3E3"
    //visibility: Window.FullScreen
    Material.theme: Material.System

    header: ToolBar {
        height: 40
        Material.background: root.isDarkTheme ? "#2B2B2B" : "#FFFFFF"

        ToolButton {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            icon.source: "qrc:/icons/menu.png"
            onClicked: menu.visible = true
        }

        Label {
            text: GameLogic.gameOver ? ("Winner: " + (GameLogic.winner === 1 ? "White" : "Black")) :
                                       (GameLogic.inChainCapture ? "Continue capturing!" :
                                                                   ((GameLogic.isPlayer1Turn ? "White" : "Black") + " Turn"))
            font.pixelSize: Math.round(18 * scaleFactor)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
        }

        Row {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            Label {
                text: GameLogic.vsAI ? "Ai" : "2 Players"
                anchors.verticalCenter: parent.verticalCenter
            }

            Switch {
                checked: true
                onClicked: {
                    GameLogic.vsAI = checked
                    GameLogic.initializeBoard()
                }
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    footer: ToolBar {
        height: 40
        Material.background: root.isDarkTheme ? "#2B2B2B" : "#FFFFFF"
    }

    Drawer {
        id: menu
        height: parent.height
        edge: Qt.LeftEdge
        width: 180
        Material.roundedScale: Material.NotRounded

        ScrollView {
            anchors.fill: parent
            clip: true

            Column {
                width: parent.width
                spacing: 2
                ItemDelegate {
                    text: qsTr("Exit")
                    height: 40
                    width: parent.width
                    onClicked: GameLogic.initializeBoard()
                }

                ItemDelegate {
                    text: qsTr("New game")
                    height: 40
                    width: parent.width
                    onClicked: Qt.quit()
                }
            }
        }
    }

    property bool isDarkTheme: Material.theme === Material.Dark
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
    readonly property int boardSize: table.maxSize
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
            root.compOpacity = 1.0
        }
    }

    Component.onCompleted: {
        audioInitTimer.start()
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

        readonly property int maxSize: Math.min(parent.width, parent.height)
        width: maxSize
        height: maxSize

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

        function handleMoveResult(result) {
            animationTimer.wasCapture = result.wasCapture
            animationTimer.toRow = result.toRow
            animationTimer.toCol = result.toCol
            animationTimer.pieceIndex = result.pieceIndex
            animationTimer.start()
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
