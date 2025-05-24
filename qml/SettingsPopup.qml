import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick
import Odizinne.Checkers

Popup {
    id: settingsPopup
    modal: true
    visible: false
    width: 350
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

    ColumnLayout {
        id: mainLyt
        anchors.fill: parent
        spacing: 10
        anchors.rightMargin: 10
        anchors.leftMargin: 10

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

                // Rule 1: Backward captures
                RowLayout {
                    Layout.fillWidth: true

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 5

                        Label {
                            text: qsTr("Backward Captures")
                            font.pixelSize: 16
                            font.bold: true
                        }

                        Label {
                            text: qsTr("Regular pieces can capture backward")
                            font.pixelSize: 12
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

                // Rule 2: Optional captures
                RowLayout {
                    Layout.fillWidth: true

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 5

                        Label {
                            text: qsTr("Optional Captures")
                            font.pixelSize: 16
                            font.bold: true
                        }

                        Label {
                            text: qsTr("Players can choose not to capture")
                            font.pixelSize: 12
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

                // Rule 3: King fast forward
                RowLayout {
                    Layout.fillWidth: true

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 5

                        Label {
                            text: qsTr("King Fast Forward")
                            font.pixelSize: 16
                            font.bold: true
                        }

                        Label {
                            text: qsTr("Kings move freely diagonally on first move per turn")
                            font.pixelSize: 12
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

                    Switch {
                        id: themeSwitch
                        checked: UserSettings.darkMode
                        onClicked: UserSettings.darkMode = checked
                    }
                }
            }
        }

        Button {
            Layout.fillWidth: true
            text: qsTr("Save and close")
            onClicked: settingsPopup.close()
            Material.roundedScale: Material.SmallScale
        }
    }
}
