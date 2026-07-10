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

    // availableVoices() liefert nur Stimmen der aktuell gesetzten Locale (Default: Systemsprache) –
    // hier werden die Stimmen aller installierten Sprachen eingesammelt.
    function getAllVoices() {
        var savedLocale = ttsProbe.locale
        var locales = ttsProbe.availableLocales()
        var all = []
        for (var i = 0; i < locales.length; i++) {
            ttsProbe.locale = locales[i]
            all = all.concat(ttsProbe.availableVoices())
        }
        ttsProbe.locale = savedLocale
        return all
    }

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
                    Label {
                        id: ttHost1
                        HoverHandler { id: ttHost1Hover }
                        text: "Wort"
                        Layout.preferredWidth: 120
                        ToolTip {
                            visible: ttHost1Hover.hovered
                            delay: 500
                            text: "Das Wort, das beim Vorlesen in einer anderen Stimme gesprochen werden soll.\nNur exakte Wortübereinstimmung (Groß-/Kleinschreibung egal)."
                        }
                    }
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
                            var voices = root.getAllVoices()
                            if (voices.length === 0) return

                            // Aktuell gewählte Sprache merken, damit ein erneuter refresh()
                            // (z. B. nach dem Probehören) die Auswahl nicht zurücksetzt.
                            var prevLocaleName = (localeList.length > 0 && currentIndex >= 0 &&
                                    currentIndex < localeList.length) ? localeList[currentIndex].name : ""

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
                            model = names

                            var restoredIndex = -1
                            for (var ri = 0; ri < locales.length; ri++) {
                                if (locales[ri].name === prevLocaleName) { restoredIndex = ri; break }
                            }

                            if (restoredIndex >= 0) {
                                currentIndex = restoredIndex
                            } else {
                                // Vorauswahl: erste Sprache, die nicht der Standardsprache entspricht
                                var defVoice = settingsManager.ttsVoice
                                var defLocale = ""
                                for (var v = 0; v < voices.length; v++) {
                                    if (voices[v].name === defVoice) {
                                        defLocale = voices[v].locale.name
                                        break
                                    }
                                }
                                currentIndex = 0
                                for (var li = 0; li < locales.length; li++) {
                                    if (locales[li].name !== defLocale) { currentIndex = li; break }
                                }
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

                            // Aktuell gewählte Stimme merken, damit ein erneuter refresh()
                            // (z. B. nach dem Probehören) die Auswahl nicht zurücksetzt.
                            var prevVoiceName = (currentIndex >= 0 && currentIndex < voiceList.length)
                                    ? voiceList[currentIndex].name : ""

                            var voices = root.getAllVoices()
                            var filtered = []
                            for (var i = 0; i < voices.length; i++) {
                                if (voices[i].locale.name === selectedLocale.name)
                                    filtered.push(voices[i])
                            }
                            voiceList = filtered

                            var names = []
                            for (var j = 0; j < filtered.length; j++) names.push(filtered[j].name)
                            model = names

                            var idx = names.indexOf(prevVoiceName)
                            currentIndex = idx >= 0 ? idx : 0
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Button {
                        id: ttHost2
                        text: "Hinzufügen"
                        enabled: wordField.text.trim().length > 0 && altVoiceCombo.count > 0
                        onClicked: {
                            settingsManager.addWordPronunciation(
                                wordField.text.trim(), altVoiceCombo.currentText)
                            wordField.text = ""
                        }
                        ToolTip {
                            visible: ttHost2.hovered
                            delay: 500
                            text: "Fügt das eingegebene Wort mit der gewählten Stimme zur Liste hinzu.\nBeim Vorlesen wird dieses Wort künftig mit der alternativen Stimme gesprochen."
                        }
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                    }
                    Button {
                        id: ttHost3
                        text: "Probehören"
                        enabled: wordField.text.trim().length > 0 && altVoiceCombo.count > 0
                        onClicked: {
                            if (altVoiceCombo.currentIndex >= 0 &&
                                    altVoiceCombo.currentIndex < altVoiceCombo.voiceList.length) {
                                ttsProbe.voice = altVoiceCombo.voiceList[altVoiceCombo.currentIndex]
                            }
                            ttsProbe.say(wordField.text.trim())
                        }
                        ToolTip {
                            visible: ttHost3.hovered
                            delay: 500
                            text: "Spricht das eingegebene Wort mit der gewählten Stimme vor,\nohne es zur Liste hinzuzufügen. Zum Testen vor dem Speichern."
                        }
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                    }
                    Button {
                        id: ttHost4
                        text: "Stimmen aktualisieren"
                        onClicked: altLangCombo.refresh()
                        ToolTip {
                            visible: ttHost4.hovered
                            delay: 500
                            text: "Lädt die Liste verfügbarer Stimmen neu.\nNützlich nach dem Installieren neuer Windows-Sprachpakete."
                        }
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                    }
                    Button {
                        id: ttHost5
                        text: "Weitere Stimmen installieren …"
                        onClicked: Qt.openUrlExternally("ms-settings:speech")
                        ToolTip {
                            visible: ttHost5.hovered
                            delay: 500
                            text: "Öffnet die Windows-Spracheinstellungen zum Installieren\nweiterer Sprachpakete und Stimmen."
                        }
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
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
                                var voices = root.getAllVoices()
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
