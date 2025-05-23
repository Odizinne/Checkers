import QtQuick

Item {
    id: piece
    x: model.x - width/2
    y: model.y - height/2
    width: GameLogic.cellSize * 0.75
    height: GameLogic.cellSize * 0.75
    visible: model.isAlive
    required property var model

    Behavior on x {
        NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
    }
    Behavior on y {
        NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
    }

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: piece.model.player === 1 ? "#F5F5F5" : "#3C3C3C"
        border.width: GameLogic.selectedPiece && GameLogic.selectedPiece.row === piece.model.row &&
                     GameLogic.selectedPiece.col === piece.model.col ? 3 : 1
        border.color: GameLogic.selectedPiece && GameLogic.selectedPiece.row === piece.model.row &&
                     GameLogic.selectedPiece.col === piece.model.col ? "#F39C12" :
                     (piece.model.player === 1 ? "#E0E0E0" : "#2C2C2C")

        // Inner circle
        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 0.7
            height: parent.height * 0.7
            radius: width / 2
            color: piece.model.player === 1 ? "#D0D0D0" : "#1F1F1F"

            // King crown (replaces the inner circle when king)
            Rectangle {
                visible: piece.model.isKing
                anchors.centerIn: parent
                width: parent.width * 0.6
                height: parent.height * 0.6
                radius: width / 2
                color: "#FFD700"
            }
        }

        scale: piece.model.isAlive ? 1 : 0
        Behavior on scale {
            NumberAnimation { duration: 300; easing.type: Easing.InBack }
        }
    }
}
