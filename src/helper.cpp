#include "helper.h"
#include <QGuiApplication>
#include <QLocale>

Helper* Helper::m_instance = nullptr;

Helper::Helper(QObject *parent)
    : QObject(parent)
{
}

Helper* Helper::create(QQmlEngine *qmlEngine, QJSEngine *jsEngine)
{
    Q_UNUSED(jsEngine)

    Helper* helper = instance();
    helper->m_engine = qmlEngine;
    return helper;
}

Helper* Helper::instance()
{
    if (!m_instance) {
        m_instance = new Helper();
    }
    return m_instance;
}

void Helper::changeApplicationLanguage(int languageIndex)
{
    if (translator) {
        qApp->removeTranslator(translator);
        delete translator;
    }

    translator = new QTranslator(this);
    QString languageCode;

    if (languageIndex == 0) {
        QLocale systemLocale;
        languageCode = systemLocale.name().left(2);
    } else {
        switch (languageIndex) {
        case 1:
            languageCode = "en";
            break;
        case 2:
            languageCode = "fr";
            break;
        default:
            languageCode = "en";
            break;
        }
    }

    QString translationFile = QString(":/i18n/Checkers_%1.qm").arg(languageCode);
    if (translator->load(translationFile)) {
        qGuiApp->installTranslator(translator);
    } else {
        qWarning() << "Failed to load translation file:" << translationFile;
    }

    if (m_engine) {
        m_engine->retranslate();
    }
}
