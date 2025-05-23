#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QIcon>

int main(int argc, char *argv[])
{
    qputenv("QT_QUICK_CONTROLS_MATERIAL_VARIANT", "Dense");
    QGuiApplication app(argc, argv);
    app.setOrganizationName("Odizinne");
    app.setApplicationName("Checkers");
    QGuiApplication::setWindowIcon(QIcon(":/icons/icon.png"));
    QQmlApplicationEngine engine;
    engine.loadFromModule("Odizinne.Checkers", "Main");

    return app.exec();
}
