import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtTextToSpeech

ScrollView {
    id: root
    clip: true
    contentWidth: availableWidth

    TextToSpeech {
        id: ttsProbe
        volume: settingsManager.ttsVolume
        rate: settingsManager.ttsRate
        onStateChanged: {
            if ((state === TextToSpeech.Ready || state === TextToSpeech.Error)
                    && root._ttsQueue.length > 0) {
                ttsPauseTimer.start()
            }
        }
    }

    property var _ttsQueue: []

    Timer {
        id: ttsPauseTimer
        interval: settingsManager.ttsDashPauseDuration
        repeat: false
        onTriggered: {
            if (root._ttsQueue.length > 0) {
                ttsProbe.say(root._ttsQueue.shift())
            }
        }
    }

    function speakTest(text) {
        ttsProbe.stop()
        root._ttsQueue = []
        if (settingsManager.ttsDashPauseEnabled && text.indexOf(" - ") >= 0) {
            var parts = text.split(" - ").filter(function(s) { return s.trim().length > 0 })
            root._ttsQueue = parts
            if (root._ttsQueue.length > 0) ttsProbe.say(root._ttsQueue.shift())
        } else {
            ttsProbe.say(text)
        }
    }

    ColumnLayout {
        width: parent.availableWidth
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            Label { text: "Sprachausgabe aktiv"; Layout.preferredWidth: 220 }
            Switch {
                checked: settingsManager.ttsEnabled
                onToggled: settingsManager.ttsEnabled = checked
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Label { text: "Stimme"; Layout.preferredWidth: 220 }
            ComboBox {
                id: voiceCombo
                Layout.fillWidth: true
                enabled: settingsManager.ttsEnabled
                model: {
                    var voices = ttsProbe.availableVoices()
                    var names = []
                    for (var i = 0; i < voices.length; i++) names.push(voices[i].name)
                    return names
                }
                Component.onCompleted: {
                    var idx = model.indexOf(settingsManager.ttsVoice)
                    if (idx >= 0) currentIndex = idx
                }
                onActivated: {
                    settingsManager.ttsVoice = currentText
                    var voices = ttsProbe.availableVoices()
                    for (var i = 0; i < voices.length; i++) {
                        if (voices[i].name === currentText) {
                            ttsProbe.voice = voices[i]
                            break
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Label { text: "Geschwindigkeit"; Layout.preferredWidth: 220 }
            Slider {
                id: rateSlider
                Layout.fillWidth: true
                enabled: settingsManager.ttsEnabled
                from: -1.0; to: 1.0; stepSize: 0.1
                value: settingsManager.ttsRate
                onMoved: settingsManager.ttsRate = value
            }
            Label { text: rateSlider.value.toFixed(1); Layout.preferredWidth: 50 }
        }

        RowLayout {
            Layout.fillWidth: true
            Label { text: "Lautstärke"; Layout.preferredWidth: 220 }
            Slider {
                id: ttsVolSlider
                Layout.fillWidth: true
                enabled: settingsManager.ttsEnabled
                from: 0.0; to: 1.0; stepSize: 0.05
                value: settingsManager.ttsVolume
                onMoved: settingsManager.ttsVolume = value
            }
            Label { text: Math.round(ttsVolSlider.value * 100) + " %"; Layout.preferredWidth: 50 }
        }

        RowLayout {
            Layout.fillWidth: true
            Label { text: "Pause bei \" - \""; Layout.preferredWidth: 220 }
            Switch {
                checked: settingsManager.ttsDashPauseEnabled
                onToggled: settingsManager.ttsDashPauseEnabled = checked
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Label { text: "Pausendauer bei \" - \""; Layout.preferredWidth: 220 }
            Slider {
                id: dashPauseSlider
                Layout.fillWidth: true
                enabled: settingsManager.ttsDashPauseEnabled && settingsManager.ttsEnabled
                from: 100; to: 2000; stepSize: 50
                value: settingsManager.ttsDashPauseDuration
                onMoved: settingsManager.ttsDashPauseDuration = value
            }
            Label { text: Math.round(dashPauseSlider.value) + " ms"; Layout.preferredWidth: 70 }
        }

        RowLayout {
            Layout.fillWidth: true
            Label { text: ""; Layout.preferredWidth: 220 }
            Button {
                text: "Probehören"
                enabled: settingsManager.ttsEnabled
                onClicked: root.speakTest("Hallo - dies ist ein Test - der Sprachausgabe.")
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Label { text: "Verzögerung vor Sprechen"; Layout.preferredWidth: 220 }
            Slider {
                id: clickDelaySlider
                Layout.fillWidth: true
                from: 0; to: 2000; stepSize: 50
                value: settingsManager.clickSpeakDelay
                onMoved: settingsManager.clickSpeakDelay = value
            }
            Label { text: Math.round(clickDelaySlider.value) + " ms"; Layout.preferredWidth: 70 }
        }

        Item { Layout.fillHeight: true }
    }
}
