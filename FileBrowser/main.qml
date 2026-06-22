import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtTextToSpeech

Item {
    id: root
    
    // WICHTIG: Hier kommen die Daten für DIESE Seite rein
    property var folderData: null 

    property int minCardWidth: settingsManager.cardMinWidth
    property int minCardHeight: settingsManager.cardMinHeight
    property int currentPage: 0
    property string lastPlayedFile: ""
    property bool shuffleEnabled: false

    Component.onCompleted: {
        root.updateLastPlayed()
        root.updateShuffleEnabled()
    }

    onFolderDataChanged: {
        root.updateLastPlayed()
        root.updateShuffleEnabled()
    }

    function updateLastPlayed() {
        if (root.folderData && root.folderData.path && typeof media_DB !== "undefined") {
            root.lastPlayedFile = media_DB.get_last_played_in_folder(root.folderData.path)
        } else {
            root.lastPlayedFile = ""
        }
    }

    function updateShuffleEnabled() {
        if (root.folderData && root.folderData.path) {
            root.shuffleEnabled = settingsManager.is_shuffle_folder(root.folderData.path)
        } else {
            root.shuffleEnabled = false
        }
    }

    // Wählt eine zufällige, noch nicht gesehene Folge aus dem aktuellen Ordner
    // (Datenbank merkt sich Gesehenes pro Ordner und setzt den Zyklus zurück, sobald alle gesehen wurden)
    function playShuffle() {
        if (!root.folderData || !root.folderData.children) return

        var files = []
        for (var i = 0; i < root.folderData.children.length; i++) {
            var child = root.folderData.children[i]
            if (child.type === "file" && child.path) {
                files.push(child.path)
            }
        }
        if (files.length === 0) return

        var chosen = media_DB.get_random_unwatched(root.folderData.path, files)
        if (!chosen) return
        media_DB.mark_shuffle_watched(root.folderData.path, chosen)

        var playlist = []
        var startIndex = 0
        for (var j = 0; j < files.length; j++) {
            if (files[j] === chosen) startIndex = playlist.length
            playlist.push("file:///" + files[j].replace(/\\/g, "/"))
        }

        root.StackView.view.push("../MultiMediaPlayer/main.qml", {
            "mediaSource": "file:///" + chosen.replace(/\\/g, "/"),
            "playlist": playlist,
            "playlistIndex": startIndex
        })
    }

    Component.onDestruction: {
        tts.stop()
    }

    // Header mit aktuellem Pfad/Namen
    Text {
        id: headerText
        text: root.folderData ? root.folderData.name : "..."
        font.pixelSize: 20 * settingsManager.fontScale
        font.bold: true
        color: settingsManager.colorText
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 10

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.speakIfEnabled(headerText.text)
        }
    }

    TextToSpeech {
        id: tts
        engine: "winrt"
        volume: settingsManager.ttsVolume
        rate: settingsManager.ttsRate
        Component.onCompleted: root.applyTtsVoice()
        onStateChanged: {
            if ((state === TextToSpeech.Ready || state === TextToSpeech.Error)
                    && root._ttsQueue.length > 0) {
                root.processNextQueueItem()
            }
        }
    }

    property var _ttsQueue: []

    Timer {
        id: dashPauseTimer
        interval: settingsManager.ttsDashPauseDuration
        repeat: false
        onTriggered: root.speakNextFromQueue()
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
            var voices = root.getAllVoices()
            for (var i = 0; i < voices.length; i++) {
                if (voices[i].name === settingsManager.ttsVoice) {
                    tts.voice = voices[i]
                    return
                }
            }
        }
    }

    function applyVoiceByName(voiceName) {
        var voices = root.getAllVoices()
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
        if (root._ttsQueue.length === 0) return
        var item = root._ttsQueue.shift()
        if (item.voice) {
            root.applyVoiceByName(item.voice)
        } else {
            root.applyTtsVoice()
        }
        tts.say(item.text)
    }

    function processNextQueueItem() {
        if (root._ttsQueue.length === 0) return
        if (root._ttsQueue[0].pause) {
            dashPauseTimer.start()
        } else {
            root.speakNextFromQueue()
        }
    }

    // Lädt den aktuellen Ordner neu (z. B. nach Änderung von Sortierung/versteckte Dateien)
    function reloadFolder() {
        if (root.folderData && root.folderData.path) {
            root.folderData = fileManager.path_to_dict(root.folderData.path)
            root.currentPage = 0
        }
    }

    Connections {
        target: settingsManager
        function onTtsVoiceChanged() { root.applyTtsVoice() }
        function onShowHiddenFilesChanged() { root.reloadFolder() }
        function onSortOrderChanged() { root.reloadFolder() }
        function onShuffle_folders_changed() { root.updateShuffleEnabled() }
    }

    Connections {
        target: media_DB
        function onHistoryChanged() { root.updateLastPlayed() }
    }

    function speakIfEnabled(text) {
        if (!settingsManager.ttsEnabled) return
        text = regexFilter.apply(text)
        tts.stop()
        root._ttsQueue = []

        var wordProns = []
        try { wordProns = JSON.parse(settingsManager.wordPronunciations || "[]") } catch (e) {}

        if (settingsManager.ttsDashPauseEnabled && text.indexOf(" - ") >= 0) {
            var parts = text.split(" - ").filter(function(s) { return s.trim().length > 0 })
            var queue = []
            for (var p = 0; p < parts.length; p++) {
                var segs = root.buildTtsSegments(parts[p], wordProns, p > 0)
                for (var s = 0; s < segs.length; s++) queue.push(segs[s])
            }
            root._ttsQueue = queue
        } else {
            root._ttsQueue = root.buildTtsSegments(text, wordProns, false)
        }

        if (root._ttsQueue.length > 0) root.speakNextFromQueue()
    }

    Grid {
        id: grid
        anchors.top: headerText.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 10
        anchors.bottomMargin: 60

        columnSpacing: 5
        rowSpacing: 5

        columns: Math.max(1, Math.floor(width / minCardWidth))
        property real cellWidth: (width - columnSpacing * (columns - 1)) / columns
        // So viele Reihen, wie bei minCardHeight passen würden → nutzt vertikalen Platz besser aus
        property int rows: Math.max(1, Math.floor((height + rowSpacing) / (minCardHeight + rowSpacing)))
        // Karten füllen ihre Reihe, aber max. 2:3 (verhindert über-streckte schmale Karten)
        property real cellHeight: Math.min(cellWidth * 1.5, (height - rowSpacing * (rows - 1)) / rows)
        property int cardsPerPage: columns * rows

        Repeater {
            // WICHTIG: Wir nutzen root.folderData.children
            model: root.folderData && root.folderData.children ? root.folderData.children : []

            delegate: Rectangle {
                id: card
                width: grid.cellWidth
                height: grid.cellHeight

                visible: index >= root.currentPage * grid.cardsPerPage &&
                        index < (root.currentPage + 1) * grid.cardsPerPage

                radius: 10
                color: modelData.type === "directory" ? settingsManager.colorCardDirectory : settingsManager.colorCardFile
                border.color: settingsManager.colorCardBorder
                clip: true // Verhindert, dass das Bild über die abgerundeten Ecken ragt

                // 1. Hintergrundbild (nimmt den ganzen Platz ein)
                Image {
                    id: bgImage
                    anchors.fill: parent
                    source: modelData.thumbnail || ""
                    fillMode: Image.PreserveAspectCrop // Füllt die Karte komplett aus
                    visible: status === Image.Ready // Nur anzeigen, wenn das Bild erfolgreich geladen wurde
                }

                MouseArea {
                    id: mouseAreaCard
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: settingsManager.speakTrigger === "hover" || settingsManager.openTrigger === "hover"
                    property string pendingSpeak: ""

                    function openItem() {
                        if (modelData.type === "directory") {
                            console.log("Opened Directory", modelData.name)
                            root.StackView.view.push("main.qml", {
                                "folderData": modelData
                            })
                        } else if (modelData.path) {
                            var urlPath = "file:///" + modelData.path.replace(/\\/g, "/")
                            // Playlist aus den Geschwister-Dateien bauen (für "Nächste Datei automatisch")
                            var siblings = root.folderData && root.folderData.children ? root.folderData.children : []
                            var playlist = []
                            var startIndex = 0
                            for (var i = 0; i < siblings.length; i++) {
                                if (siblings[i].type === "file" && siblings[i].path) {
                                    if (siblings[i].path === modelData.path)
                                        startIndex = playlist.length
                                    playlist.push("file:///" + siblings[i].path.replace(/\\/g, "/"))
                                }
                            }
                            root.StackView.view.push("../MultiMediaPlayer/main.qml", {
                                "mediaSource": urlPath,
                                "playlist": playlist,
                                "playlistIndex": startIndex
                            })
                            console.log("File:", modelData.name)
                        } else {
                            console.error("Fehler: Kein Pfad für Datei gefunden!", modelData.name)
                        }
                    }

                    Timer {
                        id: speakTimer
                        interval: settingsManager.clickSpeakDelay
                        repeat: false
                        onTriggered: root.speakIfEnabled(mouseAreaCard.pendingSpeak)
                    }

                    // Hover-Timers laufen nur, solange die Maus über der Karte ist
                    Timer {
                        id: hoverSpeakTimer
                        interval: settingsManager.hoverDelay
                        repeat: false
                        onTriggered: root.speakIfEnabled(mouseAreaCard.pendingSpeak)
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

                // 2. Inhalt (Emoji & Text)
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 5
                    // Verstecke das Emoji, wenn ein Bild angezeigt wird
                    visible: !bgImage.visible

                    Text {
                        text: modelData.type === "directory" ? "📁" : "📄"
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
                        Layout.maximumWidth: card.width - 10
                        color: settingsManager.colorCardText
                    }
                }

                // 3. Text-Overlay (Optional: Name über dem Bild anzeigen)
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: nameLabel.height + 10
                    color: "#80000000" // Halbtransparenter Balken
                    visible: bgImage.visible // Nur anzeigen, wenn das Bild da ist

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
            icon.source: "../icons/back.svg"
            icon.width: 24
            icon.height: 24
            onClicked: root.StackView.view.pop()
            HoverHandler {
                cursorShape: Qt.PointingHandCursor
            }
        }

        Button {
            icon.source: "../icons/home.svg"
            icon.width: 24
            icon.height: 24
            onClicked: root.StackView.view.pop(null)
            HoverHandler {
                cursorShape: Qt.PointingHandCursor
            }
        }

        // Pagination Buttons
        Button {
            icon.source: "../icons/arrow_left.svg"
            icon.width: 24
            icon.height: 24
            enabled: root.currentPage > 0
            // Unsichtbar machen, wenn deaktiviert und Einstellung aktiv – Platz bleibt erhalten
            opacity: (!enabled && settingsManager.hideDisabledNavButtons) ? 0 : 1
            onClicked: root.currentPage--
            HoverHandler {
                cursorShape: Qt.PointingHandCursor
            }
        }

        Text {
            id: pageIndicator
            property int totalItems: root.folderData && root.folderData.children ? root.folderData.children.length : 0
            text: (root.currentPage + 1) + " / " + Math.max(1, Math.ceil(totalItems / grid.cardsPerPage))
            color: settingsManager.colorText
            font.pixelSize: 16 * settingsManager.fontScale
            font.bold: true
            MouseArea {
                anchors.fill: parent

                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.speakIfEnabled("Seite " + (root.currentPage + 1) + " von " + Math.max(1, Math.ceil(pageIndicator.totalItems / grid.cardsPerPage)))
                }
            }
        }

        Button {
            icon.source: "../icons/arrow_forward.png"
            icon.width: 24
            icon.height: 24
            property int totalItems: root.folderData && root.folderData.children ? root.folderData.children.length : 0
            enabled: root.currentPage < Math.ceil(totalItems / grid.cardsPerPage) - 1
            // Unsichtbar machen, wenn deaktiviert und Einstellung aktiv – Platz bleibt erhalten
            opacity: (!enabled && settingsManager.hideDisabledNavButtons) ? 0 : 1
            onClicked: root.currentPage++
            HoverHandler {
                cursorShape: Qt.PointingHandCursor
            }
        }

        Button {
            visible: root.lastPlayedFile !== ""
            icon.source: "../icons/play.svg"
            icon.width: 24
            icon.height: 24
            ToolTip.text: {
                var parts = root.lastPlayedFile.replace(/\\/g, "/").split("/")
                var name = parts[parts.length - 1]
                var dot = name.lastIndexOf(".")
                return dot > 0 ? name.substring(0, dot) : name
            }
            ToolTip.visible: hovered
            ToolTip.delay: 400
            onClicked: {
                var filePath = root.lastPlayedFile.replace(/\\/g, "/")
                var urlPath = "file:///" + filePath
                var siblings = root.folderData && root.folderData.children ? root.folderData.children : []
                var playlist = []
                var startIndex = 0
                for (var i = 0; i < siblings.length; i++) {
                    if (siblings[i].type === "file" && siblings[i].path) {
                        if (siblings[i].path.replace(/\\/g, "/") === filePath)
                            startIndex = playlist.length
                        playlist.push("file:///" + siblings[i].path.replace(/\\/g, "/"))
                    }
                }
                root.StackView.view.push("../MultiMediaPlayer/main.qml", {
                    "mediaSource": urlPath,
                    "playlist": playlist,
                    "playlistIndex": startIndex
                })
            }
            HoverHandler {
                cursorShape: Qt.PointingHandCursor
            }
        }

        Button {
            id: shuffleButton
            icon.source: "../icons/shuffle.svg"
            icon.width: 24
            icon.height: 24
            enabled: root.shuffleEnabled
            // "weg" (kein Platzverbrauch) wenn die Einstellung es vorsieht, sonst nur "ausgeblendet" (deaktiviert)
            visible: root.shuffleEnabled || !settingsManager.hideShuffleButton
            opacity: enabled ? 1 : 0.4
            ToolTip.text: "Zufällige Folge abspielen"
            ToolTip.visible: hovered
            ToolTip.delay: 400
            onClicked: root.playShuffle()
            HoverHandler {
                cursorShape: Qt.PointingHandCursor
            }
        }
    }
}
