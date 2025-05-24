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
        winFX.audioOutput.device = device
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
        id: winFX
        source: "qrc:/sounds/tada.wav"
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

    function playWin() {
        winFX.play()
    }

    function playMove() {
        moveFX.play()
    }

    function playSilent() {
        silentKeepAlive.play()
    }
}
