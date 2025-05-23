#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QIcon>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setOrganizationName("Odizinne");
    app.setApplicationName("Checkers");
    QGuiApplication::setWindowIcon(QIcon(":/icons/icon.png"));
    QQmlApplicationEngine engine;
    engine.loadFromModule("Odizinne.Checkers", "Main");

    return app.exec();
}
