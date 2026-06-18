import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs
import QtTextToSpeech

Item {
    id: settingsPage
    objectName: "settingsPage"

    property var mainDirsModel: []
    property var regexRulesModel: []

    // TTS-Probe-Instanz, um verfügbare Stimmen aufzulisten und Einstellungen zu testen
    TextToSpeech {
        id: ttsProbe
        volume: settingsManager.ttsVolume
        rate: settingsManager.ttsRate
        onStateChanged: {
            if ((state === TextToSpeech.Ready || state === TextToSpeech.Error)
                    && settingsPage._ttsQueue.length > 0) {
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
            if (settingsPage._ttsQueue.length > 0) {
                ttsProbe.say(settingsPage._ttsQueue.shift())
            }
        }
    }

    function _speakTest(text) {
        ttsProbe.stop()
        settingsPage._ttsQueue = []
        if (settingsManager.ttsDashPauseEnabled && text.indexOf(" - ") >= 0) {
            var parts = text.split(" - ").filter(function(s) { return s.trim().length > 0 })
            settingsPage._ttsQueue = parts
            if (settingsPage._ttsQueue.length > 0) ttsProbe.say(settingsPage._ttsQueue.shift())
        } else {
            ttsProbe.say(text)
        }
    }

    function reloadFromSettings() {
        mainDirsModel = settingsManager.get_main_directories()
        imageDirField.text = settingsManager.get_global_image_directory()
        regexRulesModel = regexFilter.get_rules()
    }

    Component.onCompleted: reloadFromSettings()

    Connections {
        target: settingsManager
        function onMain_directories_changed() { reloadFromSettings() }
        function onGlobal_image_directory_changed() { reloadFromSettings() }
        // ComboBoxen folgen nicht automatisch (currentIndex ist kein Binding) –
        // daher nach Theme-/Sortierungswechsel bzw. Reset explizit nachziehen.
        function onThemeChanged() { themeCombo.currentIndex = themeCombo.indexOfValue(settingsManager.theme) }
        function onSortOrderChanged() { sortCombo.currentIndex = sortCombo.indexOfValue(settingsManager.sortOrder) }
        function onSpeakTriggerChanged() { speakTriggerCombo.currentIndex = speakTriggerCombo.indexOfValue(settingsManager.speakTrigger) }
        function onOpenTriggerChanged() { openTriggerCombo.currentIndex = openTriggerCombo.indexOfValue(settingsManager.openTrigger) }
    }

    Text {
        id: headerText
        text: "Einstellungen"
        font.pixelSize: 24 * settingsManager.fontScale
        font.bold: true
        color: settingsManager.colorText
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 16
    }

    ScrollView {
        id: scroll
        anchors.top: headerText.bottom
        anchors.bottom: footer.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 16
        clip: true

        ColumnLayout {
            width: scroll.availableWidth
            spacing: 20

            // ============================================================
            // Darstellung & Barrierefreiheit
            // ============================================================
            GroupBox {
                Layout.fillWidth: true
                title: "Darstellung & Barrierefreiheit"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 12

                    // Karten-Mindestbreite
                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: "Karten-Mindestbreite"; Layout.preferredWidth: 220 }
                        Slider {
                            id: cardWidthSlider
                            Layout.fillWidth: true
                            from: 100; to: 400; stepSize: 10
                            value: settingsManager.cardMinWidth
                            onMoved: settingsManager.cardMinWidth = value
                        }
                        Label { text: Math.round(cardWidthSlider.value) + " px"; Layout.preferredWidth: 70 }
                    }

                    // Karten-Mindesthöhe
                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: "Karten-Mindesthöhe"; Layout.preferredWidth: 220 }
                        Slider {
                            id: cardHeightSlider
                            Layout.fillWidth: true
                            from: 100; to: 400; stepSize: 10
                            value: settingsManager.cardMinHeight
                            onMoved: settingsManager.cardMinHeight = value
                        }
                        Label { text: Math.round(cardHeightSlider.value) + " px"; Layout.preferredWidth: 70 }
                    }

                    // Schriftgrößen-Skalierung
                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: "Schriftgröße"; Layout.preferredWidth: 220 }
                        Slider {
                            id: fontScaleSlider
                            Layout.fillWidth: true
                            from: 0.8; to: 2.0; stepSize: 0.1
                            value: settingsManager.fontScale
                            onMoved: settingsManager.fontScale = value
                        }
                        Label { text: fontScaleSlider.value.toFixed(1) + "×"; Layout.preferredWidth: 70 }
                    }

                    // Theme
                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: "Farbschema"; Layout.preferredWidth: 220 }
                        ComboBox {
                            id: themeCombo
                            Layout.fillWidth: true
                            textRole: "label"
                            valueRole: "value"
                            model: [
                                { label: "Hell",          value: "light" },
                                { label: "Dunkel",        value: "dark" },
                                { label: "Hoher Kontrast", value: "highContrast" }
                            ]
                            Component.onCompleted: currentIndex = indexOfValue(settingsManager.theme)
                            onActivated: settingsManager.theme = currentValue
                        }
                    }
                }
            }

            // ============================================================
            // Sprachausgabe
            // ============================================================
            GroupBox {
                Layout.fillWidth: true
                title: "Sprachausgabe"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: "Sprachausgabe aktiv"; Layout.preferredWidth: 220 }
                        Switch {
                            checked: settingsManager.ttsEnabled
                            onToggled: settingsManager.ttsEnabled = checked
                        }
                    }

                    // Stimme
                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: "Stimme"; Layout.preferredWidth: 220 }
                        ComboBox {
                            id: voiceCombo
                            Layout.fillWidth: true
                            enabled: settingsManager.ttsEnabled
                            // Stimmen-Liste dynamisch aus dem TTS-Engine
                            model: {
                                var voices = ttsProbe.availableVoices()
                                var names = []
                                for (var i = 0; i < voices.length; i++) {
                                    names.push(voices[i].name)
                                }
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

                    // Geschwindigkeit
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

                    // Lautstärke
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

                    // Pause bei " - "
                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: "Pause bei \" - \""; Layout.preferredWidth: 220 }
                        Switch {
                            checked: settingsManager.ttsDashPauseEnabled
                            onToggled: settingsManager.ttsDashPauseEnabled = checked
                        }
                    }

                    // Pausendauer bei " - "
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

                    // Test-Button
                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: ""; Layout.preferredWidth: 220 }
                        Button {
                            text: "Probehören"
                            enabled: settingsManager.ttsEnabled
                            onClicked: settingsPage._speakTest("Hallo - dies ist ein Test - der Sprachausgabe.")
                        }
                    }

                    // Klick-Verzögerung
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
                }
            }

            // ============================================================
            // Navigation & Interaktion
            // ============================================================
            GroupBox {
                Layout.fillWidth: true
                title: "Navigation & Interaktion"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: "Vorlesen auslösen mit"; Layout.preferredWidth: 220 }
                        ComboBox {
                            id: speakTriggerCombo
                            Layout.fillWidth: true
                            textRole: "label"
                            valueRole: "value"
                            model: [
                                { label: "Hover",        value: "hover" },
                                { label: "Einfachklick", value: "singleClick" },
                                { label: "Doppelklick",  value: "doubleClick" }
                            ]
                            Component.onCompleted: currentIndex = indexOfValue(settingsManager.speakTrigger)
                            onActivated: settingsManager.speakTrigger = currentValue
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: "Öffnen/Navigieren mit"; Layout.preferredWidth: 220 }
                        ComboBox {
                            id: openTriggerCombo
                            Layout.fillWidth: true
                            textRole: "label"
                            valueRole: "value"
                            model: [
                                { label: "Hover",        value: "hover" },
                                { label: "Einfachklick", value: "singleClick" },
                                { label: "Doppelklick",  value: "doubleClick" }
                            ]
                            Component.onCompleted: currentIndex = indexOfValue(settingsManager.openTrigger)
                            onActivated: settingsManager.openTrigger = currentValue
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: "Hover-Verzögerung"; Layout.preferredWidth: 220 }
                        Slider {
                            id: hoverDelaySlider
                            Layout.fillWidth: true
                            enabled: settingsManager.speakTrigger === "hover" || settingsManager.openTrigger === "hover"
                            from: 200; to: 10000; stepSize: 100
                            value: settingsManager.hoverDelay
                            onMoved: settingsManager.hoverDelay = value
                        }
                        Label {
                            text: (hoverDelaySlider.value / 1000).toFixed(1) + " s"
                            Layout.preferredWidth: 70
                            opacity: hoverDelaySlider.enabled ? 1.0 : 0.5
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: "Versteckte Dateien zeigen"; Layout.preferredWidth: 220 }
                        Switch {
                            checked: settingsManager.showHiddenFiles
                            onToggled: settingsManager.showHiddenFiles = checked
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: "Deaktivierte Blättern-Buttons ausblenden"; Layout.preferredWidth: 220 }
                        Switch {
                            checked: settingsManager.hideDisabledNavButtons
                            onToggled: settingsManager.hideDisabledNavButtons = checked
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: "Sortierung"; Layout.preferredWidth: 220 }
                        ComboBox {
                            id: sortCombo
                            Layout.fillWidth: true
                            textRole: "label"
                            valueRole: "value"
                            model: [
                                { label: "Name (A → Z)", value: "name_asc"  },
                                { label: "Name (Z → A)", value: "name_desc" },
                                { label: "Datum (neu zuerst)", value: "date_desc" },
                                { label: "Größe (groß zuerst)", value: "size_desc" }
                            ]
                            Component.onCompleted: currentIndex = indexOfValue(settingsManager.sortOrder)
                            onActivated: settingsManager.sortOrder = currentValue
                        }
                    }
                }
            }

            // ============================================================
            // Medienwiedergabe
            // ============================================================
            GroupBox {
                Layout.fillWidth: true
                title: "Medienwiedergabe"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: "Standardlautstärke"; Layout.preferredWidth: 220 }
                        Slider {
                            id: defVolSlider
                            Layout.fillWidth: true
                            from: 0.0; to: 1.0; stepSize: 0.05
                            value: settingsManager.defaultVolume
                            onMoved: settingsManager.defaultVolume = value
                        }
                        Label { text: Math.round(defVolSlider.value * 100) + " %"; Layout.preferredWidth: 50 }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: "Wiedergabe fortsetzen"; Layout.preferredWidth: 220 }
                        Switch {
                            checked: settingsManager.resumePlayback
                            onToggled: settingsManager.resumePlayback = checked
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: "Cursor ausblenden nach"; Layout.preferredWidth: 220 }
                        Slider {
                            id: cursorSlider
                            Layout.fillWidth: true
                            from: 1000; to: 30000; stepSize: 500
                            value: settingsManager.cursorHideTimeout
                            onMoved: settingsManager.cursorHideTimeout = value
                        }
                        Label { text: (cursorSlider.value / 1000).toFixed(1) + " s"; Layout.preferredWidth: 70 }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: "Video sofort abspielen"; Layout.preferredWidth: 220 }
                        Switch {
                            checked: settingsManager.autoPlayOnOpen
                            onToggled: settingsManager.autoPlayOnOpen = checked
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: "Nächste Datei automatisch"; Layout.preferredWidth: 220 }
                        Switch {
                            checked: settingsManager.autoPlayNext
                            onToggled: settingsManager.autoPlayNext = checked
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: "Nächste Folge ansagen"; Layout.preferredWidth: 220 }
                        Switch {
                            enabled: settingsManager.autoPlayNext && settingsManager.ttsEnabled
                            checked: settingsManager.announceNextFile
                            onToggled: settingsManager.announceNextFile = checked
                        }
                    }
                }
            }

            // ============================================================
            // Globales Bilderverzeichnis
            // ============================================================
            GroupBox {
                Layout.fillWidth: true
                title: "Globales Bilderverzeichnis (Cover/Thumbnails)"

                RowLayout {
                    anchors.fill: parent
                    spacing: 8

                    TextField {
                        id: imageDirField
                        Layout.fillWidth: true
                        placeholderText: "z. B. D:/Covers"
                    }

                    Button {
                        text: "Durchsuchen…"
                        onClicked: imageDirDialog.open()
                    }

                    Button {
                        text: "Speichern"
                        onClicked: settingsManager.set_global_image_directory(imageDirField.text)
                    }
                }
            }

            // ============================================================
            // Hauptverzeichnisse
            // ============================================================
            GroupBox {
                Layout.fillWidth: true
                title: "Hauptverzeichnisse"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 8

                    Repeater {
                        model: settingsPage.mainDirsModel

                        delegate: RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            TextField {
                                id: nameField
                                Layout.preferredWidth: 160
                                text: modelData.name
                                placeholderText: "Name"
                            }

                            TextField {
                                id: pathField
                                Layout.fillWidth: true
                                text: modelData.path
                                placeholderText: "Pfad"
                            }

                            Button {
                                text: "Speichern"
                                onClicked: settingsManager.update_main_directory(index, nameField.text, pathField.text)
                            }

                            Button {
                                text: "Entfernen"
                                onClicked: settingsManager.remove_main_directory(index)
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        TextField {
                            id: newNameField
                            Layout.preferredWidth: 160
                            placeholderText: "Neuer Name"
                        }

                        TextField {
                            id: newPathField
                            Layout.fillWidth: true
                            placeholderText: "Neuer Pfad"
                        }

                        Button {
                            text: "Hinzufügen"
                            enabled: newNameField.text.length > 0 && newPathField.text.length > 0
                            onClicked: {
                                settingsManager.add_main_directory(newNameField.text, newPathField.text)
                                newNameField.text = ""
                                newPathField.text = ""
                            }
                        }
                    }
                }
            }

            // ============================================================
            // Bildschirmschoner
            // ============================================================
            GroupBox {
                Layout.fillWidth: true
                title: "Bildschirmschoner"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 12

                    // Aktivieren / Deaktivieren
                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: "Bildschirmschoner aktiv"; Layout.preferredWidth: 220 }
                        Switch {
                            checked: settingsManager.screensaverEnabled
                            onToggled: settingsManager.screensaverEnabled = checked
                        }
                    }

                    // Wartezeit
                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: "Wartezeit bis Aktivierung"; Layout.preferredWidth: 220 }
                        Slider {
                            id: ssTimeoutSlider
                            Layout.fillWidth: true
                            enabled: settingsManager.screensaverEnabled
                            from: 30000; to: 1800000; stepSize: 30000
                            value: settingsManager.screensaverTimeout
                            onMoved: settingsManager.screensaverTimeout = value
                        }
                        Label {
                            text: {
                                var sec = Math.round(ssTimeoutSlider.value / 1000)
                                return sec >= 60
                                    ? Math.floor(sec / 60) + " min " + (sec % 60 > 0 ? sec % 60 + " s" : "")
                                    : sec + " s"
                            }
                            Layout.preferredWidth: 80
                        }
                    }

                    // Anzeigedauer pro Bild
                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: "Anzeigedauer pro Bild"; Layout.preferredWidth: 220 }
                        Slider {
                            id: ssIntervalSlider
                            Layout.fillWidth: true
                            enabled: settingsManager.screensaverEnabled
                            from: 1000; to: 60000; stepSize: 1000
                            value: settingsManager.screensaverImageInterval
                            onMoved: settingsManager.screensaverImageInterval = value
                        }
                        Label {
                            text: (ssIntervalSlider.value / 1000).toFixed(0) + " s"
                            Layout.preferredWidth: 50
                        }
                    }

                    // Bilderordner
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Label { text: "Bilderordner"; Layout.preferredWidth: 220 }

                        TextField {
                            id: ssDirField
                            Layout.fillWidth: true
                            enabled: settingsManager.screensaverEnabled
                            text: settingsManager.screensaverImageDirectory
                            placeholderText: "z. B. C:/Bilder/Bildschirmschoner"
                        }

                        Button {
                            text: "Durchsuchen…"
                            enabled: settingsManager.screensaverEnabled
                            onClicked: ssDirDialog.open()
                        }

                        Button {
                            text: "Speichern"
                            enabled: settingsManager.screensaverEnabled
                            onClicked: settingsManager.screensaverImageDirectory = ssDirField.text
                        }
                    }

                    Connections {
                        target: settingsManager
                        function onScreensaverImageDirectoryChanged() {
                            ssDirField.text = settingsManager.screensaverImageDirectory
                        }
                    }
                }
            }

            // ============================================================
            // TTS Text-Filter (Regex)
            // ============================================================
            GroupBox {
                Layout.fillWidth: true
                title: "TTS Text-Filter (Regex)"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 8

                    Label {
                        text: "Regeln werden der Reihe nach auf Datei-/Ordnernamen angewendet, bevor der Text gesprochen wird."
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                        color: settingsManager.colorText
                        font.pixelSize: 12 * settingsManager.fontScale
                    }

                    // Kopfzeile
                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: "Muster (Regex)"; Layout.fillWidth: true; font.bold: true }
                        Label { text: "Ersetzung"; Layout.fillWidth: true; font.bold: true }
                        Item { width: 80 }
                    }

                    // Bestehende Regeln
                    Repeater {
                        id: regexRepeater
                        model: settingsPage.regexRulesModel

                        delegate: RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            TextField {
                                id: patternField
                                Layout.fillWidth: true
                                text: modelData.pattern
                                placeholderText: "z. B. \\.[a-z]+$"
                                color: regexFilter.validate_pattern(text) ? settingsManager.colorText : "#cc0000"
                            }

                            TextField {
                                id: replacementField
                                Layout.fillWidth: true
                                text: modelData.replacement
                                placeholderText: "Ersetzung (leer = löschen)"
                            }

                            Button {
                                text: "Speichern"
                                width: 80
                                onClicked: {
                                    regexFilter.update_rule(index, patternField.text, replacementField.text)
                                    settingsPage.regexRulesModel = regexFilter.get_rules()
                                }
                            }

                            Button {
                                text: "Entfernen"
                                width: 80
                                onClicked: {
                                    regexFilter.remove_rule(index)
                                    settingsPage.regexRulesModel = regexFilter.get_rules()
                                }
                            }
                        }
                    }

                    // Neue Regel hinzufügen
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        TextField {
                            id: newPatternField
                            Layout.fillWidth: true
                            placeholderText: "Neues Muster (Regex)"
                            color: text.length === 0 || regexFilter.validate_pattern(text)
                                   ? settingsManager.colorText : "#cc0000"
                        }

                        TextField {
                            id: newReplacementField
                            Layout.fillWidth: true
                            placeholderText: "Neue Ersetzung"
                        }

                        Button {
                            text: "Hinzufügen"
                            width: 80
                            enabled: newPatternField.text.length > 0 && regexFilter.validate_pattern(newPatternField.text)
                            onClicked: {
                                regexFilter.add_rule(newPatternField.text, newReplacementField.text)
                                settingsPage.regexRulesModel = regexFilter.get_rules()
                                newPatternField.text = ""
                                newReplacementField.text = ""
                            }
                        }
                    }

                    // Test-Feld
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Label { text: "Testtext:"; Layout.preferredWidth: 80 }

                        TextField {
                            id: regexTestInput
                            Layout.fillWidth: true
                            placeholderText: "Beispiel-Dateiname eingeben"
                        }

                        Label {
                            text: "→ " + (regexTestInput.text.length > 0
                                          ? regexFilter.apply(regexTestInput.text) : "")
                            Layout.fillWidth: true
                            color: settingsManager.colorText
                            wrapMode: Text.Wrap
                        }
                    }
                }
            }

            // ============================================================
            // Reset
            // ============================================================
            Button {
                Layout.alignment: Qt.AlignRight
                text: "Auf Standardwerte zurücksetzen"
                onClicked: settingsManager.reset_to_defaults()
            }
        }
    }

    RowLayout {
        id: footer
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.margins: 10

        Button {
            text: "Zurück"
            onClicked: settingsPage.StackView.view.pop()
            HoverHandler { cursorShape: Qt.PointingHandCursor }
        }
    }

    FolderDialog {
        id: imageDirDialog
        title: "Bilderverzeichnis auswählen"
        onAccepted: {
            var url = imageDirDialog.selectedFolder.toString()
            var localPath = url.replace(/^file:\/{2,3}/, "")
            imageDirField.text = decodeURIComponent(localPath)
        }
    }

    FolderDialog {
        id: ssDirDialog
        title: "Bildschirmschoner-Bilderordner auswählen"
        onAccepted: {
            var url = ssDirDialog.selectedFolder.toString()
            var localPath = url.replace(/^file:\/{2,3}/, "")
            ssDirField.text = decodeURIComponent(localPath)
            settingsManager.screensaverImageDirectory = ssDirField.text
        }
    }
}
