pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Window
import Odizinne.Checkers
import QtQuick.Controls.Material
import QtQuick.Layouts
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
    readonly property int cellSize: boardSize / 8
    readonly property int buttonWidth: Math.round(80 * scaleFactor)
    readonly property int buttonHeight: Math.round(32 * scaleFactor)
    readonly property int buttonSpacing: Math.round(8 * scaleFactor)

    header: ToolBar {
        height: 40
        Material.background: UserSettings.darkMode ? "#2B2B2B" : "#FFFFFF"

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
            text: GameLogic.gameOver ? ("Winner: " + (GameLogic.winner === 1 ? "White" : "Black")) :
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
                text: UserSettings.vsAI ? "Computer" : "2 Players"
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

        Item {
            anchors.fill: parent
            anchors.margins: 4
            opacity: GameLogic.isResetting ? 0 : 1

            Behavior on opacity {
                NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
            }

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
                //height: 40
                width: parent.width
                onClicked: {
                    GameLogic.initializeBoard()
                    onClicked: menu.visible = false
                }
            }
        }

        MenuSeparator {
            anchors.bottom: volumeLyt.top
            anchors.left: parent.left
            anchors.right: parent.right
        }

        RowLayout {
            id: volumeLyt
            anchors.margins: 16
            anchors.bottom: themeLyt.top
            anchors.left: parent.left
            anchors.right: parent.right

            IconImage {
                sourceSize.width: 24
                sourceSize.height: 24
                color: Material.foreground
                source: {
                    if (UserSettings.volume === 0) {
                        return "qrc:/icons/volume_muted.png"
                    } else if (UserSettings.volume <= 0.50) {
                        return "qrc:/icons/volume_down.png"
                    } else if (UserSettings.volume <= 1) {
                        return "qrc:/icons/volume_up.png"
                    } else {
                        return "qrc:/icons/volume_up.png"
                    }
                }
            }

            Slider {
                id: volumeSlider
                Layout.preferredWidth: 230 -24 -16 -16 -6
                from: 0.0
                to: 1.0
                Layout.leftMargin: 5
                value: UserSettings.volume
                onValueChanged: UserSettings.volume = value
            }
        }

        RowLayout {
            id: themeLyt
            anchors.margins: 16
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right

            Item {
                Layout.preferredHeight: 24
                Layout.preferredWidth: 24

                Image {
                    id: sunImage
                    anchors.fill: parent
                    source: "qrc:/icons/sun.png"
                    opacity: !themeSwitch.checked ? 1 : 0
                    rotation: themeSwitch.checked ? 360 : 0
                    mipmap: true

                    Behavior on rotation {
                        NumberAnimation {
                            duration: 500
                            easing.type: Easing.OutQuad
                        }
                    }

                    Behavior on opacity {
                        NumberAnimation { duration: 500 }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: themeSwitch.checked = !themeSwitch.checked
                    }
                }

                Image {
                    anchors.fill: parent
                    id: moonImage
                    source: "qrc:/icons/moon.png"
                    opacity: themeSwitch.checked ? 1 : 0
                    rotation: themeSwitch.checked ? 360 : 0
                    mipmap: true

                    Behavior on rotation {
                        NumberAnimation {
                            duration: 500
                            easing.type: Easing.OutQuad
                        }
                    }

                    Behavior on opacity {
                        NumberAnimation { duration: 100 }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: themeSwitch.checked = !themeSwitch.checked
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Switch {
                id: themeSwitch
                checked: UserSettings.darkMode
                onClicked: UserSettings.darkMode = checked
                Layout.rightMargin: -10
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
            anchors.fill: parent

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
}
