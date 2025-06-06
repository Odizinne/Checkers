import QtQuick
import Odizinne.Checkers

Item {
    id: piece
    x: model.x - width/2
    y: model.y - height/2
    width: GameLogic.cellSize * 0.75
    height: GameLogic.cellSize * 0.75
    required property var model

    property real originalX: model.x - width/2
    property real originalY: model.y - height/2
    property bool isDragging: false

    onOriginalXChanged: {
        if (!isDragging) {
            x = originalX
        }
    }
    onOriginalYChanged: {
        if (!isDragging) {
            y = originalY
        }
    }

    Behavior on x {
        enabled: !piece.isDragging && !GameLogic.isResizing
        NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
    }
    Behavior on y {
        enabled: !piece.isDragging && !GameLogic.isResizing
        NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
    }

    Rectangle {
        id: outerCircle
        anchors.fill: parent
        radius: width / 2
        color: piece.model.isKing ? "#F0D788" :
                                    (piece.model.player === 1 ? "#F5F5F5" : "#3C3C3C")

        border.width: GameLogic.selectedPiece && GameLogic.selectedPiece.row === piece.model.row &&
                      GameLogic.selectedPiece.col === piece.model.col ?
                          Math.max(2, Math.round(width * 0.04)) : Math.max(1, Math.round(width * 0.02))
        border.color: GameLogic.selectedPiece && GameLogic.selectedPiece.row === piece.model.row &&
                      GameLogic.selectedPiece.col === piece.model.col ? "#F39C12" :
                                                                        (piece.model.isKing ? "#D4B630" :
                                                                                              (piece.model.player === 1 ? "#E0E0E0" : "#2C2C2C"))

        width: Math.min(parent.width, parent.height)
        height: width
        anchors.centerIn: parent

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            opacity: 0.3

            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: piece.model.isKing ? "#FFFFFF" :
                                                (piece.model.player === 1 ? "#40000000" : "#10FFFFFF")
                }
                GradientStop {
                    position: 1.0
                    color: piece.model.isKing ? "#D4B630" :
                                                (piece.model.player === 1 ? "#10FFFFFF" : "#40000000")
                }
            }
        }

        Rectangle {
            id: innerCircle
            anchors.centerIn: parent
            width: Math.round(parent.width * 0.7)
            height: width
            radius: width / 2
            color: piece.model.player === 1 ? "#D0D0D0" : "#1F1F1F"

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                opacity: 0.4
                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: piece.model.player === 1 ? "#40000000" : "#20000000"
                    }
                    GradientStop {
                        position: 1.0
                        color: piece.model.player === 1 ? "#10FFFFFF" : "#30FFFFFF"
                    }
                }
            }
        }

        scale: (piece.model.isAlive && !GameLogic.isResetting) ? 1 : 0
        opacity: (piece.model.isAlive && !GameLogic.isResetting) ? 1 : 0

        Behavior on scale {
            NumberAnimation {
                duration: GameLogic.isResetting ? 300 : 300
                easing.type: GameLogic.isResetting ? Easing.OutQuad : Easing.InBack
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: GameLogic.isResetting ? 300 : 300
                easing.type: GameLogic.isResetting ? Easing.OutQuad : Easing.InQuad
            }
        }
    }
}
