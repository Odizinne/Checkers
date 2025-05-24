import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick

Popup {
    modal: true
    visible: false
    Material.background: UserSettings.darkMode ? "#1C1C1C" : "#E3E3E3"
    Material.roundedScale: Material.SmallScale

    ColumnLayout {
        spacing: 0
        Image {
            source: "qrc:/icons/icon.png"
            sourceSize.width: 192
            sourceSize.height: 192
            Layout.leftMargin: 10
            Layout.topMargin: 10
            Layout.rightMargin: 10
        }

        Label {
            text: "Checkers"
            Layout.fillWidth: true
            font.bold: true
            font.pixelSize: 20
            Layout.bottomMargin: 10
            horizontalAlignment: Text.AlignHCenter
        }

        Button {
            text: "Odizinne"
            icon.source: "qrc:/icons/github.png"
            icon.width: 18
            icon.height: 18
            Layout.alignment: Qt.AlignCenter
            onClicked: Qt.openUrlExternally("https://github.com/odizinne/Checkers")
            Material.roundedScale: Material.SmallScale
        }
    }
}
