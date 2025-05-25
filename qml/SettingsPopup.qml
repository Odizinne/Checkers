import QtQuick.Controls.Material
import QtQuick.Controls.impl
import QtQuick.Layouts
import QtQuick
import Odizinne.Checkers

Popup {
    id: settingsPopup
    modal: true
    visible: false
    width: 350
    height: 550
    Material.background: UserSettings.darkMode ? "#1C1C1C" : "#E3E3E3"
    Material.roundedScale: Material.SmallScale

    property bool initialBackwardCaptures: false
    property bool initialOptionalCaptures: false
    property bool initialKingFastForward: false

    onOpened: {
        initialBackwardCaptures = UserSettings.allowBackwardCaptures
        initialOptionalCaptures = UserSettings.optionalCaptures
        initialKingFastForward = UserSettings.kingFastForward
    }

    onClosed: {
        if (initialBackwardCaptures !== UserSettings.allowBackwardCaptures ||
                initialOptionalCaptures !== UserSettings.optionalCaptures ||
                initialKingFastForward !== UserSettings.kingFastForward) {
            GameLogic.initializeBoard()
        }
    }

    ScrollingArea {
        id: scrollArea
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: saveButton.top
        anchors.bottomMargin: 10
        contentWidth: width
        contentHeight: textContainer.height + 10

        Item {
            id: textContainer
            anchors.centerIn: parent
            width: scrollArea.width - 20
            height: mainLyt.implicitHeight

            ColumnLayout {
                id: mainLyt
                anchors.centerIn: parent
                width: textContainer.width
                spacing: 10

                Label {
                    text: qsTr("Custom Rules")
                    color: Material.accent
                    Layout.leftMargin: 10
                    Layout.bottomMargin: -5
                    font.pixelSize: 14
                }

                Pane {
                    Layout.fillWidth: true
                    Material.roundedScale: Material.SmallScale
                    Material.elevation: 6
                    Material.background: UserSettings.darkMode ? "#2B2B2B" : "#FFFFFF"

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 15

                        RowLayout {
                            Layout.fillWidth: true

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 3

                                Label {
                                    text: qsTr("Backward Captures")
                                    font.bold: true
                                }

                                Label {
                                    text: qsTr("Regular pieces can capture backward")
                                    opacity: 0.7
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                }
                            }

                            Switch {
                                checked: UserSettings.allowBackwardCaptures
                                onClicked: UserSettings.allowBackwardCaptures = checked
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 3

                                Label {
                                    text: qsTr("Optional Captures")
                                    font.bold: true
                                }

                                Label {
                                    text: qsTr("Players can choose not to capture")
                                    opacity: 0.7
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                }
                            }

                            Switch {
                                checked: UserSettings.optionalCaptures
                                onClicked: UserSettings.optionalCaptures = checked
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 3

                                Label {
                                    text: qsTr("King Fast Forward")
                                    font.bold: true
                                }

                                Label {
                                    text: qsTr("Kings move freely diagonally")
                                    opacity: 0.7
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                }
                            }

                            Switch {
                                checked: UserSettings.kingFastForward
                                onClicked: UserSettings.kingFastForward = checked
                            }
                        }
                    }
                }

                Item {
                    Layout.fillHeight: true
                }


                Label {
                    text: qsTr("Board settings")
                    color: Material.accent
                    Layout.leftMargin: 10
                    Layout.bottomMargin: -5
                    font.pixelSize: 14
                }

                Pane {
                    Layout.fillWidth: true
                    Material.roundedScale: Material.SmallScale
                    Material.elevation: 6
                    Material.background: UserSettings.darkMode ? "#2B2B2B" : "#FFFFFF"

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 15
                        RowLayout {
                            Layout.fillWidth: true
                            Label {
                                text: qsTr("Board size")
                                Layout.fillWidth: true
                            }

                            ComboBox {
                                id: boardSizeCombo
                                model: [
                                    { text: "8x8", value: 8 },
                                    { text: "10x10", value: 10 }
                                ]
                                textRole: "text"
                                valueRole: "value"
                                Layout.preferredHeight: 35

                                Component.onCompleted: {
                                    currentIndex = UserSettings.boardSize === 8 ? 0 : 1
                                }

                                onActivated: {
                                    if (UserSettings.boardSize !== currentValue) {
                                        UserSettings.boardSize = currentValue
                                        GameLogic.initializeBoard()
                                    }
                                }

                                Material.roundedScale: Material.SmallScale
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Label {
                                text: qsTr("Show hints")
                                Layout.fillWidth: true
                            }

                            Switch {
                                checked: UserSettings.showHints
                                onClicked: UserSettings.showHints = checked
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Label {
                                text: qsTr("Wood texture")
                                Layout.fillWidth: true
                            }

                            Switch {
                                checked: UserSettings.enableWood
                                onClicked: UserSettings.enableWood = checked
                            }
                        }
                    }
                }
                Label {

                    text: qsTr("Application settings")
                    color: Material.accent
                    Layout.leftMargin: 10
                    Layout.bottomMargin: -5
                    font.pixelSize: 14
                }

                Pane {
                    Layout.fillWidth: true
                    Material.roundedScale: Material.SmallScale
                    Material.elevation: 6
                    Material.background: UserSettings.darkMode ? "#2B2B2B" : "#FFFFFF"

                    ColumnLayout {
                        id: appSettingsLyt
                        anchors.fill: parent
                        spacing: 15
                        property int labelWidth: Math.max(themeLabel.implicitWidth, volumeLabel.implicitWidth)

                        RowLayout {
                            spacing: 10

                            Label {
                                text: qsTr("Language")
                                Layout.fillWidth: true
                            }

                            ComboBox {
                                Layout.preferredHeight: 35
                                model: [qsTr("System"), "english", "français"]
                                currentIndex: UserSettings.languageIndex
                                onActivated: {
                                    UserSettings.languageIndex = currentIndex
                                    Helper.changeApplicationLanguage(currentIndex)
                                    currentIndex = UserSettings.languageIndex
                                }
                                onCurrentIndexChanged: currentIndex = UserSettings.languageIndex
                            }
                        }

                        RowLayout {
                            id: volumeLyt
                            Layout.fillWidth: true

                            Label {
                                id: volumeLabel
                                text: qsTr("Volume")
                                Layout.preferredWidth: appSettingsLyt.labelWidth
                            }

                            Slider {
                                id: volumeSlider
                                from: 0.0
                                to: 1.0
                                Layout.leftMargin: 5
                                Layout.fillWidth: true
                                value: UserSettings.volume
                                onValueChanged: UserSettings.volume = value
                            }
                        }

                        RowLayout {
                            id: themeLyt
                            Layout.fillWidth: true

                            Label {
                                id: themeLabel
                                text: qsTr("Dark mode")
                                Layout.fillWidth: true
                                Layout.preferredWidth: appSettingsLyt.labelWidth
                            }

                            Item {
                                Layout.preferredHeight: 20
                                Layout.preferredWidth: 20

                                IconImage {
                                    id: sunImage
                                    anchors.fill: parent
                                    source: "qrc:/icons/sun.svg"
                                    color: "black"
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

                                IconImage {
                                    anchors.fill: parent
                                    id: moonImage
                                    source: "qrc:/icons/moon.svg"
                                    color: "white"
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

                            Switch {
                                id: themeSwitch
                                checked: UserSettings.darkMode
                                onClicked: UserSettings.darkMode = checked
                            }
                        }
                    }
                }
            }
        }
    }

    Button {
        id: saveButton
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        text: qsTr("Save and close")
        onClicked: settingsPopup.close()
        Material.roundedScale: Material.SmallScale
    }

}
