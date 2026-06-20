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
        engine: "winrt"
        volume: settingsManager.ttsVolume
        rate: settingsManager.ttsRate
        onStateChanged: {
            if (state === TextToSpeech.Ready) {
                langCombo.refresh()
            }
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

    Component.onCompleted: langCombo.refresh()

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

        // ── Sprache ───────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Label { text: "Sprache"; Layout.preferredWidth: 220 }
            ComboBox {
                id: langCombo
                Layout.fillWidth: true
                enabled: settingsManager.ttsEnabled

                property var localeList: []

                function refresh() {
                    var voices = ttsProbe.availableVoices()
                    if (voices.length === 0) return

                    // Eindeutige Locales aus den verfügbaren Stimmen ableiten
                    var seen = {}
                    var locales = []
                    for (var i = 0; i < voices.length; i++) {
                        var lname = voices[i].locale.name
                        if (!seen[lname]) {
                            seen[lname] = true
                            locales.push(voices[i].locale)
                        }
                    }
                    localeList = locales

                    var names = []
                    for (var j = 0; j < locales.length; j++) {
                        var l = locales[j]
                        var display = l.nativeLanguageName
                        if (l.nativeTerritoryName && l.nativeTerritoryName !== l.nativeLanguageName)
                            display += " (" + l.nativeTerritoryName + ")"
                        names.push(display)
                    }
                    var prevIndex = currentIndex
                    model = names

                    // Sprache der gespeicherten Stimme vorauswählen
                    var savedVoice = settingsManager.ttsVoice
                    for (var v = 0; v < voices.length; v++) {
                        if (voices[v].name === savedVoice) {
                            for (var li = 0; li < locales.length; li++) {
                                if (locales[li].name === voices[v].locale.name) {
                                    currentIndex = li
                                    break
                                }
                            }
                            break
                        }
                    }
                    voiceCombo.refresh()
                }

                onActivated: voiceCombo.refresh()
            }
        }

        // ── Stimme ────────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Label { text: "Stimme"; Layout.preferredWidth: 220 }
            ComboBox {
                id: voiceCombo
                Layout.fillWidth: true
                enabled: settingsManager.ttsEnabled

                property var voiceList: []

                function refresh() {
                    if (langCombo.localeList.length === 0) return
                    var selectedLocale = langCombo.localeList[langCombo.currentIndex]
                    if (!selectedLocale) return

                    var voices = ttsProbe.availableVoices()
                    var filtered = []
                    for (var i = 0; i < voices.length; i++) {
                        if (voices[i].locale.name === selectedLocale.name)
                            filtered.push(voices[i])
                    }
                    voiceList = filtered

                    var names = []
                    for (var j = 0; j < filtered.length; j++) names.push(filtered[j].name)
                    model = names

                    // Gespeicherte Stimme wiederherstellen, sonst erste nehmen
                    var idx = names.indexOf(settingsManager.ttsVoice)
                    currentIndex = idx >= 0 ? idx : 0
                }

                onActivated: {
                    if (currentIndex < 0 || currentIndex >= voiceList.length) return
                    settingsManager.ttsVoice = currentText
                    ttsProbe.voice = voiceList[currentIndex]
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
            Button {
                text: "Stimmen aktualisieren"
                onClicked: langCombo.refresh()
            }
            Button {
                text: "Weitere Stimmen installieren …"
                onClicked: Qt.openUrlExternally("ms-settings:speech")
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
