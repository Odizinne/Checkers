#ifndef AIPLAYER_H
#define AIPLAYER_H

#include <QObject>
#include <QQmlEngine>
#include <QVariantList>
#include <QVariantMap>
#include <QHash>
#include <QJSValue>

struct Move {
    int fromRow = -1, fromCol = -1;
    int toRow = -1, toCol = -1;
    bool isCapture = false;

    bool isValid() const {
        return fromRow >= 0 && fromCol >= 0 && toRow >= 0 && toCol >= 0;
    }
};

struct Piece {
    int row, col;
    int player;
    bool isKing;
};

struct BoardState {
    QList<Piece> pieces;
    QVector<QVector<int>> board; // -1 = empty, index into pieces list
};

struct MinimaxResult {
    int score = 0;
    Move move;
    bool hasMove = false;
    int depth = 0;
};

class AIPlayer : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    static AIPlayer* create(QQmlEngine *qmlEngine, QJSEngine *jsEngine);
    static AIPlayer* instance();

    Q_INVOKABLE QVariantMap makeMove();
    Q_INVOKABLE QVariantMap makeChainCaptureMove();

private:
    explicit AIPlayer(QObject *parent = nullptr);
    static AIPlayer* m_instance;

    // Core AI methods
    MinimaxResult minimax(const BoardState& state, int depth, int alpha, int beta, bool maximizing);
    BoardState getBoardState();
    QList<Move> getAllPossibleMoves(const BoardState& state, int player);
    QList<Move> getCaptureMoves(const BoardState& state, int row, int col, int player);
    QList<Move> getRegularMoves(const BoardState& state, int row, int col, int player, bool isKing);
    BoardState applyMove(const BoardState& state, const Move& move);
    int evaluateBoard(const BoardState& state);
    int evaluatePiecePosition(const Piece& piece);
    QList<Move> orderMoves(const QList<Move>& moves, const BoardState& state);
    bool isGameOver(const BoardState& state);
    QString getBoardKey(const BoardState& state);
    bool hasAnyCaptures(const BoardState& state, int player);

    // Settings access with caching
    bool getAllowBackwardCaptures();
    bool getOptionalCaptures();
    bool getKingFastForward();
    int getBoardSize();
    void updateSettingsCache();

    // Game state access
    QObject* getGameLogic();
    QObject* getUserSettings();
    QVariantList getPiecesModel();
    bool getInChainCapture();
    QVariantMap getChainCapturePosition();

    // Cache for settings
    mutable bool m_settingsCached = false;
    mutable bool m_allowBackwardCaptures = false;
    mutable bool m_optionalCaptures = false;
    mutable bool m_kingFastForward = false;
    mutable int m_boardSize = 8;

    // Cache
    QHash<QString, MinimaxResult> m_transpositionTable;
    int m_maxDepth = 3; // Reduced for better performance
};

#endif // AIPLAYER_H
