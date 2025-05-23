pragma Singleton

import QtQuick
import QtMultimedia
import Odizinne.Checkers

Item {
    property string currentAudioDevice: ""
    property var currentAudioOutput: null

    Component.onCompleted: {
        updateAudioDevice()
    }

    MediaDevices {
        id: mediaDevices
        onAudioOutputsChanged: {
            AudioEngine.updateAudioDevice()
        }
    }

    function updateAudioDevice() {
        const device = mediaDevices.defaultAudioOutput

        if (device.id !== (currentAudioOutput ? currentAudioOutput.id : "")) {
            currentAudioDevice = device.description
            currentAudioOutput = device

            applyAudioDeviceToAllPlayers(device)
        }
    }

    function applyAudioDeviceToAllPlayers(device) {
        moveFX.audioOutput.device = device
        captureFX.audioOutput.device = device
        silentKeepAlive.audioOutput.device = device

        silentKeepAlive.stop()
        silentKeepAlive.play()
    }

    MediaPlayer {
        id: moveFX
        source: "qrc:/sounds/move.wav"
        audioOutput: AudioOutput {
            volume: UserSettings.volume
            device: mediaDevices.defaultAudioOutput
        }
    }

    MediaPlayer {
        id: captureFX
        source: "qrc:/sounds/capture.wav"
        audioOutput: AudioOutput {
            volume: UserSettings.volume
            device: mediaDevices.defaultAudioOutput
        }
    }

    MediaPlayer {
        id: silentKeepAlive
        source: "qrc:/sounds/empty.wav"
        audioOutput: AudioOutput {
            id: silentAudio
            volume: 0.01
            device: mediaDevices.defaultAudioOutput
        }
        loops: MediaPlayer.Infinite
    }

    function playCapture() {
        captureFX.play()
    }

    function playMove() {
        moveFX.play()
    }

    function playSilent() {
        silentKeepAlive.play()
    }
}
