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

        // Edge gradient only - covers outer ring
        Rectangle {
            anchors.fill: parent
            radius: width / 2

            gradient: {
                if (piece.model.player === 1) {
                    return piece.whiteGradient
                } else {
                    return piece.darkGradient
                }
            }
        }

        // Inner circle - clean, no gradient
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

                // Crown gradient - keep some shine on gold
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    gradient: piece.crownGradient
                }
            }
        }

        scale: piece.model.isAlive ? 1 : 0
        Behavior on scale {
            NumberAnimation { duration: 300; easing.type: Easing.InBack }
        }
    }

    // Edge gradients only
    property Gradient whiteGradient: Gradient {
        GradientStop { position: 0.0; color: "#30000000" }
        GradientStop { position: 0.2; color: "#10000000" }
        GradientStop { position: 0.8; color: "#00000000" }
        GradientStop { position: 1.0; color: "#40000000" }
    }

    property Gradient darkGradient: Gradient {
        GradientStop { position: 0.0; color: "#40FFFFFF" }
        GradientStop { position: 0.3; color: "#20FFFFFF" }
        GradientStop { position: 0.7; color: "#00FFFFFF" }
        GradientStop { position: 1.0; color: "#10000000" }
    }

    property Gradient crownGradient: Gradient {
        GradientStop { position: 0.0; color: "#60FFFFFF" }
        GradientStop { position: 0.4; color: "#30FFFFFF" }
        GradientStop { position: 1.0; color: "#20000000" }
    }
}
