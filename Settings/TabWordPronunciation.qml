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
                altLangCombo.refresh()
            }
        }
    }

    property var entries: []

    function loadEntries() {
        try {
            root.entries = JSON.parse(settingsManager.wordPronunciations || "[]")
        } catch (e) {
            root.entries = []
        }
    }

    Component.onCompleted: {
        root.loadEntries()
        altLangCombo.refresh()
    }

    Connections {
        target: settingsManager
        function onWordPronunciationsChanged() { root.loadEntries() }
    }

    ColumnLayout {
        width: parent.availableWidth
        spacing: 12

        Label {
            text: "Bestimmte Wörter in einer anderen Stimme aussprechen"
            font.bold: true
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        Label {
            text: "Wenn ein Wort unten eingetragen ist, wird es beim Vorlesen mit der " +
                  "gewählten Stimme gesprochen. Der Rest bleibt in der Standard-Stimme."
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        Label {
            text: "Tipp: Weitere Sprachen erscheinen hier erst, nachdem du sie unter " +
                  "Windows-Einstellungen → Zeit & Sprache → Sprache → Sprachpakete installierst. " +
                  "Nutze den Button \„Weitere Stimmen installieren\" unten."
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            opacity: 0.6
            font.italic: true
        }

        // ── Eingabe für neuen Eintrag ──────────────────────────────────────────
        GroupBox {
            title: "Neues Wort hinzufügen"
            Layout.fillWidth: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "Wort"; Layout.preferredWidth: 120 }
                    TextField {
                        id: wordField
                        Layout.fillWidth: true
                        placeholderText: "z. B. Hello"
                    }
                }

                // ── Sprache ───────────────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "Sprache"; Layout.preferredWidth: 120 }
                    ComboBox {
                        id: altLangCombo
                        Layout.fillWidth: true

                        property var localeList: []

                        function refresh() {
                            var voices = ttsProbe.availableVoices()
                            if (voices.length === 0) return

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
                            var prev = currentIndex
                            model = names

                            // Vorauswahl: erste Sprache, die nicht der Standardsprache entspricht
                            var defVoice = settingsManager.ttsVoice
                            var defLocale = ""
                            var allVoices = ttsProbe.availableVoices()
                            for (var v = 0; v < allVoices.length; v++) {
                                if (allVoices[v].name === defVoice) {
                                    defLocale = allVoices[v].locale.name
                                    break
                                }
                            }
                            currentIndex = 0
                            for (var li = 0; li < locales.length; li++) {
                                if (locales[li].name !== defLocale) { currentIndex = li; break }
                            }
                            altVoiceCombo.refresh()
                        }

                        onActivated: altVoiceCombo.refresh()
                    }
                }

                // ── Stimme ────────────────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "Stimme"; Layout.preferredWidth: 120 }
                    ComboBox {
                        id: altVoiceCombo
                        Layout.fillWidth: true

                        property var voiceList: []

                        function refresh() {
                            if (altLangCombo.localeList.length === 0) return
                            var selectedLocale = altLangCombo.localeList[altLangCombo.currentIndex]
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
                            currentIndex = 0
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Button {
                        text: "Hinzufügen"
                        enabled: wordField.text.trim().length > 0 && altVoiceCombo.count > 0
                        onClicked: {
                            settingsManager.addWordPronunciation(
                                wordField.text.trim(), altVoiceCombo.currentText)
                            wordField.text = ""
                        }
                    }
                    Button {
                        text: "Probehören"
                        enabled: wordField.text.trim().length > 0 && altVoiceCombo.count > 0
                        onClicked: {
                            if (altVoiceCombo.currentIndex >= 0 &&
                                    altVoiceCombo.currentIndex < altVoiceCombo.voiceList.length) {
                                ttsProbe.voice = altVoiceCombo.voiceList[altVoiceCombo.currentIndex]
                            }
                            ttsProbe.say(wordField.text.trim())
                        }
                    }
                    Button {
                        text: "Stimmen aktualisieren"
                        onClicked: altLangCombo.refresh()
                    }
                    Button {
                        text: "Weitere Stimmen installieren …"
                        onClicked: Qt.openUrlExternally("ms-settings:speech")
                    }
                }
            }
        }

        // ── Eintrags-Liste ────────────────────────────────────────────────────
        GroupBox {
            title: "Eingetragene Wörter"
            Layout.fillWidth: true
            visible: root.entries.length > 0

            ColumnLayout {
                anchors.fill: parent
                spacing: 4

                Repeater {
                    model: root.entries

                    delegate: RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Label {
                            text: modelData.word
                            font.bold: true
                            Layout.preferredWidth: 160
                            elide: Text.ElideRight
                        }
                        Label {
                            text: modelData.voice
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            opacity: 0.7
                        }
                        Button {
                            text: "Test"
                            onClicked: {
                                var voices = ttsProbe.availableVoices()
                                for (var i = 0; i < voices.length; i++) {
                                    if (voices[i].name === modelData.voice) {
                                        ttsProbe.voice = voices[i]
                                        break
                                    }
                                }
                                ttsProbe.say(modelData.word)
                            }
                        }
                        Button {
                            text: "Entfernen"
                            onClicked: settingsManager.removeWordPronunciation(modelData.word)
                        }
                    }
                }
            }
        }

        Label {
            text: "Keine Wörter eingetragen."
            visible: root.entries.length === 0
            opacity: 0.6
        }

        Item { Layout.fillHeight: true }
    }
}
