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
            onClicked: menu.visible = true
        }

        Label {
            text: GameLogic.gameOver ? ("Winner: " + (GameLogic.winner === 1 ? "White" : "Black")) :
                                       (GameLogic.inChainCapture ? "Continue capturing!" :
                                                                   ((GameLogic.isPlayer1Turn ? "White" : "Black") + " Turn"))
            font.pixelSize: Math.round(18 * root.scaleFactor)
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
                checked: true
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

        Row {
            anchors.fill: parent
            anchors.margins: 4
            opacity: GameLogic.isResetting ? 0 : 1

            Behavior on opacity {
                NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
            }

            // Captured white pieces (left side)
            Column {
                width: parent.width / 2
                height: parent.height
                spacing: 2

                Row {
                    spacing: 2
                    Repeater {
                        model: GameLogic.isResetting ? 0 : Math.min(6, GameLogic.capturedWhiteCount)

                        Rectangle {
                            id: capWhite1
                            width: 16
                            height: 16
                            radius: 6
                            color: "#F5F5F5"
                            border.width: 1
                            border.color: "#E0E0E0"
                            required property int index

                            opacity: 0
                            Component.onCompleted: {
                                fadeInCapwhite1.start()
                            }

                            NumberAnimation {
                                id: fadeInCapwhite1
                                target: capWhite1
                                property: "opacity"
                                to: 1
                                duration: 300
                                easing.type: Easing.OutQuad
                            }

                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width * 0.7
                                height: width
                                radius: width / 2
                                color: "#D0D0D0"

                                Rectangle {
                                    visible: capWhite1.index < GameLogic.capturedWhitePieces.length &&
                                             GameLogic.capturedWhitePieces[capWhite1.index] &&
                                    GameLogic.capturedWhitePieces[capWhite1.index].isKing
                                    anchors.centerIn: parent
                                    width: parent.width * 0.6
                                    height: width
                                    radius: width / 2
                                    color: "#FFD700"
                                }
                            }
                        }
                    }
                }

                Row {
                    spacing: 2
                    Repeater {
                        model: GameLogic.isResetting ? 0 : Math.max(0, GameLogic.capturedWhiteCount - 6)

                        Rectangle {
                            id: capWhite2
                            width: 16
                            height: 16
                            radius: 6
                            color: "#F5F5F5"
                            border.width: 1
                            border.color: "#E0E0E0"
                            required property int index

                            opacity: 0
                            Component.onCompleted: {
                                fadeInCapwhite2.start()
                            }

                            NumberAnimation {
                                id: fadeInCapwhite2
                                target: capWhite2
                                property: "opacity"
                                to: 1
                                duration: 300
                                easing.type: Easing.OutQuad
                            }

                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width * 0.7
                                height: width
                                radius: width / 2
                                color: "#D0D0D0"

                                Rectangle {
                                    visible: (capWhite2.index + 6) < GameLogic.capturedWhitePieces.length &&
                                             GameLogic.capturedWhitePieces[capWhite2.index + 6] &&
                                    GameLogic.capturedWhitePieces[capWhite2.index + 6].isKing
                                    anchors.centerIn: parent
                                    width: parent.width * 0.6
                                    height: width
                                    radius: width / 2
                                    color: "#FFD700"
                                }
                            }
                        }
                    }
                }
            }

            // Captured black pieces (right side) - apply same pattern
            Column {
                width: parent.width / 2
                height: parent.height
                spacing: 2

                Row {
                    spacing: 2
                    layoutDirection: Qt.RightToLeft
                    anchors.right: parent.right

                    Repeater {
                        model: GameLogic.isResetting ? 0 : Math.min(6, GameLogic.capturedBlackCount)

                        Rectangle {
                            id: capBlack1
                            width: 16
                            height: 16
                            radius: 6
                            color: "#3C3C3C"
                            border.width: 1
                            border.color: "#2C2C2C"
                            required property int index

                            opacity: 0
                            Component.onCompleted: {
                                fadeInCapBlack1.start()
                            }

                            NumberAnimation {
                                id: fadeInCapBlack1
                                target: capBlack1
                                property: "opacity"
                                to: 1
                                duration: 300
                                easing.type: Easing.OutQuad
                            }

                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width * 0.7
                                height: width
                                radius: width / 2
                                color: "#1F1F1F"

                                Rectangle {
                                    visible: capBlack1.index < GameLogic.capturedBlackPieces.length &&
                                             GameLogic.capturedBlackPieces[capBlack1.index] &&
                                    GameLogic.capturedBlackPieces[capBlack1.index].isKing
                                    anchors.centerIn: parent
                                    width: parent.width * 0.6
                                    height: width
                                    radius: width / 2
                                    color: "#FFD700"
                                }
                            }
                        }
                    }
                }

                Row {
                    spacing: 2
                    layoutDirection: Qt.RightToLeft
                    anchors.right: parent.right

                    Repeater {
                        model: GameLogic.isResetting ? 0 : Math.max(0, GameLogic.capturedBlackCount - 6)

                        Rectangle {
                            id: capBlack2
                            width: 16
                            height: 16
                            radius: 6
                            color: "#3C3C3C"
                            border.width: 1
                            border.color: "#2C2C2C"
                            required property int index

                            opacity: 0
                            Component.onCompleted: {
                                fadeInCapBlack2.start()
                            }

                            NumberAnimation {
                                id: fadeInCapBlack2
                                target: capBlack2
                                property: "opacity"
                                to: 1
                                duration: 300
                                easing.type: Easing.OutQuad
                            }

                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width * 0.7
                                height: width
                                radius: width / 2
                                color: "#1F1F1F"

                                Rectangle {
                                    visible: (capBlack2.index + 6) < GameLogic.capturedBlackPieces.length &&
                                             GameLogic.capturedBlackPieces[capBlack2.index + 6] &&
                                    GameLogic.capturedBlackPieces[capBlack2.index + 6].isKing
                                    anchors.centerIn: parent
                                    width: parent.width * 0.6
                                    height: width
                                    radius: width / 2
                                    color: "#FFD700"
                                }
                            }
                        }
                    }
                }
            }
        }
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
                    text: qsTr("Close menu")
                    height: 40
                    width: parent.width
                    onClicked: menu.visible = false
                }

                MenuSeparator {}

                ItemDelegate {
                    text: qsTr("New game")
                    height: 40
                    width: parent.width
                    onClicked: GameLogic.initializeBoard()
                }

                ItemDelegate {
                    text: qsTr("Exit")
                    height: 40
                    width: parent.width
                    onClicked: Qt.quit()
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
                Layout.preferredWidth: 180 -24 -16 -16 -6
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
}
