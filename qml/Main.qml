pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Window
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
    color: UserSettings.darkMode ? "#1C1C1C" : "#E3E3E3"
    Material.theme: UserSettings.darkMode ? Material.Dark : Material.Light

    readonly property bool isPortrait: height > width
    readonly property real scaleFactor: Math.max(Screen.pixelDensity / 6, 1.2)
    readonly property int boardSize: table.maxSize
    readonly property int cellSize: boardSize / 8
    readonly property int buttonWidth: Math.round(80 * scaleFactor)
    readonly property int buttonHeight: Math.round(32 * scaleFactor)
    readonly property int buttonSpacing: Math.round(8 * scaleFactor)
    property real compOpacity: 0.0
    property bool backPressedOnce: false

    onClosing: function(close) {
        if (Qt.platform.os === "android") {
            if (!backPressedOnce) {
                close.accepted = false
                backPressedOnce = true
                exitTooltip.show()
                exitTimer.start()
                return
            }
        }
        close.accepted = true
    }

    Timer {
        id: exitTimer
        interval: 2000
        onTriggered: {
            root.backPressedOnce = false
            exitTooltip.hide()
        }
    }

    ToolTip {
        id: exitTooltip
        text: qsTr("Press back again to exit")
        timeout: 2000
        x: (parent.width - width) / 2
        y: parent.height - height - 60
        font.pixelSize: 16
        Material.roundedScale: Material.SmallScale

        function show() {
            visible = true
        }

        function hide() {
            visible = false
        }
    }

    header: ToolBar {
        height: 40
        Material.background: UserSettings.darkMode ? "#2B2B2B" : "#FFFFFF"
        opacity: root.compOpacity
        Behavior on opacity {
            NumberAnimation {
                duration: 400
                easing.type: Easing.OutQuad
            }
        }

        ToolButton {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            icon.source: "qrc:/icons/menu.png"
            icon.color: UserSettings.darkMode ? "white" : "black"
            onClicked: menu.visible = true
            icon.width: 16
            icon.height: 16
        }

        Label {
            text: GameLogic.gameOver ? ("Winner: ") + (GameLogic.winner === 1 ? "White" : "Black") :
                                       (GameLogic.inChainCapture ? "Continue capturing!" :
                                                                   ((GameLogic.isPlayer1Turn ? "White" : "Black") + " Turn"))
            color: UserSettings.darkMode ? "white" : "black"
            font.pixelSize: Math.round(16 * root.scaleFactor)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
        }

        Row {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            Label {
                text: UserSettings.vsAI ? qsTr("Computer") : qsTr("2 Players")
                anchors.verticalCenter: parent.verticalCenter
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
        height: 40
        Material.background: UserSettings.darkMode ? "#2B2B2B" : "#FFFFFF"
        opacity: root.compOpacity
        Behavior on opacity {
            NumberAnimation {
                duration: 400
                easing.type: Easing.OutQuad
            }
        }

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
        width: 230
        Material.roundedScale: Material.NotRounded

        Column {
            anchors.fill: parent
            spacing: 2

            ItemDelegate {
                text: qsTr("New game")
                icon.source: "qrc:/icons/new.png"
                icon.width: 20
                icon.height: 20
                font.pixelSize: 16
                height: 50
                width: parent.width
                onClicked: {
                    GameLogic.initializeBoard()
                    menu.visible = false
                }
            }

            ItemDelegate {
                text: qsTr("Settings")
                icon.source: "qrc:/icons/settings.png"
                icon.width: 20
                icon.height: 20
                font.pixelSize: 16
                height: 50
                width: parent.width
                onClicked: {
                    settingsPopup.visible = true
                    menu.visible = false
                }
            }

            ItemDelegate {
                text: qsTr("About")
                icon.source: "qrc:/icons/about.png"
                icon.width: 20
                icon.height: 20
                font.pixelSize: 16
                height: 50
                width: parent.width
                onClicked: {
                    aboutPopup.visible = true
                    menu.visible = false
                }
            }
        }
    }

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

    Timer {
        id: audioInitTimer
        interval: 50
        onTriggered: {
            AudioEngine.playSilent()
        }
    }

    Component.onCompleted: {
        audioInitTimer.start()
        compOpacity = 1
    }

    Rectangle {
        id: table

        readonly property int maxSize: Math.min(parent.width, parent.height)
        width: maxSize
        height: maxSize

        color: "transparent"
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
            GameLogic.isResizing = true
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
            // Reset flag after a brief delay to allow position updates
            Qt.callLater(function() { GameLogic.isResizing = false })
        }

        Board {
            anchors.fill: parent
            onCellClicked: (row, col) => GameLogic.handleCellClick(row, col)
        }

        Item {
            width: GameLogic.cellSize * GameLogic.boardSize
            height: GameLogic.cellSize * GameLogic.boardSize
            anchors.centerIn: parent

            Repeater {
                model: piecesModel
                Piece {}
            }
        }
    }

    GameOverPopup {
        id: gameOverPopup
        anchors.centerIn: parent
        Connections {
            target: GameLogic
            function onShowGameOverPopup() {
                gameOverPopup.open()
            }
        }
    }

    AboutPopup {
        id: aboutPopup
        anchors.centerIn: parent
    }

    SettingsPopup {
        id: settingsPopup
        anchors.centerIn: parent
    }
}
