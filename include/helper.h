#ifndef HELPER_H
#define HELPER_H

#include <QObject>
#include <QQmlEngine>
#include <QTranslator>

class Helper : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    static Helper* create(QQmlEngine *qmlEngine, QJSEngine *jsEngine);
    static Helper* instance();

    Q_INVOKABLE void changeApplicationLanguage(int languageIndex);

private:
    explicit Helper(QObject *parent = nullptr);
    static Helper* m_instance;
    QTranslator* translator = nullptr;
    QQmlEngine* m_engine = nullptr;
};

#endif // HELPER_H
