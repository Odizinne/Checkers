import QtQuick
import Odizinne.Checkers

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
        id: outerCircle
        anchors.fill: parent
        radius: width / 2
        color: piece.model.player === 1 ? "#F5F5F5" : "#3C3C3C"

        // Use fixed border width instead of variable
        border.width: GameLogic.selectedPiece && GameLogic.selectedPiece.row === piece.model.row &&
                     GameLogic.selectedPiece.col === piece.model.col ?
                     Math.max(2, Math.round(width * 0.04)) : Math.max(1, Math.round(width * 0.02))
        border.color: GameLogic.selectedPiece && GameLogic.selectedPiece.row === piece.model.row &&
                     GameLogic.selectedPiece.col === piece.model.col ? "#F39C12" :
                     (piece.model.player === 1 ? "#E0E0E0" : "#2C2C2C")

        // Force perfect circle by making sure width equals height
        width: Math.min(parent.width, parent.height)
        height: width
        anchors.centerIn: parent

        // Simplified gradient - less likely to cause rendering issues
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            opacity: 0.3

            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: piece.model.player === 1 ? "#40000000" : "#60FFFFFF"
                }
                GradientStop {
                    position: 1.0
                    color: piece.model.player === 1 ? "#10FFFFFF" : "#20000000"
                }
            }
        }

        // Inner circle - clean, no gradient
        Rectangle {
            id: innerCircle
            anchors.centerIn: parent
            width: Math.round(parent.width * 0.7)
            height: width  // Force perfect circle
            radius: width / 2
            color: piece.model.player === 1 ? "#D0D0D0" : "#1F1F1F"

            // King crown
            Rectangle {
                visible: piece.model.isKing
                anchors.centerIn: parent
                width: Math.round(parent.width * 0.6)
                height: width  // Force perfect circle
                radius: width / 2
                color: "#FFD700"

                // Simplified crown gradient
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    opacity: 0.4
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#FFFFFF" }
                        GradientStop { position: 1.0; color: "#000000" }
                    }
                }
            }
        }

        scale: piece.model.isAlive ? 1 : 0
        Behavior on scale {
            NumberAnimation { duration: 300; easing.type: Easing.InBack }
        }
    }
}
