#include "AudioLevelMonitor.h"
#include <QAudioFormat>
#include <QDebug>

AudioLevelMonitor::AudioLevelMonitor(QObject *parent)
    : QObject(parent)
    , m_audioSource(nullptr)
    , m_audioDevice(nullptr)
    , m_timer(new QTimer(this))
    , m_audioLevel(0.0)
    , m_decibelLevel(-60.0)
    , m_isActive(false)
    , m_hasPermission(false)
    , m_shouldTurnOffCandle(false)
    , m_hasTriggeredCandle(false)
{
    qDebug() << "AudioLevelMonitor constructor called";

    // Setup timer for processing audio data
    m_timer->setInterval(50);
    connect(m_timer, &QTimer::timeout, this, &AudioLevelMonitor::processAudioData);

    // Delay permission request until after QML is fully loaded and graphics context is stable
    QTimer::singleShot(1000, this, &AudioLevelMonitor::requestPermission);

    qDebug() << "AudioLevelMonitor constructor finished";
}

AudioLevelMonitor::~AudioLevelMonitor()
{
    qDebug() << "AudioLevelMonitor destructor called";
    stopMonitoring();
}

void AudioLevelMonitor::requestPermission()
{
    // Early return if not June 16th
    QDate currentDate = QDate::currentDate();
    if (currentDate.day() != 16 || currentDate.month() != 6) {
        qDebug() << "Not June 16th, returning early";
        return;
    }

    qDebug() << "requestPermission called";
#if QT_CONFIG(permissions)
    QMicrophonePermission microphonePermission;
    // Check current permission status
    switch (qApp->checkPermission(microphonePermission)) {
    case Qt::PermissionStatus::Undetermined:
        qDebug() << "Permission undetermined, requesting...";
        // Request permission - this callback approach matches Qt documentation
        qApp->requestPermission(microphonePermission, this, [this](const QPermission &permission) {
            qDebug() << "Permission callback received, status:" << (int)permission.status();
            if (permission.status() == Qt::PermissionStatus::Granted) {
                m_hasPermission = true;
                qDebug() << "Microphone permission granted!";
                emit hasPermissionChanged();
                // Small delay to ensure graphics context is stable after permission dialog
                QTimer::singleShot(200, this, [this]() {
                    createAudioSource();
                    startMonitoring();
                });
            } else {
                m_hasPermission = false;
                qDebug() << "Microphone permission denied!";
                emit hasPermissionChanged();
            }
        });
        return;
    case Qt::PermissionStatus::Denied:
        qDebug() << "Permission denied";
        m_hasPermission = false;
        emit hasPermissionChanged();
        return;
    case Qt::PermissionStatus::Granted:
        qDebug() << "Permission already granted";
        m_hasPermission = true;
        emit hasPermissionChanged();
        createAudioSource();
        startMonitoring();
        break;
    }
#else
    qDebug() << "Permissions not supported on this platform";
    m_hasPermission = true;
    emit hasPermissionChanged();
    createAudioSource();
    startMonitoring();
#endif
}

void AudioLevelMonitor::createAudioSource()
{
    qDebug() << "createAudioSource called";

    if (m_audioSource) {
        qDebug() << "Audio source already exists";
        return;
    }

    // Setup audio format
    QAudioFormat format;
    format.setSampleRate(44100);
    format.setChannelCount(1);
    format.setSampleFormat(QAudioFormat::Int16);

    qDebug() << "Audio format configured";

    // Get default audio input device
    QAudioDevice audioDevice = QMediaDevices::defaultAudioInput();

    if (audioDevice.isNull()) {
        qDebug() << "No audio input device found!";
        return;
    }

    qDebug() << "Creating audio source with device:" << audioDevice.description();

    // Create audio source
    m_audioSource = new QAudioSource(audioDevice, format, this);

    qDebug() << "Audio source created successfully";
}

void AudioLevelMonitor::startMonitoring()
{
    qDebug() << "startMonitoring called - hasPermission:" << m_hasPermission << "isActive:" << m_isActive;

    if (!m_hasPermission) {
        qDebug() << "No permission, cannot start monitoring";
        return;
    }

    if (!m_audioSource) {
        qDebug() << "No audio source, creating...";
        createAudioSource();
    }

    if (!m_isActive && m_audioSource) {
        qDebug() << "Starting audio source...";
        m_audioDevice = m_audioSource->start();
        if (m_audioDevice) {
            qDebug() << "Audio source started, starting timer";
            m_timer->start();
            m_isActive = true;
            emit isActiveChanged();
        } else {
            qDebug() << "Failed to start audio source!";
        }
    }
}

void AudioLevelMonitor::stopMonitoring()
{
    qDebug() << "stopMonitoring called";
    if (m_isActive) {
        m_timer->stop();
        if (m_audioSource) {
            m_audioSource->stop();
        }
        m_audioDevice = nullptr;
        m_isActive = false;
        m_audioLevel = 0.0;
        m_decibelLevel = -60.0;
        m_shouldTurnOffCandle = false;
        m_hasTriggeredCandle = false; // Add this line
        emit isActiveChanged();
        emit audioLevelChanged();
        emit shouldTurnOffCandleChanged();
    }
}

void AudioLevelMonitor::checkPermission()
{
    // This method can be used to manually check permission status
    requestPermission();
}

void AudioLevelMonitor::processAudioData()
{
    if (!m_audioDevice) return;

    QByteArray audioData = m_audioDevice->readAll();
    if (audioData.isEmpty()) return;

    // Calculate RMS level from audio data
    const qint16* samples = reinterpret_cast<const qint16*>(audioData.constData());
    int sampleCount = audioData.size() / sizeof(qint16);

    if (sampleCount == 0) return;

    qreal sum = 0.0;
    for (int i = 0; i < sampleCount; ++i) {
        qreal sample = samples[i] / 32768.0;
        sum += sample * sample;
    }

    qreal rms = qSqrt(sum / sampleCount);
    m_audioLevel = rms;

    if (rms > 0.0) {
        m_decibelLevel = 20.0 * qLn(rms) / qLn(10.0);
        m_decibelLevel = qMax(-60.0, qMin(0.0, m_decibelLevel));
    } else {
        m_decibelLevel = -60.0;
    }

    // Trigger candle blow out once when -7 dB is reached
    if (m_decibelLevel >= -7.0 && !m_hasTriggeredCandle) {
        m_shouldTurnOffCandle = true;
        m_hasTriggeredCandle = true;
        emit shouldTurnOffCandleChanged();
    }
    // Reset trigger when audio level drops significantly (e.g., below -20 dB)
    else if (m_decibelLevel < -20.0 && m_hasTriggeredCandle) {
        m_hasTriggeredCandle = false;
    }

    emit audioLevelChanged();
}
