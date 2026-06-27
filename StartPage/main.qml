import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtTextToSpeech

Item {
    id: startPage

    // Damit das Grid genauso wie im FileBrowser funktioniert:
    property var folderData: null
    property int minCardWidth: settingsManager.cardMinWidth
    property int minCardHeight: settingsManager.cardMinHeight
    property int currentPage: 0

    Component.onDestruction: {
        tts.stop()
    }

    TextToSpeech {
        id: tts
        engine: "winrt"
        volume: settingsManager.ttsVolume
        rate: settingsManager.ttsRate
        Component.onCompleted: startPage.applyTtsVoice()
        onStateChanged: {
            if ((state === TextToSpeech.Ready || state === TextToSpeech.Error)
                    && startPage._ttsQueue.length > 0) {
                startPage.processNextQueueItem()
            }
        }
    }

    property var _ttsQueue: []

    Timer {
        id: dashPauseTimer
        interval: settingsManager.ttsDashPauseDuration
        repeat: false
        onTriggered: startPage.speakNextFromQueue()
    }

    // availableVoices() liefert nur Stimmen der aktuell gesetzten Locale (Default: Systemsprache) –
    // hier werden die Stimmen aller installierten Sprachen eingesammelt.
    function getAllVoices() {
        var savedLocale = tts.locale
        var locales = tts.availableLocales()
        var all = []
        for (var i = 0; i < locales.length; i++) {
            tts.locale = locales[i]
            all = all.concat(tts.availableVoices())
        }
        tts.locale = savedLocale
        return all
    }

    // Übernimmt die in den Einstellungen gewählte Stimme (auch bei späterer Änderung)
    function applyTtsVoice() {
        if (settingsManager.ttsVoice) {
            var voices = startPage.getAllVoices()
            for (var i = 0; i < voices.length; i++) {
                if (voices[i].name === settingsManager.ttsVoice) {
                    tts.voice = voices[i]
                    return
                }
            }
        }
    }

    function applyVoiceByName(voiceName) {
        var voices = startPage.getAllVoices()
        for (var i = 0; i < voices.length; i++) {
            if (voices[i].name === voiceName) {
                tts.voice = voices[i]
                return
            }
        }
    }

    // Segmentiert Text anhand der Wortaussprache-Liste in {text, voice, pause}-Objekte.
    function buildTtsSegments(text, wordProns, withPause) {
        var segs = [{text: text, voice: null}]
        for (var i = 0; i < wordProns.length; i++) {
            var entry = wordProns[i]
            var escaped = entry.word.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
            var re = new RegExp("\\b(" + escaped + ")\\b", "gi")
            var newSegs = []
            for (var j = 0; j < segs.length; j++) {
                var seg = segs[j]
                if (seg.voice !== null) { newSegs.push(seg); continue }
                var src = seg.text
                var lastIdx = 0
                var m
                re.lastIndex = 0
                while ((m = re.exec(src)) !== null) {
                    if (m.index > lastIdx)
                        newSegs.push({text: src.slice(lastIdx, m.index), voice: null})
                    newSegs.push({text: m[0], voice: entry.voice})
                    lastIdx = re.lastIndex
                }
                if (lastIdx < src.length)
                    newSegs.push({text: src.slice(lastIdx), voice: null})
            }
            segs = newSegs
        }
        var result = []
        var first = true
        for (var k = 0; k < segs.length; k++) {
            if (segs[k].text.trim().length === 0) continue
            segs[k].pause = withPause && first
            first = false
            result.push(segs[k])
        }
        return result
    }

    function speakNextFromQueue() {
        if (startPage._ttsQueue.length === 0) return
        var item = startPage._ttsQueue.shift()
        if (item.voice) {
            startPage.applyVoiceByName(item.voice)
        } else {
            startPage.applyTtsVoice()
        }
        tts.say(item.text)
    }

    function processNextQueueItem() {
        if (startPage._ttsQueue.length === 0) return
        if (startPage._ttsQueue[0].pause) {
            dashPauseTimer.start()
        } else {
            startPage.speakNextFromQueue()
        }
    }

    Connections {
        target: settingsManager
        function onTtsVoiceChanged() { startPage.applyTtsVoice() }
    }

    function speakIfEnabled(text) {
        if (!settingsManager.ttsEnabled) return
        text = regexFilter.apply(text)
        tts.stop()
        startPage._ttsQueue = []

        var wordProns = []
        try { wordProns = JSON.parse(settingsManager.wordPronunciations || "[]") } catch (e) {}

        if (settingsManager.ttsDashPauseEnabled && text.indexOf(" - ") >= 0) {
            var parts = text.split(" - ").filter(function(s) { return s.trim().length > 0 })
            var queue = []
            for (var p = 0; p < parts.length; p++) {
                var segs = startPage.buildTtsSegments(parts[p], wordProns, p > 0)
                for (var s = 0; s < segs.length; s++) queue.push(segs[s])
            }
            startPage._ttsQueue = queue
        } else {
            startPage._ttsQueue = startPage.buildTtsSegments(text, wordProns, false)
        }

        if (startPage._ttsQueue.length > 0) startPage.speakNextFromQueue()
    }

    // Header mit aktuellem Pfad/Namen
    Text {
        id: headerText
        text: startPage.folderData ? startPage.folderData.name : "..."
        font.pixelSize: 20 * settingsManager.fontScale
        font.bold: true
        color: settingsManager.colorText
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 10

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: startPage.speakIfEnabled(headerText.text)
        }
    }

    GridLayout {
        id: grid
        anchors.top: headerText.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 10
        anchors.bottomMargin: 60

        columns: Math.max(1, Math.floor(width / minCardWidth))
        rows: Math.max(1, Math.floor(height / minCardHeight))
        property int cardsPerPage: columns * rows

        Repeater {
            model: mainDirs

            delegate: Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                // Cover-Verhältnis 2:3 (Bild ist 2 breit zu 3 hoch).
                // Greift nur, wenn die Karte sonst schlanker als 2:3 würde
                // (z. B. einzelne Reihe, die sich über die volle Grid-Höhe streckt).
                Layout.maximumHeight: width * 1.5
                Layout.alignment: Qt.AlignTop

                visible: index >= startPage.currentPage * grid.cardsPerPage &&
                         index < (startPage.currentPage + 1) * grid.cardsPerPage

                Component.onCompleted: {
                    console.log("Delegate created for", modelData)
                }

                radius: 10
                color: settingsManager.colorCardDirectory
                border.color: settingsManager.colorCardBorder
                clip: true

                Image {
                    id: bgImage
                    anchors.fill: parent
                    source: modelData.thumbnail || ""
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                }

                MouseArea {
                    id: mouseAreaCard
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: settingsManager.speakTrigger === "hover" || settingsManager.openTrigger === "hover"
                    property string pendingSpeak: ""

                    function openItem() {
                        parent.parent.parent.parent.push("../FileBrowser/main.qml",
                            { folderData: fileManager.path_to_dict(modelData.path) })
                    }

                    Timer {
                        id: speakTimer
                        interval: settingsManager.clickSpeakDelay
                        repeat: false
                        onTriggered: startPage.speakIfEnabled(mouseAreaCard.pendingSpeak)
                    }

                    // Hover-Timers laufen nur, solange die Maus über der Karte ist
                    Timer {
                        id: hoverSpeakTimer
                        interval: settingsManager.hoverDelay
                        repeat: false
                        onTriggered: startPage.speakIfEnabled(mouseAreaCard.pendingSpeak)
                    }

                    Timer {
                        id: hoverOpenTimer
                        interval: settingsManager.hoverDelay
                        repeat: false
                        onTriggered: openItem()
                    }

                    onContainsMouseChanged: {
                        if (containsMouse) {
                            if (settingsManager.speakTrigger === "hover") {
                                mouseAreaCard.pendingSpeak = modelData.name
                                hoverSpeakTimer.restart()
                            }
                            if (settingsManager.openTrigger === "hover") {
                                hoverOpenTimer.restart()
                            }
                        } else {
                            hoverSpeakTimer.stop()
                            hoverOpenTimer.stop()
                        }
                    }

                    onClicked: {
                        if (settingsManager.speakTrigger === "singleClick") {
                            mouseAreaCard.pendingSpeak = modelData.name
                            speakTimer.restart()
                        }
                        if (settingsManager.openTrigger === "singleClick") {
                            speakTimer.stop()
                            openItem()
                        }
                    }

                    onDoubleClicked: {
                        speakTimer.stop()
                        hoverSpeakTimer.stop()
                        hoverOpenTimer.stop()
                        if (settingsManager.speakTrigger === "doubleClick") {
                            mouseAreaCard.pendingSpeak = modelData.name
                            speakTimer.restart()
                        }
                        if (settingsManager.openTrigger === "doubleClick") {
                            openItem()
                        }
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    visible: !bgImage.visible
                    Text {
                        text: "📁"
                        font.pixelSize: 40 * settingsManager.fontScale
                        Layout.alignment: Qt.AlignHCenter
                        color: settingsManager.colorCardText
                    }
                    Text {
                        text: modelData.name
                        font.bold: true
                        font.pixelSize: 14 * settingsManager.fontScale
                        Layout.alignment: Qt.AlignHCenter
                        elide: Text.ElideRight
                        Layout.maximumWidth: parent.width
                        color: settingsManager.colorCardText
                    }
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: nameLabel.height + 10
                    color: "#80000000"
                    visible: bgImage.visible

                    Text {
                        id: nameLabel
                        text: modelData.name
                        color: "white"
                        font.bold: true
                        font.pixelSize: 14 * settingsManager.fontScale
                        anchors.centerIn: parent
                        elide: Text.ElideRight
                        width: parent.width - 10
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
    }

    RowLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.margins: 10

        Button {
            icon.source: "../icons/arrow_left.svg"
            icon.width: 24
            icon.height: 24
            enabled: startPage.currentPage > 0
            // Unsichtbar machen, wenn deaktiviert und Einstellung aktiv – Platz bleibt erhalten
            opacity: (!enabled && settingsManager.hideDisabledNavButtons) ? 0 : 1
            onClicked: startPage.currentPage--
            HoverHandler { cursorShape: Qt.PointingHandCursor }
        }

        Text {
            id: pageIndicator
            property int totalItems: startPage.folderData && startPage.folderData.children
                                     ? startPage.folderData.children.length : 0
            text: (startPage.currentPage + 1) + " / " + Math.max(1, Math.ceil(totalItems / grid.cardsPerPage))
            color: settingsManager.colorText
            font.pixelSize: 16 * settingsManager.fontScale
            font.bold: true

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    startPage.speakIfEnabled("Seite " + (startPage.currentPage + 1) + " von " +
                            Math.max(1, Math.ceil(pageIndicator.totalItems / grid.cardsPerPage)))
                }
            }
        }

        Button {
            icon.source: "../icons/arrow_forward.png"
            icon.width: 24
            icon.height: 24
            property int totalItems: startPage.folderData && startPage.folderData.children
                                     ? startPage.folderData.children.length : 0
            enabled: startPage.currentPage < Math.ceil(totalItems / grid.cardsPerPage) - 1
            // Unsichtbar machen, wenn deaktiviert und Einstellung aktiv – Platz bleibt erhalten
            opacity: (!enabled && settingsManager.hideDisabledNavButtons) ? 0 : 1
            onClicked: startPage.currentPage++
            HoverHandler { cursorShape: Qt.PointingHandCursor }
        }
    }
}
