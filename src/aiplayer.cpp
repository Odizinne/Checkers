#include "aiplayer.h"
#include <QQmlEngine>
#include <QJSEngine>
#include <QQmlContext>
#include <QGuiApplication>
#include <QMetaObject>
#include <algorithm>
#include <limits>

AIPlayer* AIPlayer::m_instance = nullptr;

AIPlayer::AIPlayer(QObject *parent)
    : QObject(parent)
{
}

AIPlayer* AIPlayer::create(QQmlEngine *qmlEngine, QJSEngine *jsEngine)
{
    Q_UNUSED(jsEngine)
    Q_UNUSED(qmlEngine)
    return instance();
}

AIPlayer* AIPlayer::instance()
{
    if (!m_instance) {
        m_instance = new AIPlayer();
    }
    return m_instance;
}

QVariantMap AIPlayer::makeMove()
{
    QVariantMap result;

    // Reset cache for fresh settings
    m_settingsCached = false;

    BoardState state = getBoardState();
    MinimaxResult aiResult = minimax(state, m_maxDepth,
                                     std::numeric_limits<int>::min(),
                                     std::numeric_limits<int>::max(), true);

    if (aiResult.hasMove && aiResult.move.isValid()) {
        result["from"] = QVariantMap{
            {"row", aiResult.move.fromRow},
            {"col", aiResult.move.fromCol}
        };
        result["to"] = QVariantMap{
            {"row", aiResult.move.toRow},
            {"col", aiResult.move.toCol}
        };
        result["isCapture"] = aiResult.move.isCapture;
    }

    return result;
}

QVariantMap AIPlayer::makeChainCaptureMove()
{
    QVariantMap result;

    if (getInChainCapture()) {
        QVariantMap pos = getChainCapturePosition();
        if (!pos.isEmpty()) {
            int row = pos["row"].toInt();
            int col = pos["col"].toInt();

            BoardState state = getBoardState();
            QList<Move> captures = getCaptureMoves(state, row, col, 2);

            if (!captures.isEmpty()) {
                // Find best capture
                Move bestCapture;
                int bestScore = std::numeric_limits<int>::min();

                for (const Move& capture : captures) {
                    BoardState newState = applyMove(state, capture);
                    int score = evaluateBoard(newState);
                    if (score > bestScore) {
                        bestScore = score;
                        bestCapture = capture;
                    }
                }

                if (bestCapture.isValid()) {
                    result["from"] = QVariantMap{
                        {"row", row},
                        {"col", col}
                    };
                    result["to"] = QVariantMap{
                        {"row", bestCapture.toRow},
                        {"col", bestCapture.toCol}
                    };
                    result["isCapture"] = true;
                }
            }
        }
    }

    return result;
}

void AIPlayer::updateSettingsCache()
{
    if (!m_settingsCached) {
        QObject* userSettings = getUserSettings();
        if (userSettings) {
            m_allowBackwardCaptures = userSettings->property("allowBackwardCaptures").toBool();
            m_optionalCaptures = userSettings->property("optionalCaptures").toBool();
            m_kingFastForward = userSettings->property("kingFastForward").toBool();
            m_boardSize = userSettings->property("boardSize").toInt();
            m_settingsCached = true;
        }
    }
}

BoardState AIPlayer::getBoardState()
{
    BoardState state;
    int boardSize = getBoardSize();

    // Initialize board
    state.board = QVector<QVector<int>>(boardSize, QVector<int>(boardSize, -1));

    // Get pieces from QML model
    QVariantList pieces = getPiecesModel();
    state.pieces.reserve(pieces.size()); // Reserve space for efficiency

    for (int i = 0; i < pieces.size(); ++i) {
        QVariantMap pieceData = pieces[i].toMap();
        if (pieceData["isAlive"].toBool()) {
            Piece piece;
            piece.row = pieceData["row"].toInt();
            piece.col = pieceData["col"].toInt();
            piece.player = pieceData["player"].toInt();
            piece.isKing = pieceData["isKing"].toBool();

            state.pieces.append(piece);
            state.board[piece.row][piece.col] = state.pieces.size() - 1;
        }
    }

    return state;
}

MinimaxResult AIPlayer::minimax(const BoardState& state, int depth, int alpha, int beta, bool maximizing)
{
    // Clear cache if it gets too large to prevent memory issues
    if (m_transpositionTable.size() > 10000) {
        m_transpositionTable.clear();
    }

    QString key = getBoardKey(state);

    // Check cache
    if (m_transpositionTable.contains(key)) {
        const MinimaxResult& cached = m_transpositionTable[key];
        if (cached.depth >= depth) {
            return cached;
        }
    }

    if (depth == 0 || isGameOver(state)) {
        MinimaxResult result;
        result.score = evaluateBoard(state);
        result.hasMove = false;
        result.depth = depth;
        return result;
    }

    QList<Move> moves = getAllPossibleMoves(state, maximizing ? 2 : 1);

    if (moves.isEmpty()) {
        MinimaxResult result;
        result.score = maximizing ? -10000 : 10000;
        result.hasMove = false;
        result.depth = depth;
        return result;
    }

    moves = orderMoves(moves, state);

    MinimaxResult bestResult;
    bestResult.score = maximizing ? std::numeric_limits<int>::min() : std::numeric_limits<int>::max();
    bestResult.hasMove = false;
    bestResult.depth = depth;

    for (const Move& move : moves) {
        BoardState newState = applyMove(state, move);
        MinimaxResult result = minimax(newState, depth - 1, alpha, beta, !maximizing);

        if (maximizing) {
            if (result.score > bestResult.score) {
                bestResult.score = result.score;
                bestResult.move = move;
                bestResult.hasMove = true;
            }
            alpha = std::max(alpha, bestResult.score);
        } else {
            if (result.score < bestResult.score) {
                bestResult.score = result.score;
                bestResult.move = move;
                bestResult.hasMove = true;
            }
            beta = std::min(beta, bestResult.score);
        }

        if (beta <= alpha) {
            break; // Alpha-beta pruning
        }
    }

    // Cache result
    m_transpositionTable[key] = bestResult;

    return bestResult;
}

QList<Move> AIPlayer::getAllPossibleMoves(const BoardState& state, int player)
{
    QList<Move> allMoves;
    QList<Move> captureMoves;

    for (const Piece& piece : state.pieces) {
        if (piece.player == player) {
            QList<Move> captures = getCaptureMoves(state, piece.row, piece.col, player);
            captureMoves.append(captures);

            // If optional captures is enabled OR no captures available, include regular moves
            if (getOptionalCaptures() || captureMoves.isEmpty()) {
                QList<Move> regularMoves = getRegularMoves(state, piece.row, piece.col, piece.player, piece.isKing);
                allMoves.append(regularMoves);
            }
        }
    }

    // If optional captures is disabled, prioritize captures
    if (!getOptionalCaptures() && !captureMoves.isEmpty()) {
        return captureMoves;
    }

    allMoves.append(captureMoves);
    return allMoves;
}

QList<Move> AIPlayer::getCaptureMoves(const BoardState& state, int row, int col, int player)
{
    QList<Move> moves;
    int boardSize = getBoardSize();

    if (row < 0 || row >= boardSize || col < 0 || col >= boardSize) {
        return moves;
    }

    int pieceIndex = state.board[row][col];
    if (pieceIndex == -1 || pieceIndex >= state.pieces.size()) {
        return moves;
    }

    const Piece& piece = state.pieces[pieceIndex];

    // King fast forward captures
    if (piece.isKing && getKingFastForward()) {
        QList<QPair<int, int>> directions = {{-1, -1}, {-1, 1}, {1, -1}, {1, 1}};

        for (const auto& dir : directions) {
            bool foundEnemy = false;

            for (int distance = 1; distance < boardSize; ++distance) {
                int targetRow = row + (dir.first * distance);
                int targetCol = col + (dir.second * distance);

                if (targetRow < 0 || targetRow >= boardSize || targetCol < 0 || targetCol >= boardSize) {
                    break;
                }

                int targetIndex = state.board[targetRow][targetCol];
                if (targetIndex != -1) {
                    if (!foundEnemy && targetIndex < state.pieces.size() &&
                        state.pieces[targetIndex].player != player) {
                        // Found first enemy piece in this direction
                        foundEnemy = true;
                    } else {
                        // Hit another piece (friendly or second enemy), stop here
                        break;
                    }
                } else if (foundEnemy) {
                    // Empty square after enemy piece - valid capture landing spot
                    Move move;
                    move.fromRow = row;
                    move.fromCol = col;
                    move.toRow = targetRow;
                    move.toCol = targetCol;
                    move.isCapture = true;
                    moves.append(move);
                }
            }
        }
        return moves;
    }

    // Regular captures
    QList<QPair<int, int>> directions;
    if (piece.isKing) {
        directions = {{-1, -1}, {-1, 1}, {1, -1}, {1, 1}};
    } else if (player == 1) {
        directions = {{-1, -1}, {-1, 1}};
        if (getAllowBackwardCaptures()) {
            directions.append({{1, -1}, {1, 1}});
        }
    } else {
        directions = {{1, -1}, {1, 1}};
        if (getAllowBackwardCaptures()) {
            directions.append({{-1, -1}, {-1, 1}});
        }
    }

    for (const auto& dir : directions) {
        int captureRow = row + dir.first * 2;
        int captureCol = col + dir.second * 2;
        int middleRow = row + dir.first;
        int middleCol = col + dir.second;

        if (captureRow >= 0 && captureRow < boardSize &&
            captureCol >= 0 && captureCol < boardSize &&
            state.board[captureRow][captureCol] == -1) {

            int middleIndex = state.board[middleRow][middleCol];
            if (middleIndex != -1 && middleIndex < state.pieces.size() &&
                state.pieces[middleIndex].player != player) {

                Move move;
                move.fromRow = row;
                move.fromCol = col;
                move.toRow = captureRow;
                move.toCol = captureCol;
                move.isCapture = true;
                moves.append(move);
            }
        }
    }

    return moves;
}

QList<Move> AIPlayer::getRegularMoves(const BoardState& state, int row, int col, int player, bool isKing)
{
    QList<Move> moves;
    int boardSize = getBoardSize();

    // King fast forward moves
    if (isKing && getKingFastForward()) {
        QList<QPair<int, int>> directions = {{-1, -1}, {-1, 1}, {1, -1}, {1, 1}};

        for (const auto& dir : directions) {
            for (int distance = 1; distance < boardSize; ++distance) {
                int newRow = row + (dir.first * distance);
                int newCol = col + (dir.second * distance);

                if (newRow < 0 || newRow >= boardSize || newCol < 0 || newCol >= boardSize) {
                    break;
                }

                if (state.board[newRow][newCol] != -1) {
                    break;
                }

                Move move;
                move.fromRow = row;
                move.fromCol = col;
                move.toRow = newRow;
                move.toCol = newCol;
                move.isCapture = false;
                moves.append(move);
            }
        }
        return moves;
    }

    // Regular moves
    QList<QPair<int, int>> directions;
    if (isKing) {
        directions = {{-1, -1}, {-1, 1}, {1, -1}, {1, 1}};
    } else if (player == 1) {
        directions = {{-1, -1}, {-1, 1}};
    } else {
        directions = {{1, -1}, {1, 1}};
    }

    for (const auto& dir : directions) {
        int newRow = row + dir.first;
        int newCol = col + dir.second;
        if (newRow >= 0 && newRow < boardSize && newCol >= 0 && newCol < boardSize &&
            state.board[newRow][newCol] == -1) {

            Move move;
            move.fromRow = row;
            move.fromCol = col;
            move.toRow = newRow;
            move.toCol = newCol;
            move.isCapture = false;
            moves.append(move);
        }
    }

    return moves;
}

BoardState AIPlayer::applyMove(const BoardState& state, const Move& move)
{
    BoardState newState;
    newState.pieces.reserve(state.pieces.size()); // Reserve space for efficiency

    int boardSize = getBoardSize();
    newState.board = QVector<QVector<int>>(boardSize, QVector<int>(boardSize, -1));

    // Copy pieces more efficiently
    for (const Piece& piece : state.pieces) {
        newState.pieces.append(piece);
    }

    // Find and move the piece
    int movedPieceIndex = -1;
    for (int i = 0; i < newState.pieces.size(); ++i) {
        if (newState.pieces[i].row == move.fromRow && newState.pieces[i].col == move.fromCol) {
            newState.pieces[i].row = move.toRow;
            newState.pieces[i].col = move.toCol;
            movedPieceIndex = i;

            // Check for promotion
            if ((newState.pieces[i].player == 1 && move.toRow == 0) ||
                (newState.pieces[i].player == 2 && move.toRow == boardSize - 1)) {
                newState.pieces[i].isKing = true;
            }
            break;
        }
    }

    // Handle capture - remove captured pieces
    if (move.isCapture) {
        if (movedPieceIndex >= 0 && newState.pieces[movedPieceIndex].isKing && getKingFastForward()) {
            // King fast forward capture - remove pieces in path
            int rowDir = move.toRow > move.fromRow ? 1 : -1;
            int colDir = move.toCol > move.fromCol ? 1 : -1;

            for (int i = 1; i < qAbs(move.toRow - move.fromRow); ++i) {
                int checkRow = move.fromRow + (rowDir * i);
                int checkCol = move.fromCol + (colDir * i);

                // Remove captured piece efficiently (iterate backwards to avoid index issues)
                for (int j = newState.pieces.size() - 1; j >= 0; --j) {
                    if (newState.pieces[j].row == checkRow && newState.pieces[j].col == checkCol &&
                        newState.pieces[j].player != newState.pieces[movedPieceIndex].player) {
                        newState.pieces.removeAt(j);
                        if (j < movedPieceIndex) movedPieceIndex--; // Adjust index
                        break;
                    }
                }
            }
        } else {
            // Regular capture
            int middleRow = move.fromRow + (move.toRow - move.fromRow) / 2;
            int middleCol = move.fromCol + (move.toCol - move.fromCol) / 2;

            // Remove captured piece (iterate backwards)
            for (int i = newState.pieces.size() - 1; i >= 0; --i) {
                if (newState.pieces[i].row == middleRow && newState.pieces[i].col == middleCol) {
                    newState.pieces.removeAt(i);
                    break;
                }
            }
        }
    }

    // Rebuild board index - only once at the end
    for (int i = 0; i < newState.pieces.size(); ++i) {
        const Piece& piece = newState.pieces[i];
        newState.board[piece.row][piece.col] = i;
    }

    return newState;
}

int AIPlayer::evaluateBoard(const BoardState& state)
{
    int score = 0;
    int player1Pieces = 0;
    int player2Pieces = 0;
    int player1Kings = 0;
    int player2Kings = 0;
    int boardSize = getBoardSize();

    for (const Piece& piece : state.pieces) {
        if (piece.player == 1) {
            player1Pieces++;
            if (piece.isKing) player1Kings++;
        } else {
            player2Pieces++;
            if (piece.isKing) player2Kings++;
        }

        // Positional scoring
        int positionScore = evaluatePiecePosition(piece);
        if (piece.player == 2) {
            score += positionScore;
        } else {
            score -= positionScore;
        }
    }

    // Material advantage
    score += (player2Pieces - player1Pieces) * 100;
    score += (player2Kings - player1Kings) * 50;

    // Back row protection bonus for AI
    int backRowBonus = 0;
    for (int col = 1; col < boardSize; col += 2) {
        if (state.board[boardSize - 1][col] != -1) {
            int pieceIndex = state.board[boardSize - 1][col];
            if (pieceIndex < state.pieces.size() &&
                state.pieces[pieceIndex].player == 2 &&
                !state.pieces[pieceIndex].isKing) {
                backRowBonus += 10;
            }
        }
    }
    score += backRowBonus;

    // Mobility
    int player1Mobility = getAllPossibleMoves(state, 1).size();
    int player2Mobility = getAllPossibleMoves(state, 2).size();
    score += (player2Mobility - player1Mobility) * 5;

    return score;
}

int AIPlayer::evaluatePiecePosition(const Piece& piece)
{
    int score = 0;
    int boardSize = getBoardSize();

    // Base value
    score += piece.isKing ? 150 : 100;

    // Center control is valuable
    double centerDistance = qAbs(piece.row - (boardSize - 1) / 2.0) +
                            qAbs(piece.col - (boardSize - 1) / 2.0);
    score += ((boardSize * 2) - centerDistance) * 3;

    // Advanced position bonus
    if (piece.player == 1) {
        score += (boardSize - 1 - piece.row) * 5;
    } else {
        score += piece.row * 5;
    }

    // Side pieces are slightly less valuable
    if (piece.col == 0 || piece.col == boardSize - 1) {
        score -= 5;
    }

    return score;
}

QList<Move> AIPlayer::orderMoves(const QList<Move>& moves, const BoardState& state)
{
    QList<QPair<Move, int>> scoredMoves;
    scoredMoves.reserve(moves.size());

    for (const Move& move : moves) {
        int score = 0;

        // Captures get highest priority
        if (move.isCapture) score += 1000;

        // King moves get higher priority
        int pieceIndex = state.board[move.fromRow][move.fromCol];
        if (pieceIndex >= 0 && pieceIndex < state.pieces.size() && state.pieces[pieceIndex].isKing) {
            score += 100;
        }

        // Center moves get slight bonus
        int centerDistance = qAbs(move.toRow - getBoardSize()/2) + qAbs(move.toCol - getBoardSize()/2);
        score += (getBoardSize() - centerDistance);

        scoredMoves.append({move, score});
    }

    // Sort by score (highest first)
    std::sort(scoredMoves.begin(), scoredMoves.end(),
              [](const QPair<Move, int>& a, const QPair<Move, int>& b) {
                  return a.second > b.second;
              });

    QList<Move> result;
    result.reserve(moves.size());
    for (const auto& pair : scoredMoves) {
        result.append(pair.first);
    }

    return result;
}

bool AIPlayer::isGameOver(const BoardState& state)
{
    int player1Count = 0;
    int player2Count = 0;

    for (const Piece& piece : state.pieces) {
        if (piece.player == 1) player1Count++;
        else player2Count++;
    }

    return player1Count == 0 || player2Count == 0;
}

QString AIPlayer::getBoardKey(const BoardState& state)
{
    QString key;
    int boardSize = getBoardSize();

    for (int row = 0; row < boardSize; ++row) {
        for (int col = 0; col < boardSize; ++col) {
            int pieceIndex = state.board[row][col];
            if (pieceIndex != -1 && pieceIndex < state.pieces.size()) {
                const Piece& piece = state.pieces[pieceIndex];
                key += QString::number(piece.player) + (piece.isKing ? "K" : "") + ",";
            } else {
                key += "0,";
            }
        }
    }

    return key;
}

bool AIPlayer::hasAnyCaptures(const BoardState& state, int player)
{
    for (const Piece& piece : state.pieces) {
        if (piece.player == player) {
            if (!getCaptureMoves(state, piece.row, piece.col, player).isEmpty()) {
                return true;
            }
        }
    }
    return false;
}

// Helper methods to access QML singletons
QObject* AIPlayer::getGameLogic()
{
    QQmlEngine* engine = qmlEngine(this);
    if (!engine) return nullptr;

    return engine->singletonInstance<QObject*>("Odizinne.Checkers", "GameLogic");
}

QObject* AIPlayer::getUserSettings()
{
    QQmlEngine* engine = qmlEngine(this);
    if (!engine) return nullptr;

    return engine->singletonInstance<QObject*>("Odizinne.Checkers", "UserSettings");
}

bool AIPlayer::getAllowBackwardCaptures()
{
    updateSettingsCache();
    return m_allowBackwardCaptures;
}

bool AIPlayer::getOptionalCaptures()
{
    updateSettingsCache();
    return m_optionalCaptures;
}

bool AIPlayer::getKingFastForward()
{
    updateSettingsCache();
    return m_kingFastForward;
}

int AIPlayer::getBoardSize()
{
    updateSettingsCache();
    return m_boardSize;
}

QVariantList AIPlayer::getPiecesModel()
{
    QObject* gameLogic = getGameLogic();
    if (!gameLogic) return QVariantList();

    QObject* model = gameLogic->property("piecesModel").value<QObject*>();
    if (!model) return QVariantList();

    QVariantList result;
    int count = model->property("count").toInt();

    // Get QML engine to properly handle QJSValue conversion
    QQmlEngine* engine = qmlEngine(this);
    if (!engine) return QVariantList();

    for (int i = 0; i < count; ++i) {
        QJSValue item;
        QMetaObject::invokeMethod(model, "get", Q_RETURN_ARG(QJSValue, item), Q_ARG(int, i));

        // Convert QJSValue to QVariantMap
        if (item.isObject()) {
            QVariantMap pieceData;
            pieceData["id"] = item.property("id").toString();
            pieceData["row"] = item.property("row").toInt();
            pieceData["col"] = item.property("col").toInt();
            pieceData["player"] = item.property("player").toInt();
            pieceData["isKing"] = item.property("isKing").toBool();
            pieceData["isAlive"] = item.property("isAlive").toBool();
            pieceData["x"] = item.property("x").toNumber();
            pieceData["y"] = item.property("y").toNumber();

            result.append(pieceData);
        }
    }

    return result;
}

bool AIPlayer::getInChainCapture()
{
    QObject* gameLogic = getGameLogic();
    return gameLogic ? gameLogic->property("inChainCapture").toBool() : false;
}

QVariantMap AIPlayer::getChainCapturePosition()
{
    QObject* gameLogic = getGameLogic();
    if (!gameLogic) return QVariantMap();

    QVariant pos = gameLogic->property("chainCapturePosition");
    return pos.toMap();
}
