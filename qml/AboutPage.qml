import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick
import Odizinne.Checkers

Page {
    id: aboutPage
    Material.background: UserSettings.darkMode ? "#1C1C1C" : "#E3E3E3"

    signal navigateBack()

    header: ToolBar {
        Material.elevation: 6
        Material.background: UserSettings.darkMode ? "#2B2B2B" : "#FFFFFF"

        ToolButton {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            icon.source: "qrc:/icons/back.svg"
            icon.color: UserSettings.darkMode ? "white" : "black"
            onClicked: aboutPage.navigateBack()
            icon.width: 18
            icon.height: 18
        }

        Label {
            text: qsTr("About")
            anchors.centerIn: parent
            font.pixelSize: 18
            font.bold: true
        }
    }

    Pane {
        anchors.centerIn: parent
        Material.elevation: 6
        Material.roundedScale: Material.LargeScale
        Material.background: UserSettings.darkMode ? "#2B2B2B" : "#FFFFFF"
        ColumnLayout {
            anchors.fill: parent
            spacing: 20

            Item {
                Layout.fillHeight: true
            }

            Image {
                source: "qrc:/icons/icon.png"
                sourceSize.width: 192
                sourceSize.height: 192
                Layout.alignment: Qt.AlignHCenter
            }

            Label {
                text: "Checkers"
                Layout.alignment: Qt.AlignHCenter
                font.bold: true
                font.pixelSize: 24
            }

            Label {
                text: qsTr("by Odizinne")
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: 14
                opacity: 0.7
                Layout.topMargin: -15
            }

            Label {
                text: qsTr("A classic checkers game built with Qt")
                Layout.alignment: Qt.AlignHCenter
                opacity: 0.7
                font.pixelSize: 16
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 20

                Button {
                    icon.source: "qrc:/icons/github.svg"
                    onClicked: Qt.openUrlExternally("https://github.com/odizinne/Checkers")
                    Material.roundedScale: Material.SmallScale
                    icon.width: 18
                    icon.height: 18
                    text: "Github"
                    font.bold: true
                }

                Button {
                    icon.source: "qrc:/icons/donate.svg"
                    icon.color: Material.accent
                    onClicked: Qt.openUrlExternally("https://ko-fi.com/odizinne")
                    Material.roundedScale: Material.SmallScale
                    icon.width: 18
                    icon.height: 18
                    font.bold: true
                    text: "Donate"
                }
            }

            Item {
                Layout.fillHeight: true
            }
        }
    }
}
