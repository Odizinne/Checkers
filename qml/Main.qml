pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Window
import Odizinne.Checkers
import QtQuick.Controls.Material

ApplicationWindow {
    id: root
    width: 430
    minimumWidth: 430
    height: 680
    minimumHeight: 680
    visible: true
    title: "Checkers"
    color: UserSettings.darkMode ? "#1C1C1C" : "#E3E3E3"
    Material.theme: UserSettings.darkMode ? Material.Dark : Material.Light

    property bool backPressedOnce: false

    // Create models at app level
    ListModel { id: globalBoardModel }
    ListModel { id: globalPiecesModel }

    onClosing: function(close) {
        if (Qt.platform.os === "android") {
            if (stackView.depth > 1) {
                close.accepted = false
                stackView.pop()
                return
            }

            if (!backPressedOnce) {
                close.accepted = false
                backPressedOnce = true
                exitTooltip.show()
                exitTimer.start()
                return
            }

            close.accepted = true
        }
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

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: splashPage
    }

    SplashPage {
        id: splashPage
        visible: false

        onNavigateToGame: {
            stackView.replace(gamePage)
        }
    }

    GamePage {
        id: gamePage
        visible: false
        boardModel: globalBoardModel
        piecesModel: globalPiecesModel

        onNavigateToSettings: stackView.push(settingsPage)
        onNavigateToRules: stackView.push(rulesPage)
        onNavigateToAbout: stackView.push(aboutPage)
        onNavigateToDonate: donatePopup.visible = true
        onNavigateToGameOver: gameOverPopup.open()
    }

    SettingsPage {
        id: settingsPage
        visible: false

        onNavigateBack: stackView.pop()
        onNavigateToEasterEgg: stackView.push(easterEggPage)
    }

    EasterEGGPage {
        id: easterEggPage
        visible: false
    }

    RulesPage {
        id: rulesPage
        visible: false

        onNavigateBack: stackView.pop()
    }

    AboutPage {
        id: aboutPage
        visible: false

        onNavigateBack: stackView.pop()
    }

    GameOverPopup {
        id: gameOverPopup
        anchors.centerIn: parent
    }

    DonatePopup {
        id: donatePopup
        anchors.centerIn: parent
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
        function onShowGameOverPopup() {
            gameOverPopup.open()
        }

        function onShowDonatePopup() {
            donatePopup.visible = true
        }
    }

    Component.onCompleted: {
        Helper.changeApplicationLanguage(UserSettings.languageIndex)
        AudioEngine.playSilent()

        // Set up GameLogic models immediately
        GameLogic.boardModel = globalBoardModel
        GameLogic.piecesModel = globalPiecesModel
        GameLogic.cellSize = 80 // Default size

        // Initialize the board
        GameLogic.initializeBoard()
    }
}
