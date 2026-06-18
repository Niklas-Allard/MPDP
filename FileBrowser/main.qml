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

    Component.onCompleted: root.updateLastPlayed()

    onFolderDataChanged: root.updateLastPlayed()

    function updateLastPlayed() {
        if (root.folderData && root.folderData.path && typeof media_DB !== "undefined") {
            root.lastPlayedFile = media_DB.get_last_played_in_folder(root.folderData.path)
        } else {
            root.lastPlayedFile = ""
        }
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
        volume: settingsManager.ttsVolume
        rate: settingsManager.ttsRate
        Component.onCompleted: root.applyTtsVoice()
        onStateChanged: {
            if ((state === TextToSpeech.Ready || state === TextToSpeech.Error)
                    && root._ttsQueue.length > 0) {
                dashPauseTimer.start()
            }
        }
    }

    property var _ttsQueue: []

    Timer {
        id: dashPauseTimer
        interval: settingsManager.ttsDashPauseDuration
        repeat: false
        onTriggered: {
            if (root._ttsQueue.length > 0) {
                tts.say(root._ttsQueue.shift())
            }
        }
    }

    // Übernimmt die in den Einstellungen gewählte Stimme (auch bei späterer Änderung)
    function applyTtsVoice() {
        if (settingsManager.ttsVoice) {
            var voices = tts.availableVoices()
            for (var i = 0; i < voices.length; i++) {
                if (voices[i].name === settingsManager.ttsVoice) {
                    tts.voice = voices[i]
                    break
                }
            }
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
        if (settingsManager.ttsDashPauseEnabled && text.indexOf(" - ") >= 0) {
            var parts = text.split(" - ").filter(function(s) { return s.trim().length > 0 })
            root._ttsQueue = parts
            if (root._ttsQueue.length > 0) tts.say(root._ttsQueue.shift())
        } else {
            tts.say(text)
        }
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

                    onClicked: {
                        if (settingsManager.openOnSingleClick) {
                            speakTimer.stop()
                            openItem()
                        } else {
                            mouseAreaCard.pendingSpeak = modelData.name
                            speakTimer.restart()
                        }
                    }

                    onDoubleClicked: (mouse) => {
                        speakTimer.stop()
                        openItem()
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
    }
}
