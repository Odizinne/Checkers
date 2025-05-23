pragma ComponentBehavior: Bound

import QtQuick 2.15
import QtQuick.Window 2.15
import QtMultimedia

Window {
    id: root
    width: 840
    height: 840
    visible: true
    title: "Checkers"
    color: "#2C3E50"

    Column {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 20
        spacing: 10
        z: 1

        Row {
            spacing: 10
            anchors.horizontalCenter: parent.horizontalCenter

            Rectangle {
                width: 100
                height: 40
                color: "#3498DB"
                radius: 5

                Text {
                    anchors.centerIn: parent
                    text: "New Game"
                    color: "white"
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: table.initializeBoard()
                }
            }

            Rectangle {
                width: 120
                height: 40
                color: table.vsAI ? "#E74C3C" : "#27AE60"
                radius: 5

                Text {
                    anchors.centerIn: parent
                    text: table.vsAI ? "vs AI" : "vs Human"
                    color: "white"
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        table.vsAI = !table.vsAI
                        table.initializeBoard()
                    }
                }
            }
        }
    }

    Column {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 20
        spacing: 10
        z: 1

        Text {
            text: table.gameOver ? ("winner: Player " + table.winner) :
                  (table.inChainCapture ? "Continue capturing!" :
                   ("Player " + (table.isPlayer1Turn ? "1" : "2") + "'s Turn"))
            color: "white"
            font.pixelSize: 24
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    SoundEffect {
        id: captureFX
        source: "qrc:/sounds/capture.wav"
    }

    SoundEffect {
        id: moveFX
        source: "qrc:/sounds/move.wav"
    }

    Rectangle {
        id: table
        width: 800
        height: 800
        color: "#2C3E50"
        anchors.centerIn: parent

        property int boardSize: 8
        property int cellSize: 80
        property var selectedPiece: null
        property bool isPlayer1Turn: true
        property bool gameOver: false
        property int winner: 0
        property bool vsAI: true
        property bool animating: false
        property bool inChainCapture: false
        property var chainCapturePosition: null

        ListModel {
            id: boardModel
        }

        ListModel {
            id: piecesModel
        }

        Component.onCompleted: {
            initializeBoard()
        }

        function initializeBoard() {
            boardModel.clear()
            piecesModel.clear()

            for (let row = 0; row < table.boardSize; row++) {
                for (let col = 0; col < table.boardSize; col++) {
                    boardModel.append({
                        row: row,
                        col: col
                    })

                    if ((row + col) % 2 === 1) {
                        if (row < 3) {
                            piecesModel.append({
                                id: "piece_" + row + "_" + col,
                                row: row,
                                col: col,
                                player: 2,
                                isKing: false,
                                isAlive: true,
                                x: col * table.cellSize + table.cellSize / 2,
                                y: row * table.cellSize + table.cellSize / 2
                            })
                        } else if (row > 4) {
                            piecesModel.append({
                                id: "piece_" + row + "_" + col,
                                row: row,
                                col: col,
                                player: 1,
                                isKing: false,
                                isAlive: true,
                                x: col * table.cellSize + table.cellSize / 2,
                                y: row * table.cellSize + table.cellSize / 2
                            })
                        }
                    }
                }
            }

            table.gameOver = false
            table.winner = 0
            table.isPlayer1Turn = true
            table.selectedPiece = null
            table.animating = false
            table.inChainCapture = false
            table.chainCapturePosition = null
        }

        function handleCellClick(row, col) {
            if (table.gameOver || table.animating) return

            // During chain capture, only allow clicking on valid capture squares
            if (table.inChainCapture && table.chainCapturePosition) {
                if (isValidMove(table.chainCapturePosition.row, table.chainCapturePosition.col, row, col)) {
                    table.animating = true
                    movePiece(table.chainCapturePosition.row, table.chainCapturePosition.col, row, col)
                }
                return
            }

            if (table.selectedPiece !== null) {
                if (isValidMove(table.selectedPiece.row, table.selectedPiece.col, row, col)) {
                    table.animating = true
                    movePiece(table.selectedPiece.row, table.selectedPiece.col, row, col)
                } else {
                    let piece = getPieceAt(row, col)
                    if (piece && piece.player === (table.isPlayer1Turn ? 1 : 2)) {
                        table.selectedPiece = { row: row, col: col, index: piece.index }
                    } else {
                        table.selectedPiece = null
                    }
                }
            } else {
                let piece = getPieceAt(row, col)
                if (piece && piece.player === (table.isPlayer1Turn ? 1 : 2)) {
                    table.selectedPiece = { row: row, col: col, index: piece.index }
                }
            }
        }

        function getPieceAt(row, col) {
            for (let i = 0; i < piecesModel.count; i++) {
                let piece = piecesModel.get(i)
                if (piece.row === row && piece.col === col && piece.isAlive) {
                    return {
                        player: piece.player,
                        isKing: piece.isKing,
                        index: i
                    }
                }
            }
            return null
        }

        function getCaptureMoves(row, col) {
            let moves = []
            let piece = getPieceAt(row, col)
            if (!piece) return moves

            let directions = []
            if (piece.isKing) {
                directions = [[-1, -1], [-1, 1], [1, -1], [1, 1]]
            } else if (piece.player === 1) {
                directions = [[-1, -1], [-1, 1]]
            } else {
                directions = [[1, -1], [1, 1]]
            }

            for (let dir of directions) {
                let captureRow = row + dir[0] * 2
                let captureCol = col + dir[1] * 2
                let middleRow = row + dir[0]
                let middleCol = col + dir[1]

                if (captureRow >= 0 && captureRow < table.boardSize &&
                    captureCol >= 0 && captureCol < table.boardSize &&
                    !getPieceAt(captureRow, captureCol)) {
                    let middlePiece = getPieceAt(middleRow, middleCol)
                    if (middlePiece && middlePiece.player !== piece.player) {
                        moves.push({row: captureRow, col: captureCol})
                    }
                }
            }

            return moves
        }

        function isValidMove(fromRow, fromCol, toRow, toCol) {
            if (toRow < 0 || toRow >= table.boardSize || toCol < 0 || toCol >= table.boardSize)
                return false

            if (getPieceAt(toRow, toCol))
                return false

            let piece = getPieceAt(fromRow, fromCol)
            if (!piece) return false

            // If in chain capture, only capture moves are valid
            if (table.inChainCapture) {
                let captureMoves = getCaptureMoves(fromRow, fromCol)
                return captureMoves.some(m => m.row === toRow && m.col === toCol)
            }

            let rowDiff = toRow - fromRow
            let colDiff = Math.abs(toCol - fromCol)

            // Regular move
            if (colDiff === 1 && Math.abs(rowDiff) === 1) {
                // Check if any captures are available for current player
                if (hasAnyCaptures(piece.player)) {
                    return false // Must capture if possible
                }

                if (piece.isKing) {
                    return true
                } else {
                    return (piece.player === 1 && rowDiff === -1) ||
                           (piece.player === 2 && rowDiff === 1)
                }
            }

            // Capture move
            if (colDiff === 2 && Math.abs(rowDiff) === 2) {
                let middleRow = fromRow + rowDiff / 2
                let middleCol = fromCol + (toCol - fromCol) / 2
                let middlePiece = getPieceAt(middleRow, middleCol)

                if (middlePiece && middlePiece.player !== piece.player) {
                    if (piece.isKing) {
                        return true
                    } else {
                        return (piece.player === 1 && rowDiff === -2) ||
                               (piece.player === 2 && rowDiff === 2)
                    }
                }
            }

            return false
        }

        function hasAnyCaptures(player) {
            for (let i = 0; i < piecesModel.count; i++) {
                let piece = piecesModel.get(i)
                if (piece.isAlive && piece.player === player) {
                    if (getCaptureMoves(piece.row, piece.col).length > 0) {
                        return true
                    }
                }
            }
            return false
        }

        function movePiece(fromRow, fromCol, toRow, toCol) {
            let piece = getPieceAt(fromRow, fromCol)
            if (!piece) return

            let currentPiece = piecesModel.get(piece.index)
            let wasCapture = Math.abs(toRow - fromRow) === 2

            // Update piece position
            piecesModel.set(piece.index, {
                id: currentPiece.id,
                row: toRow,
                col: toCol,
                player: currentPiece.player,
                isKing: currentPiece.isKing,
                isAlive: currentPiece.isAlive,
                x: toCol * table.cellSize + table.cellSize / 2,
                y: toRow * table.cellSize + table.cellSize / 2
            })

            // Handle capture
            if (wasCapture) {
                captureFX.play()
                let rowDiff = toRow - fromRow
                let colDiff = toCol - fromCol
                let middleRow = fromRow + rowDiff / 2
                let middleCol = fromCol + colDiff / 2
                let capturedPiece = getPieceAt(middleRow, middleCol)
                if (capturedPiece) {
                    let capturedData = piecesModel.get(capturedPiece.index)
                    piecesModel.set(capturedPiece.index, {
                        id: capturedData.id,
                        row: capturedData.row,
                        col: capturedData.col,
                        player: capturedData.player,
                        isKing: capturedData.isKing,
                        isAlive: false,
                        x: capturedData.x,
                        y: capturedData.y
                    })
                }
            } else {
                moveFX.play()
            }

            // Check for king promotion
            if ((currentPiece.player === 1 && toRow === 0) ||
                (currentPiece.player === 2 && toRow === table.boardSize - 1)) {
                let updatedPiece = piecesModel.get(piece.index)
                piecesModel.set(piece.index, {
                    id: updatedPiece.id,
                    row: updatedPiece.row,
                    col: updatedPiece.col,
                    player: updatedPiece.player,
                    isKing: true,
                    isAlive: updatedPiece.isAlive,
                    x: updatedPiece.x,
                    y: updatedPiece.y
                })
            }

            // Update selected piece position for chain captures
            if (table.selectedPiece) {
                table.selectedPiece.row = toRow
                table.selectedPiece.col = toCol
            }

            animationTimer.wasCapture = wasCapture
            animationTimer.toRow = toRow
            animationTimer.toCol = toCol
            animationTimer.pieceIndex = piece.index
            animationTimer.start()
        }

        Timer {
            id: animationTimer
            interval: 300
            property bool wasCapture: false
            property int toRow: 0
            property int toCol: 0
            property int pieceIndex: -1

            onTriggered: {
                table.animating = false

                // Check for chain capture
                if (wasCapture) {
                    let availableCaptures = table.getCaptureMoves(toRow, toCol)
                    if (availableCaptures.length > 0) {
                        table.inChainCapture = true
                        table.chainCapturePosition = { row: toRow, col: toCol }
                        table.selectedPiece = { row: toRow, col: toCol, index: pieceIndex }

                        // If it's AI's turn and AI made the capture, continue with AI immediately
                        if (table.vsAI && !table.isPlayer1Turn) {
                            aiChainCaptureTimer.start()
                        }
                        return
                    }
                }

                // Turn ends
                table.inChainCapture = false
                table.chainCapturePosition = null
                table.isPlayer1Turn = !table.isPlayer1Turn
                table.selectedPiece = null

                table.checkGameState()

                if (!table.gameOver && table.vsAI && !table.isPlayer1Turn) {
                    aiTimer.start()
                }
            }
        }

        Timer {
            id: aiChainCaptureTimer
            interval: 400
            onTriggered: {
                if (table.inChainCapture && table.chainCapturePosition) {
                    let availableCaptures = table.getCaptureMoves(table.chainCapturePosition.row, table.chainCapturePosition.col)
                    if (availableCaptures.length > 0) {
                        let randomCapture = availableCaptures[Math.floor(Math.random() * availableCaptures.length)]
                        table.animating = true
                        table.movePiece(table.chainCapturePosition.row, table.chainCapturePosition.col, randomCapture.row, randomCapture.col)
                    }
                }
            }
        }

        function checkGameState() {
            let player1Count = 0
            let player2Count = 0

            for (let i = 0; i < piecesModel.count; i++) {
                let piece = piecesModel.get(i)
                if (piece.isAlive) {
                    if (piece.player === 1) player1Count++
                    else player2Count++
                }
            }

            // Check for no pieces left
            if (player1Count === 0) {
                table.gameOver = true
                table.winner = 2
                return
            } else if (player2Count === 0) {
                table.gameOver = true
                table.winner = 1
                return
            }

            // Check for no valid moves (stalemate = defeat)
            let currentPlayer = table.isPlayer1Turn ? 1 : 2
            if (!hasValidMoves(currentPlayer)) {
                table.gameOver = true
                table.winner = currentPlayer === 1 ? 2 : 1
            }
        }

        function hasValidMoves(player) {
            for (let i = 0; i < piecesModel.count; i++) {
                let piece = piecesModel.get(i)
                if (piece.isAlive && piece.player === player) {
                    // Check for captures first
                    if (getCaptureMoves(piece.row, piece.col).length > 0) {
                        return true
                    }

                    // If no captures available, check regular moves
                    if (!hasAnyCaptures(player)) {
                        let directions = piece.isKing ?
                            [[-1, -1], [-1, 1], [1, -1], [1, 1]] :
                            (piece.player === 1 ? [[-1, -1], [-1, 1]] : [[1, -1], [1, 1]])

                        for (let dir of directions) {
                            let newRow = piece.row + dir[0]
                            let newCol = piece.col + dir[1]
                            if (isValidMove(piece.row, piece.col, newRow, newCol)) {
                                return true
                            }
                        }
                    }
                }
            }
            return false
        }

        function makeAIMove() {
            let allMoves = []
            let captureMoves = []

            // Reset any lingering chain capture state when AI starts
            table.inChainCapture = false
            table.chainCapturePosition = null

            for (let i = 0; i < piecesModel.count; i++) {
                let piece = piecesModel.get(i)
                if (piece.isAlive && piece.player === 2) {
                    // Check for captures first
                    let captures = getCaptureMoves(piece.row, piece.col)
                    for (let capture of captures) {
                        captureMoves.push({
                            from: {row: piece.row, col: piece.col},
                            to: capture,
                            isCapture: true
                        })
                    }

                    // Regular moves only if no captures available
                    if (captureMoves.length === 0) {
                        let directions = [[-1, -1], [-1, 1], [1, -1], [1, 1]]
                        for (let dir of directions) {
                            let newRow = piece.row + dir[0]
                            let newCol = piece.col + dir[1]
                            if (table.isValidMove(piece.row, piece.col, newRow, newCol)) {
                                allMoves.push({
                                    from: {row: piece.row, col: piece.col},
                                    to: {row: newRow, col: newCol},
                                    isCapture: false
                                })
                            }
                        }
                    }
                }
            }

            let moveToMake = captureMoves.length > 0 ?
                captureMoves[Math.floor(Math.random() * captureMoves.length)] :
                allMoves[Math.floor(Math.random() * allMoves.length)]

            if (moveToMake) {
                table.animating = true
                table.movePiece(moveToMake.from.row, moveToMake.from.col,
                         moveToMake.to.row, moveToMake.to.col)
            } else {
                // AI has no valid moves - trigger game over
                table.checkGameState()
            }
        }

        Timer {
            id: aiTimer
            interval: 500
            onTriggered: table.makeAIMove()
        }

        Rectangle {
            id: board
            width: table.boardSize * table.cellSize
            height: table.boardSize * table.cellSize
            anchors.centerIn: parent
            color: "transparent"

            // Board squares
            Grid {
                rows: table.boardSize
                columns: table.boardSize

                Repeater {
                    model: boardModel

                    Rectangle {
                        id: boardRec
                        width: table.cellSize
                        height: table.cellSize
                        color: (model.row + model.col) % 2 === 0 ? "#F0D9B5" : "#B58863"
                        required property var model
                        Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                            visible: {
                                // Don't show valid moves during AI chain capture
                                if (table.vsAI && !table.isPlayer1Turn && table.inChainCapture) {
                                    return false
                                }

                                if (table.inChainCapture && table.chainCapturePosition) {
                                    return table.isValidMove(table.chainCapturePosition.row, table.chainCapturePosition.col, boardRec.model.row, boardRec.model.col)
                                } else if (table.selectedPiece) {
                                    return table.isValidMove(table.selectedPiece.row, table.selectedPiece.col, boardRec.model.row, boardRec.model.col)
                                }
                                return false
                            }
                            border.width: 3
                            border.color: table.inChainCapture ? "#E74C3C" : "#27AE60"

                            Rectangle {
                                anchors.centerIn: parent
                                width: 10
                                height: 10
                                radius: 5
                                color: table.inChainCapture ? "#E74C3C" : "#27AE60"
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: table.handleCellClick(boardRec.model.row, boardRec.model.col)
                        }
                    }
                }
            }

            // Pieces layer
            Item {
                anchors.fill: parent

                Repeater {
                    model: piecesModel

                    Item {
                        id: itemModel
                        x: model.x - 30
                        y: model.y - 30
                        width: 60
                        height: 60
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
                            radius: 30
                            color: itemModel.model.player === 1 ? "#F5F5F5" : "#3C3C3C"
                            border.width: table.selectedPiece && table.selectedPiece.row === itemModel.model.row &&
                                         table.selectedPiece.col === itemModel.model.col ? 3 : 1
                            border.color: table.selectedPiece && table.selectedPiece.row === itemModel.model.row &&
                                         table.selectedPiece.col === itemModel.model.col ? "#F39C12" :
                                         (itemModel.model.player === 1 ? "#E0E0E0" : "#2C2C2C")

                            // Inner circle
                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width * 0.7
                                height: parent.height * 0.7
                                radius: width / 2
                                color: itemModel.model.player === 1 ? "#D0D0D0" : "#1F1F1F"

                                // King crown (replaces the inner circle when king)
                                Rectangle {
                                    visible: itemModel.model.isKing
                                    anchors.centerIn: parent
                                    width: parent.width * 0.6
                                    height: parent.height * 0.6
                                    radius: width / 2
                                    color: "#FFD700"
                                }
                            }

                            scale: itemModel.model.isAlive ? 1 : 0
                            Behavior on scale {
                                NumberAnimation { duration: 300; easing.type: Easing.InBack }
                            }
                        }
                    }
                }
            }
        }
    }
}
