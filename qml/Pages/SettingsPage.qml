import QtQuick.Controls.Material
import QtQuick.Controls.impl
import QtQuick
import Odizinne.Checkers

Page {
    id: settingsPage
    Material.background: UserSettings.darkMode ? "#1C1C1C" : "#E3E3E3"

    signal navigateBack()
    signal navigateToEasterEgg()

    property int delegateHeight: 60

    header: ToolBar {
        Material.elevation: 6
        Material.background: UserSettings.darkMode ? "#2B2B2B" : "#FFFFFF"

        ToolButton {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            icon.source: "qrc:/icons/back.svg"
            icon.color: UserSettings.darkMode ? "white" : "black"
            onClicked: settingsPage.navigateBack()
            icon.width: 18
            icon.height: 18
        }

        Label {
            text: qsTr("Settings")
            color: UserSettings.darkMode ? "white" : "black"
            anchors.centerIn: parent
            font.pixelSize: 18
            font.bold: true
        }
    }

    ScrollView {
        anchors.fill: parent
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        contentWidth: parent.width

        Column {
            width: parent.width
            spacing: 0

            Label {
                width: parent.width
                anchors.left: parent.left
                anchors.leftMargin: 16
                text: qsTr("Custom Rules")
                font.pixelSize: 14
                opacity: 0.6
                height: 48
                verticalAlignment: Text.AlignBottom
                bottomPadding: 8
                color: UserSettings.darkMode ? "white" : "black"
            }

            SwitchDelegate {
                width: parent.width
                height: settingsPage.delegateHeight
                text: " "
                checked: UserSettings.allowBackwardCaptures
                onClicked: {
                    UserSettings.allowBackwardCaptures = checked
                    GameLogic.initializeBoard()
                }

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Label {
                        text: qsTr("Backward Captures")
                        color: UserSettings.darkMode ? "white" : "black"
                    }

                    Label {
                        text: qsTr("Regular pieces can capture backward")
                        opacity: 0.6
                        color: UserSettings.darkMode ? "white" : "black"
                    }
                }
            }

            SwitchDelegate {
                width: parent.width
                height: settingsPage.delegateHeight
                text: " "
                checked: UserSettings.optionalCaptures
                onClicked: {
                    UserSettings.optionalCaptures = checked
                    GameLogic.initializeBoard()
                }

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Label {
                        text: qsTr("Optional Captures")
                        color: UserSettings.darkMode ? "white" : "black"
                    }

                    Label {
                        text: qsTr("Players can choose not to capture")
                        opacity: 0.6
                        color: UserSettings.darkMode ? "white" : "black"
                    }
                }
            }

            SwitchDelegate {
                width: parent.width
                height: settingsPage.delegateHeight
                text: " "
                checked: UserSettings.kingFastForward
                onClicked: {
                    UserSettings.kingFastForward = checked
                    GameLogic.initializeBoard()
                }

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Label {
                        text: qsTr("King Fast Forward")
                        color: UserSettings.darkMode ? "white" : "black"
                    }

                    Label {
                        text: qsTr("Kings move freely diagonally")
                        opacity: 0.6
                        color: UserSettings.darkMode ? "white" : "black"
                    }
                }
            }

            MenuSeparator {
                width: parent.width
            }

            Label {
                width: parent.width
                anchors.left: parent.left
                anchors.leftMargin: 16
                text: qsTr("Board Settings")
                font.pixelSize: 14
                opacity: 0.6
                height: 48
                verticalAlignment: Text.AlignBottom
                bottomPadding: 8
                color: UserSettings.darkMode ? "white" : "black"
            }

            ItemDelegate {
                width: parent.width
                height: settingsPage.delegateHeight
                text: qsTr("Board size")
                onClicked: boardSizeDialog.open()
                font.bold: false

                Label {
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: UserSettings.boardSize + "x" + UserSettings.boardSize
                    opacity: 0.6
                    color: UserSettings.darkMode ? "white" : "black"
                }
            }

            SwitchDelegate {
                width: parent.width
                height: settingsPage.delegateHeight
                text: qsTr("Show hints")
                checked: UserSettings.showHints
                onClicked: UserSettings.showHints = checked
            }

            SwitchDelegate {
                width: parent.width
                height: settingsPage.delegateHeight
                text: qsTr("Wood texture")
                checked: UserSettings.enableWood
                onClicked: UserSettings.enableWood = checked
            }

            SwitchDelegate {
                width: parent.width
                height: settingsPage.delegateHeight
                text: qsTr("Missclick correction")
                checked: UserSettings.missClickCorrection
                onClicked: UserSettings.missClickCorrection = checked
            }

            MenuSeparator {
                width: parent.width
            }

            Label {
                width: parent.width
                anchors.left: parent.left
                anchors.leftMargin: 16
                text: qsTr("Application Settings")
                font.pixelSize: 14
                opacity: 0.6
                height: 48
                verticalAlignment: Text.AlignBottom
                bottomPadding: 8
                color: UserSettings.darkMode ? "white" : "black"
            }

            ItemDelegate {
                width: parent.width
                height: settingsPage.delegateHeight
                text: qsTr("Language")
                onClicked: languageDialog.open()
                font.bold: false

                Label {
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: {
                        switch (UserSettings.languageIndex) {
                        case 0: return qsTr("System")
                        case 1: return "English"
                        case 2: return "Français"
                        default: return "English"
                        }
                    }
                    opacity: 0.6
                    color: UserSettings.darkMode ? "white" : "black"
                }
            }

            Item {
                width: parent.width
                height: settingsPage.delegateHeight

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 16

                    Label {
                        text: qsTr("Volume")
                        anchors.verticalCenter: parent.verticalCenter
                        width: 80
                        color: UserSettings.darkMode ? "white" : "black"
                    }

                    Slider {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 80 - 16
                        from: 0.0
                        to: 1.0
                        value: UserSettings.volume
                        onValueChanged: UserSettings.volume = value
                    }
                }
            }

            SwitchDelegate {
                id: darkModeSwitch
                width: parent.width
                height: settingsPage.delegateHeight
                text: qsTr("Dark mode")
                checked: UserSettings.darkMode
                onClicked: UserSettings.darkMode = checked

                Item {
                    anchors.right: parent.right
                    anchors.rightMargin: 70
                    anchors.verticalCenter: parent.verticalCenter
                    width: 20
                    height: 20

                    IconImage {
                        anchors.fill: parent
                        source: "qrc:/icons/sun.svg"
                        color: "black"
                        opacity: !darkModeSwitch.checked ? 1 : 0
                        rotation: darkModeSwitch.checked ? 360 : 0
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
                    }

                    IconImage {
                        anchors.fill: parent
                        source: "qrc:/icons/moon.svg"
                        color: "white"
                        opacity: darkModeSwitch.checked ? 1 : 0
                        rotation: darkModeSwitch.checked ? 360 : 0
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
                    }
                }
            }

            MenuSeparator {
                width: parent.width
            }

            Label {
                width: parent.width
                anchors.left: parent.left
                anchors.leftMargin: 16
                text: qsTr("Informations")
                font.pixelSize: 14
                opacity: 0.6
                height: 48
                verticalAlignment: Text.AlignBottom
                bottomPadding: 8
                color: UserSettings.darkMode ? "white" : "black"
            }

            ItemDelegate {
                width: parent.width
                height: settingsPage.delegateHeight
                text: qsTr("App Version")
                onClicked: {
                    if (Qt.platform.os === "android") {
                        tapCount++
                        if (tapCount >= 5) {
                            settingsPage.navigateToEasterEgg()
                            tapCount = 0
                        }
                    }
                }
                property int tapCount: 0

                Label {
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: Helper.getAppVersion()
                    opacity: 0.6
                    color: UserSettings.darkMode ? "white" : "black"
                }

                Timer {
                    interval: 2000
                    running: parent.tapCount > 0 && parent.tapCount < 5
                    onTriggered: parent.tapCount = 0
                }
            }

            ItemDelegate {
                width: parent.width
                height: settingsPage.delegateHeight
                text: qsTr("Qt Version")
                onClicked: {
                    return
                }

                Label {
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: Helper.getQtVersion()
                    opacity: 0.6
                    color: UserSettings.darkMode ? "white" : "black"
                }
            }

            ItemDelegate {
                width: parent.width
                height: settingsPage.delegateHeight
                text: qsTr("Credits")
                onClicked: {
                    creditsDialog.open()
                }
            }
        }
    }

    Dialog {
        id: boardSizeDialog
        anchors.centerIn: parent
        title: qsTr("Board size")
        modal: true

        Column {
            RadioButton {
                text: "8x8"
                checked: UserSettings.boardSize === 8
                onClicked: {
                    UserSettings.boardSize = 8
                    GameLogic.initializeBoard()
                    boardSizeDialog.close()
                }
            }
            RadioButton {
                text: "10x10"
                checked: UserSettings.boardSize === 10
                onClicked: {
                    UserSettings.boardSize = 10
                    GameLogic.initializeBoard()
                    boardSizeDialog.close()
                }
            }
        }
    }

    Dialog {
        id: languageDialog
        anchors.centerIn: parent
        title: qsTr("Language")
        modal: true

        Column {
            RadioButton {
                text: qsTr("System")
                checked: UserSettings.languageIndex === 0
                onClicked: {
                    UserSettings.languageIndex = 0
                    Helper.changeApplicationLanguage(0)
                    languageDialog.close()
                }
            }
            RadioButton {
                text: "English"
                checked: UserSettings.languageIndex === 1
                onClicked: {
                    UserSettings.languageIndex = 1
                    Helper.changeApplicationLanguage(1)
                    languageDialog.close()
                }
            }
            RadioButton {
                text: "Français"
                checked: UserSettings.languageIndex === 2
                onClicked: {
                    UserSettings.languageIndex = 2
                    Helper.changeApplicationLanguage(2)
                    languageDialog.close()
                }
            }
        }
    }

    Dialog {
        id: creditsDialog
        anchors.centerIn: parent
        title: qsTr("Icons from:")
        modal: true
        standardButtons: Dialog.Ok

        Column {
            Label {
                text: " - Dave Gandy"
            }
            Label {
                text: " - Phoenix Group"
            }
            Label {
                text: " - Freepik"
            }
            Label {
                text: " - VectorPortal"
            }
            Label {
                text: " - denis.klyuchnikov.1"
            }
            Label {
                text: " - AbtoCreative"
            }
            Label {
                text: " - ariefstudio"
            }
            Label {
                text: " - Kirill Kazachek"
            }
        }
    }
}
