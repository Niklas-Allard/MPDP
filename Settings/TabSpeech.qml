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
            Label {
                id: ttHost1
                HoverHandler { id: ttHost1Hover }
                text: "Sprachausgabe aktiv"
                Layout.preferredWidth: 220
                ToolTip {
                    visible: ttHost1Hover.hovered
                    delay: 500
                    text: "Aktiviert oder deaktiviert das automatische Vorlesen\nvon Datei- und Ordnernamen beim Navigieren im Dateibrowser.\nAlle anderen Sprachausgabe-Einstellungen sind nur wirksam wenn diese Option aktiv ist."
                }
            }
            Switch {
                checked: settingsManager.ttsEnabled
                onToggled: settingsManager.ttsEnabled = checked
            }
        }

        // ── Sprache ───────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Label {
                id: ttHost2
                HoverHandler { id: ttHost2Hover }
                text: "Sprache"
                Layout.preferredWidth: 220
                ToolTip {
                    visible: ttHost2Hover.hovered
                    delay: 500
                    text: "Sprache der Sprachausgabe.\nEs werden nur Windows-Sprachpakete angezeigt, die auf diesem Gerät installiert sind.\nWeitere Sprachen können über 'Weitere Stimmen installieren' hinzugefügt werden."
                }
            }
            ComboBox {
                id: langCombo
                Layout.fillWidth: true
                enabled: settingsManager.ttsEnabled

                property var localeList: []

                function refresh() {
                    var voices = root.getAllVoices()
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
            Label {
                id: ttHost3
                HoverHandler { id: ttHost3Hover }
                text: "Stimme"
                Layout.preferredWidth: 220
                ToolTip {
                    visible: ttHost3Hover.hovered
                    delay: 500
                    text: "Sprechstimme innerhalb der gewählten Sprache.\nVerschiedene Stimmen klingen unterschiedlich natürlich – einfach ausprobieren.\nNach der Auswahl kann 'Probehören' zum Vergleich genutzt werden."
                }
            }
            ComboBox {
                id: voiceCombo
                Layout.fillWidth: true
                enabled: settingsManager.ttsEnabled

                property var voiceList: []

                function refresh() {
                    if (langCombo.localeList.length === 0) return
                    var selectedLocale = langCombo.localeList[langCombo.currentIndex]
                    if (!selectedLocale) return

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

                    // Gespeicherte Stimme wiederherstellen, sonst erste nehmen
                    var idx = names.indexOf(settingsManager.ttsVoice)
                    currentIndex = idx >= 0 ? idx : 0

                    // ttsProbe auch ohne Nutzerinteraktion auf die aktuelle Auswahl setzen,
                    // sonst spricht "Probehören" nach dem Öffnen der Seite mit der System-Standardstimme.
                    if (currentIndex >= 0 && currentIndex < filtered.length) {
                        ttsProbe.locale = selectedLocale
                        ttsProbe.voice = filtered[currentIndex]
                    }
                }

                onActivated: {
                    if (currentIndex < 0 || currentIndex >= voiceList.length) return
                    settingsManager.ttsVoice = currentText
                    ttsProbe.locale = langCombo.localeList[langCombo.currentIndex]
                    ttsProbe.voice = voiceList[currentIndex]
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Label {
                id: ttHost4
                HoverHandler { id: ttHost4Hover }
                text: "Geschwindigkeit"
                Layout.preferredWidth: 220
                ToolTip {
                    visible: ttHost4Hover.hovered
                    delay: 500
                    text: "Sprechgeschwindigkeit der Stimme.\n0,0 = normale Geschwindigkeit\nNegative Werte = langsamer (bis −1,0 = sehr langsam)\nPositive Werte = schneller (bis +1,0 = sehr schnell)\nEmpfehlung für leichteres Verstehen: −0,2 bis −0,4."
                }
            }
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
            Label {
                id: ttHost5
                HoverHandler { id: ttHost5Hover }
                text: "Lautstärke"
                Layout.preferredWidth: 220
                ToolTip {
                    visible: ttHost5Hover.hovered
                    delay: 500
                    text: "Lautstärke der Sprachausgabe, unabhängig von der Medienwiedergabe.\n0 % = stumm · 100 % = maximale Lautstärke.\nDiese Einstellung beeinflusst nur das Vorlesen, nicht das abgespielte Video."
                }
            }
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
            Label {
                id: ttHost6
                HoverHandler { id: ttHost6Hover }
                text: "Pause bei \" - \""
                Layout.preferredWidth: 220
                ToolTip {
                    visible: ttHost6Hover.hovered
                    delay: 500
                    text: "Macht beim Vorlesen eine kurze Pause, wenn ein ' - ' im Namen vorkommt.\nBeispiel: 'Staffel 1 - Folge 3' wird mit Pause zwischen den Teilen gesprochen.\nVerbessert die Verständlichkeit bei zusammengesetzten Titeln."
                }
            }
            Switch {
                checked: settingsManager.ttsDashPauseEnabled
                onToggled: settingsManager.ttsDashPauseEnabled = checked
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Label {
                id: ttHost7
                HoverHandler { id: ttHost7Hover }
                text: "Pausendauer bei \" - \""
                Layout.preferredWidth: 220
                ToolTip {
                    visible: ttHost7Hover.hovered
                    delay: 500
                    text: "Dauer der Sprechpause an einem ' - '-Trenner in Millisekunden.\n100 ms = kaum wahrnehmbar · 500 ms = deutliche Pause · 2000 ms = lange Pause.\nNur wirksam wenn 'Pause bei \" - \"' aktiviert ist."
                }
            }
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
                id: ttHost8
                text: "Probehören"
                enabled: settingsManager.ttsEnabled
                onClicked: root.speakTest("Hallo - dies ist ein Test - der Sprachausgabe.")
                ToolTip {
                    visible: ttHost8.hovered
                    delay: 500
                    text: "Spricht einen Beispielsatz mit den aktuellen Einstellungen,\num Stimme, Geschwindigkeit und Lautstärke zu testen."
                }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
            }
            Button {
                id: ttHost9
                text: "Stimmen aktualisieren"
                onClicked: langCombo.refresh()
                ToolTip {
                    visible: ttHost9.hovered
                    delay: 500
                    text: "Lädt die Liste der verfügbaren Stimmen und Sprachen neu.\nNützlich nach dem Installieren neuer Sprachpakete."
                }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
            }
            Button {
                id: ttHost10
                text: "Weitere Stimmen installieren …"
                onClicked: Qt.openUrlExternally("ms-settings:speech")
                ToolTip {
                    visible: ttHost10.hovered
                    delay: 500
                    text: "Öffnet die Windows-Einstellungen zum Installieren weiterer Sprachpakete.\nNach der Installation 'Stimmen aktualisieren' klicken."
                }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Label {
                id: ttHost11
                HoverHandler { id: ttHost11Hover }
                text: "Verzögerung vor Sprechen"
                Layout.preferredWidth: 220
                ToolTip {
                    visible: ttHost11Hover.hovered
                    delay: 500
                    text: "Wartezeit nach dem Klick, bevor der Name vorgelesen wird.\n0 ms = sofort · 500 ms = halbe Sekunde Verzögerung.\nEmpfohlen: 200–400 ms, um versehentliches Vorlesen\nbeim schnellen Durchklicken zu vermeiden."
                }
            }
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
