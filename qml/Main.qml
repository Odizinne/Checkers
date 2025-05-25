pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Window
import Odizinne.Checkers
import QtQuick.Controls.Material
import QtQuick.Controls.impl

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
    readonly property int cellSize: boardSize / GameLogic.boardSize
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
        id: headerBar
        height: 40
        Material.background: UserSettings.darkMode ? "#2B2B2B" : "#FFFFFF"
        property bool hasShown: false
        opacity: hasShown ? 1 : (board.allItemsCreated ? 1 : 0)

        Behavior on opacity {
            NumberAnimation {
                duration: 400
                easing.type: Easing.OutQuad
            }
        }

        onOpacityChanged: {
            if (opacity === 1 && board.allItemsCreated) {
                hasShown = true
            }
        }

        Row {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            spacing: 4

            ToolButton {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                icon.source: "qrc:/icons/menu.svg"
                icon.color: UserSettings.darkMode ? "white" : "black"
                onClicked: menu.visible = true
                icon.width: 18
                icon.height: 18
            }

            ToolButton {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                icon.source: "qrc:/icons/undo.svg"
                icon.color: UserSettings.darkMode ? "white" : "black"
                onClicked: GameLogic.undoLastMove()
                icon.width: 18
                icon.height: 18
                enabled: GameLogic.canUndo && !GameLogic.gameOver && !GameLogic.animating
                visible: !UserSettings.vsAI
                opacity: enabled ? 1.0 : 0.3
            }
        }

        Label {
            text: GameLogic.gameOver ? (GameLogic.winner === 1 ? qsTr("Winner: White") : qsTr("Winner: Black")) :
                                       (GameLogic.isPlayer1Turn ? qsTr("White Turn") : qsTr("Black Turn"))
            color: UserSettings.darkMode ? "white" : "black"
            font.pixelSize: Math.round(16 * root.scaleFactor)
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
        height: 40
        Material.background: UserSettings.darkMode ? "#2B2B2B" : "#FFFFFF"
        property bool hasShown: false
        opacity: hasShown ? 1 : (board.allItemsCreated ? 1 : 0)

        Behavior on opacity {
            NumberAnimation {
                duration: 400
                easing.type: Easing.OutQuad
            }
        }

        onOpacityChanged: {
            if (opacity === 1 && board.allItemsCreated) {
                hasShown = true
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
            spacing: 0

            ItemDelegate {
                text: qsTr("New game")
                icon.source: "qrc:/icons/new.svg"
                icon.width: 18
                icon.height: 18
                font.pixelSize: 14
                height: 45
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
                font.pixelSize: 14
                height: 45
                width: parent.width
                onClicked: {
                    rulesPopup.visible = true
                    menu.visible = false
                }
            }

            ItemDelegate {
                text: qsTr("Settings")
                icon.source: "qrc:/icons/settings.svg"
                icon.width: 18
                icon.height: 18
                font.pixelSize: 14
                height: 45
                width: parent.width
                onClicked: {
                    settingsPopup.visible = true
                    menu.visible = false
                }
            }

            ItemDelegate {
                text: qsTr("About")
                icon.source: "qrc:/icons/about.svg"
                icon.width: 18
                icon.height: 18
                font.pixelSize: 14
                height: 45
                width: parent.width
                onClicked: {
                    aboutPopup.visible = true
                    menu.visible = false
                }
            }

            ItemDelegate {
                text: qsTr("Quit")
                icon.source: "qrc:/icons/exit.svg"
                icon.width: 18
                icon.height: 18
                font.pixelSize: 14
                height: 45
                width: parent.width
                onClicked: {
                    root.backPressedOnce = true
                    Qt.quit()
                }
            }
        }

        ItemDelegate {
            text: qsTr("Support me")
            icon.source: "qrc:/icons/donate.svg"
            icon.color: Material.accent
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.left: parent.left
            icon.width: 18
            icon.height: 18
            font.pixelSize: 14
            font.bold: true
            height: 45
            onClicked: {
                donatePopup.visible = true
                menu.visible = false
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

    Connections {
        target: GameLogic
        function onBoardSizeChanged() {
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
    }

    Component.onCompleted: {
        Helper.changeApplicationLanguage(UserSettings.languageIndex)
        AudioEngine.playSilent()
        splashScreen.opacity = 1
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
            id: board
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

    SplashScreen {
        id: splashScreen
        anchors.fill: parent
        anchors.topMargin: -headerBar.height
        anchors.bottomMargin: -footerBar.height
    }

    DonatePopup {
        id: donatePopup
        anchors.centerIn: parent
        Connections {
            target: GameLogic
            function onShowDonatePopup() {
                donatePopup.visible = true
            }
        }
    }

    RulesPopup {
        id: rulesPopup
        anchors.centerIn: parent
    }
}
