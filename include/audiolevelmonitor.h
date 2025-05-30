#ifndef AUDIOLEVELMONITOR_H
#define AUDIOLEVELMONITOR_H

#include <QObject>
#include <QAudioSource>
#include <QAudioDevice>
#include <QMediaDevices>
#include <QIODevice>
#include <QTimer>
#include <QBuffer>
#include <QtMath>
#include <QtQml/qqmlregistration.h>
#include <QQmlEngine>

#if QT_CONFIG(permissions)
#include <QPermissions>
#include <QCoreApplication>
#endif

class AudioLevelMonitor : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(qreal audioLevel READ audioLevel NOTIFY audioLevelChanged)
    Q_PROPERTY(qreal decibelLevel READ decibelLevel NOTIFY audioLevelChanged)
    Q_PROPERTY(bool isActive READ isActive NOTIFY isActiveChanged)
    Q_PROPERTY(bool hasPermission READ hasPermission NOTIFY hasPermissionChanged)
    Q_PROPERTY(bool shouldTurnOffCandle READ shouldTurnOffCandle NOTIFY shouldTurnOffCandleChanged)

public:
    explicit AudioLevelMonitor(QObject *parent = nullptr);
    ~AudioLevelMonitor();

    static AudioLevelMonitor* create(QQmlEngine*, QJSEngine*)
    {
        return new AudioLevelMonitor();
    }

    qreal audioLevel() const { return m_audioLevel; }
    qreal decibelLevel() const { return m_decibelLevel; }
    bool isActive() const { return m_isActive; }
    bool hasPermission() const { return m_hasPermission; }
    bool shouldTurnOffCandle() const { return m_shouldTurnOffCandle; }

public slots:
    void requestPermission();
    void startMonitoring();
    void stopMonitoring();

signals:
    void audioLevelChanged();
    void isActiveChanged();
    void hasPermissionChanged();
    void shouldTurnOffCandleChanged();

private slots:
    void processAudioData();

private:
    QAudioSource* m_audioSource;
    QIODevice* m_audioDevice;
    QTimer* m_timer;
    qreal m_audioLevel;
    qreal m_decibelLevel;
    bool m_isActive;
    bool m_hasPermission;
    bool m_shouldTurnOffCandle;
    bool m_hasTriggeredCandle;

    void createAudioSource();
    void checkPermission();
};

#endif // AUDIOLEVELMONITOR_H
