pragma Singleton
import QtCore

Settings {
    property bool darkMode: true
    property bool vsAI: true
    property real volume: 1.0

    property bool enableWood: true
    property bool showHints: true

    property bool allowBackwardCaptures: false
    property bool optionalCaptures: false
    property bool kingFastForward: false
    property int boardSize: 8

    property int languageIndex: 0
    property bool showDonate: true
    property int totalGames: 0
}
