pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Material
import QtQuick.Controls.impl
import Odizinne.Checkers

Page {
    id: gamePage
    Material.background: UserSettings.darkMode ? "#1C1C1C" : "#E3E3E3"

    property var boardModel: null
    property var piecesModel: null

    readonly property bool isPortrait: height > width
    readonly property real scaleFactor: Math.max(Screen.pixelDensity / 6, 1.2)
    readonly property int boardSize: table.maxSize
    readonly property int cellSize: boardSize / GameLogic.boardSize

    signal navigateToSettings()
    signal navigateToRules()
    signal navigateToAbout()
    signal navigateToDonate()
    signal navigateToGameOver()

    header: ToolBar {
        id: headerBar
        Material.background: UserSettings.darkMode ? "#2B2B2B" : "#FFFFFF"
        property bool hasShown: false

        Row {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            spacing: 4

            ToolButton {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                icon.source: "qrc:/icons/menu.svg"
                Material.foreground: UserSettings.darkMode ? "white" : "black"
                onClicked: menu.visible = true
                icon.width: 18
                icon.height: 18
            }

            ToolButton {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                icon.source: "qrc:/icons/undo.svg"
                Material.foreground: UserSettings.darkMode ? "white" : "black"
                onClicked: GameLogic.undoLastMove()
                icon.width: 18
                icon.height: 18
                enabled: GameLogic.canUndo && !GameLogic.gameOver && !GameLogic.animating
                visible: !UserSettings.vsAI
                //  opacity: enabled ? 1.0 : 0.3
            }
        }

        Label {
            text: GameLogic.gameOver ? (GameLogic.winner === 1 ? qsTr("Winner: White") : qsTr("Winner: Black")) :
                                       (GameLogic.isPlayer1Turn ? qsTr("White Turn") : qsTr("Black Turn"))
            color: UserSettings.darkMode ? "white" : "black"
            font.pixelSize: Math.round(16 * gamePage.scaleFactor)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
        }

        Row {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            IconImage {
                source: UserSettings.vsAI ? "qrc:/icons/computer.svg" : "qrc:/icons/people.svg"
                anchors.verticalCenter: parent.verticalCenter
                width: 18
                height: 18
                color: UserSettings.darkMode ? "white" : "black"
            }

            Switch {
                checked: UserSettings.vsAI
                onClicked: {
                    UserSettings.vsAI = checked
                    GameLogic.initializeBoard()
                }
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    footer: ToolBar {
        id: footerBar
        Material.background: UserSettings.darkMode ? "#2B2B2B" : "#FFFFFF"
        property bool hasShown: false

        Item {
            anchors.fill: parent
            anchors.margins: 4

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Rectangle {
                    id: whiteCapture
                    width: 30
                    height: 30
                    radius: 15
                    color: "#F5F5F5"
                    border.width: 1
                    border.color: "#E0E0E0"

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width * 0.6
                        height: width
                        radius: width / 2
                        color: "#D0D0D0"
                    }
                }

                Label {
                    height: parent.height
                    color: UserSettings.darkMode ? "white" : "black"
                    text: GameLogic.capturedWhiteCount
                    font.pixelSize: 20
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Label {
                    height: parent.height
                    color: UserSettings.darkMode ? "white" : "black"
                    text: GameLogic.capturedBlackCount
                    font.pixelSize: 20
                    verticalAlignment: Text.AlignVCenter
                }

                Rectangle {
                    id: blackCapture
                    width: 30
                    height: 30
                    radius: 15
                    color: "#3C3C3C"
                    border.width: 1
                    border.color: "#2C2C2C"

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width * 0.6
                        height: width
                        radius: width / 2
                        color: "#1F1F1F"
                    }
                }
            }
        }
    }

    Drawer {
        id: menu
        height: parent.height
        edge: Qt.LeftEdge
        width: gamePage.height > gamePage.width ? gamePage.width * 0.8 : 230
        Material.roundedScale: Material.NotRounded

        Column {
            anchors.fill: parent
            spacing: 0

            Item {
                width: parent.width
                height: 70

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 16

                    Image {
                        source: "qrc:/icons/icon.png"
                        width: 40
                        height: 40
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Label {
                        text: "Checkers"
                        font.pixelSize: 22
                        font.bold: true
                        color: UserSettings.darkMode ? "white" : "black"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            MenuSeparator {
                width: parent.width
            }

            ItemDelegate {
                text: qsTr("New game")
                icon.source: "qrc:/icons/new.svg"
                icon.width: 18
                icon.height: 18
                height: 50
                width: parent.width
                onClicked: {
                    GameLogic.initializeBoard()
                    menu.visible = false
                }
            }

            ItemDelegate {
                text: qsTr("Rules")
                icon.source: "qrc:/icons/rules.svg"
                icon.width: 20
                icon.height: 20
                height: 50
                width: parent.width
                onClicked: {
                    gamePage.navigateToRules()
                    menu.visible = false
                }
            }

            ItemDelegate {
                text: qsTr("Settings")
                icon.source: "qrc:/icons/settings.svg"
                icon.width: 18
                icon.height: 18
                height: 50
                width: parent.width
                onClicked: {
                    gamePage.navigateToSettings()
                    menu.visible = false
                }
            }

            ItemDelegate {
                text: qsTr("About")
                icon.source: "qrc:/icons/about.svg"
                icon.width: 18
                icon.height: 18
                height: 50
                width: parent.width
                onClicked: {
                    gamePage.navigateToAbout()
                    menu.visible = false
                }
            }

            ItemDelegate {
                text: qsTr("Support me")
                icon.source: "qrc:/icons/donate.svg"
                icon.color: Material.accent
                icon.width: 18
                icon.height: 18
                height: 50
                font.bold: true
                width: parent.width
                onClicked: {
                    gamePage.navigateToDonate()
                    menu.visible = false
                }
            }
        }
    }

    Rectangle {
        id: table

        readonly property int maxSize: Math.min(parent.width, parent.height)
        width: maxSize
        height: maxSize

        color: "transparent"
        anchors.centerIn: parent

        Component.onCompleted: {
            // Update cell size when GamePage is ready
            GameLogic.cellSize = gamePage.cellSize
        }

        onWidthChanged: {
            GameLogic.isResizing = true
            GameLogic.cellSize = gamePage.cellSize

            if (gamePage.piecesModel) {
                for (let i = 0; i < gamePage.piecesModel.count; i++) {
                    let piece = gamePage.piecesModel.get(i)
                    gamePage.piecesModel.set(i, {
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
            Qt.callLater(function() { GameLogic.isResizing = false })
        }

        Board {
            id: board
            anchors.fill: parent
            onCellClicked: (row, col) => GameLogic.handleCellClick(row, col)
        }

        Item {
            width: GameLogic.cellSize * GameLogic.boardSize
            height: GameLogic.cellSize * GameLogic.boardSize
            anchors.centerIn: parent

            Repeater {
                model: gamePage.piecesModel
                Piece {}
            }
        }
    }

    Connections {
        target: GameLogic
        function onBoardSizeChanged() {
            GameLogic.cellSize = gamePage.cellSize

            if (gamePage.piecesModel) {
                for (let i = 0; i < gamePage.piecesModel.count; i++) {
                    let piece = gamePage.piecesModel.get(i)
                    gamePage.piecesModel.set(i, {
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
        }
    }
}
