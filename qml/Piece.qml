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

    // Update original position when model changes
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
        enabled: !piece.isDragging
        NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
    }
    Behavior on y {
        enabled: !piece.isDragging
        NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
    }

    Rectangle {
        id: outerCircle
        anchors.fill: parent
        radius: width / 2
        color: piece.model.isKing ? "#FFD700" :
               (piece.model.player === 1 ? "#F5F5F5" : "#3C3C3C")

        border.width: GameLogic.selectedPiece && GameLogic.selectedPiece.row === piece.model.row &&
                     GameLogic.selectedPiece.col === piece.model.col ?
                     Math.max(2, Math.round(width * 0.04)) : Math.max(1, Math.round(width * 0.02))
        border.color: GameLogic.selectedPiece && GameLogic.selectedPiece.row === piece.model.row &&
                     GameLogic.selectedPiece.col === piece.model.col ? "#F39C12" :
                     (piece.model.isKing ? "#B8860B" :
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
                    color: piece.model.isKing ? "#B8860B" :
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

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        drag.target: parent
        propagateComposedEvents: true
        enabled: {
            if (GameLogic.gameOver || GameLogic.animating || GameLogic.isResetting) return false

            // During chain capture, only the capturing piece can be moved
            if (GameLogic.inChainCapture) {
                return GameLogic.chainCapturePosition &&
                       GameLogic.chainCapturePosition.row === piece.model.row &&
                       GameLogic.chainCapturePosition.col === piece.model.col
            }

            // vs AI mode - only player 1 (white pieces) can be dragged on player 1's turn
            if (UserSettings.vsAI) {
                return GameLogic.isPlayer1Turn && piece.model.player === 1
            }

            // 2 player mode - current player can drag their pieces
            return (GameLogic.isPlayer1Turn && piece.model.player === 1) ||
                   (!GameLogic.isPlayer1Turn && piece.model.player === 2)
        }

        onPressed: {
            piece.isDragging = true
            piece.z = 10 // Bring to front while dragging

            // Select this piece
            let pieceData = GameLogic.getPieceAt(piece.model.row, piece.model.col)
            if (pieceData) {
                GameLogic.selectedPiece = {
                    row: piece.model.row,
                    col: piece.model.col,
                    index: pieceData.index
                }
            }
        }

        onReleased: {
            piece.isDragging = false
            piece.z = 0 // Reset z-order

            // Calculate which cell we're over
            let boardX = piece.x + piece.width/2
            let boardY = piece.y + piece.height/2

            // Convert to board coordinates
            let targetCol = Math.floor(boardX / GameLogic.cellSize)
            let targetRow = Math.floor(boardY / GameLogic.cellSize)

            // Check if drop position is valid
            if (targetRow >= 0 && targetRow < GameLogic.boardSize &&
                targetCol >= 0 && targetCol < GameLogic.boardSize) {

                let fromRow = piece.model.row
                let fromCol = piece.model.col

                // Try to execute the move through GameLogic
                let success = GameLogic.handlePieceDrop(fromRow, fromCol, targetRow, targetCol)

                if (success) {
                    // Valid move - animate to center of target cell
                    let targetCenterX = targetCol * GameLogic.cellSize + GameLogic.cellSize / 2 - piece.width/2
                    let targetCenterY = targetRow * GameLogic.cellSize + GameLogic.cellSize / 2 - piece.height/2
                    piece.x = targetCenterX
                    piece.y = targetCenterY
                } else {
                    // Invalid move - return to original position
                    returnToOriginalPosition()
                }
            } else {
                // Dropped outside board - return to original position
                returnToOriginalPosition()
            }
        }

        function returnToOriginalPosition() {
            piece.x = piece.originalX
            piece.y = piece.originalY
        }
    }
}
