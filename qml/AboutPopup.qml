import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick

Popup {
    modal: true
    visible: false
    Material.background: UserSettings.darkMode ? "#1C1C1C" : "#E3E3E3"
    Material.roundedScale: Material.SmallScale

    ColumnLayout {
        spacing: 3
        Image {
            source: "qrc:/icons/icon.png"
            sourceSize.width: 192
            sourceSize.height: 192
            Layout.leftMargin: 10
            Layout.topMargin: 10
            Layout.rightMargin: 10
            Layout.fillWidth: true
        }

        Label {
            text: "Checkers"
            Layout.fillWidth: true
            font.bold: true
            font.pixelSize: 20
            Layout.bottomMargin: 10
            horizontalAlignment: Text.AlignHCenter
        }

        RowLayout {
            spacing: 10
            Layout.fillWidth: true

            Item {
                Layout.fillWidth: true
            }

            Button {
                icon.source: "qrc:/icons/github.svg"
                onClicked: Qt.openUrlExternally("https://github.com/odizinne/Checkers")
                Material.roundedScale: Material.SmallScale
                icon.width: 18
                icon.height: 18
                text: "Github"
                font.bold: true
                Layout.fillWidth: true
                smooth: false
                antialiasing: false
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
                Layout.fillWidth: true
                smooth: false
                antialiasing: false
            }

            Item {
                Layout.fillWidth: true
            }
        }
    }
}
