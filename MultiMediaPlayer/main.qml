import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia
import QtTextToSpeech

Item {
    id: multiMediaPlayerPage

    property string mediaSource: ""
    property bool isPlaying: mediaplayer.playbackState === MediaPlayer.PlayingState
    // Playlist der Dateien im selben Ordner + Position darin (für autoPlayNext)
    property var playlist: []
    property int playlistIndex: -1
    // aus QSettings, mit sinnvollem Fallback
    property int cursorHideTimeout: settingsManager ? settingsManager.cursorHideTimeout : 5000
    // true, solange wir auf das Ende der TTS-Ansage warten, um dann das Video zu starten
    property bool pendingPlay: false

    Component.onCompleted: {
        if (typeof media_DB !== "undefined") {
            media_DB.add_to_history(mediaSource.replace("file:///", ""))
        }
    }

    Component.onDestruction: tts.stop()

    // Sprachausgabe für die Ansage der nächsten Folge
    TextToSpeech {
        id: tts
        volume: settingsManager ? settingsManager.ttsVolume : 1.0
        rate: settingsManager ? settingsManager.ttsRate : 0.0
        Component.onCompleted: multiMediaPlayerPage.applyTtsVoice()

        onStateChanged: {
            if (state === TextToSpeech.Ready || state === TextToSpeech.Error) {
                // Erst die Queue abarbeiten (Pausen bei " - ")
                if (multiMediaPlayerPage._ttsQueue.length > 0) {
                    dashPauseTimer.start()
                    return
                }
                // Queue leer: Video starten wenn Ansage abgeschlossen
                if (multiMediaPlayerPage.pendingPlay) {
                    multiMediaPlayerPage.pendingPlay = false
                    mediaplayer.play()
                }
            }
        }
    }

    property var _ttsQueue: []

    Timer {
        id: dashPauseTimer
        interval: settingsManager ? settingsManager.ttsDashPauseDuration : 400
        repeat: false
        onTriggered: {
            if (multiMediaPlayerPage._ttsQueue.length > 0) {
                tts.say(multiMediaPlayerPage._ttsQueue.shift())
            }
        }
    }

    Connections {
        target: settingsManager
        function onTtsVoiceChanged() { multiMediaPlayerPage.applyTtsVoice() }
    }

    // Übernimmt die in den Einstellungen gewählte Stimme (auch bei späterer Änderung)
    function applyTtsVoice() {
        if (settingsManager && settingsManager.ttsVoice) {
            var voices = tts.availableVoices()
            for (var i = 0; i < voices.length; i++) {
                if (voices[i].name === settingsManager.ttsVoice) {
                    tts.voice = voices[i]
                    break
                }
            }
        }
    }

    // Liefert den reinen Dateinamen aus einer "file:///..."-Quelle
    function fileNameFromSource(src) {
        var s = decodeURIComponent(src.replace(/^file:\/{3}/, ""))
        var parts = s.split("/")
        return parts[parts.length - 1]
    }

    Timer {
        id: progressTimer
        interval: 5000
        repeat: true
        // Fortschritt immer mitschreiben, damit "Fortsetzen" später greifen kann
        running: true
        onTriggered: {
            if (typeof media_DB !== "undefined") {
                media_DB.set_progress(multiMediaPlayerPage.mediaSource.replace("file:///", ""), Math.floor(mediaplayer.position / 1000))
            }
        }
    }

    MediaPlayer {
        id: mediaplayer
        source: multiMediaPlayerPage.mediaSource
        audioOutput: AudioOutput {
            id: audioOutput
            muted: true
            volume: settingsManager ? settingsManager.defaultVolume : 1.0
        }
        videoOutput: videoOutput
        position: {
            if (settingsManager && settingsManager.resumePlayback && typeof media_DB !== "undefined") {
                var pos = media_DB.get_progress(multiMediaPlayerPage.mediaSource.replace("file:///", ""))
                if (pos !== null) {
                    return pos * 1000
                }
            }
            return 0
        }
        // Wiedergabe wird bewusst manuell gesteuert (Initial-Timer bzw. nach TTS-Ansage)
        autoPlay: false

        // "Nächste Datei automatisch": am Ende zum nächsten Eintrag der Playlist springen
        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.EndOfMedia &&
                    settingsManager && settingsManager.autoPlayNext &&
                    multiMediaPlayerPage.playlistIndex >= 0 &&
                    multiMediaPlayerPage.playlistIndex < multiMediaPlayerPage.playlist.length - 1) {
                multiMediaPlayerPage.playlistIndex++
                multiMediaPlayerPage.mediaSource = multiMediaPlayerPage.playlist[multiMediaPlayerPage.playlistIndex]
                if (typeof media_DB !== "undefined") {
                    media_DB.add_to_history(multiMediaPlayerPage.mediaSource.replace("file:///", ""))
                }

                if (settingsManager && settingsManager.ttsEnabled && settingsManager.announceNextFile) {
                    multiMediaPlayerPage.pendingPlay = !settingsManager || settingsManager.autoPlayOnOpen
                    var announceText = "Nächste Folge: " +
                            multiMediaPlayerPage.fileNameFromSource(multiMediaPlayerPage.mediaSource)
                    tts.stop()
                    multiMediaPlayerPage._ttsQueue = []
                    if (settingsManager.ttsDashPauseEnabled && announceText.indexOf(" - ") >= 0) {
                        var parts = announceText.split(" - ").filter(function(s) { return s.trim().length > 0 })
                        multiMediaPlayerPage._ttsQueue = parts
                        tts.say(multiMediaPlayerPage._ttsQueue.shift())
                    } else {
                        tts.say(announceText)
                    }
                } else if (!settingsManager || settingsManager.autoPlayOnOpen) {
                    // Ohne Ansage: direkt weiterspielen
                    mediaplayer.play()
                }
            }
        }
    }

    // loads the saved position after a short delay to ensure media is ready
    Timer {
        interval: 200
        repeat: false
        running: true
        onTriggered: {
            mediaplayer.pause()
            if (settingsManager && settingsManager.resumePlayback && typeof media_DB !== "undefined") {
                var pos = media_DB.get_progress(multiMediaPlayerPage.mediaSource.replace("file:///", ""))
                if (pos !== null) {
                    mediaplayer.position = pos * 1000
                }
            }
            audioOutput.muted = false
            // Nur sofort starten, wenn die Einstellung es erlaubt – sonst pausiert lassen
            if (!settingsManager || settingsManager.autoPlayOnOpen) {
                mediaplayer.play()
            }
        }
    }

    VideoOutput {
        id: videoOutput
        anchors.fill: parent
    }

    MouseArea {
        id: mediaPlayerMouseArea
        anchors.fill: parent
        onClicked: {
            if (mediaplayer.playbackState === MediaPlayer.PlayingState) {
                mediaplayer.pause()
            } else {
                mediaplayer.play()
            }
        }
        hoverEnabled: true
        cursorShape: Qt.ArrowCursor 

        Timer {
            id: cursorHideTimer
            interval: multiMediaPlayerPage.cursorHideTimeout
            repeat: false
            onTriggered: {
                mediaPlayerMouseArea.cursorShape = Qt.BlankCursor
            }
        }

        onPositionChanged: {
            mediaPlayerMouseArea.cursorShape = Qt.ArrowCursor
            cursorHideTimer.restart()
        }
        onPressed: {
            mediaPlayerMouseArea.cursorShape = Qt.ArrowCursor
            cursorHideTimer.restart()
        }
        onEntered: {
            mediaPlayerMouseArea.cursorShape = Qt.ArrowCursor
            cursorHideTimer.restart()
        }
        onExited: {
            // Wenn du willst, beim Verlassen sofort wieder normaler Cursor
            mediaPlayerMouseArea.cursorShape = Qt.ArrowCursor
            cursorHideTimer.stop()
        }
    }

    Rectangle {
        id: controlBar
        // Bewusst kräftig dunkel (liegt über Video bzw. Fensterhintergrund),
        // damit die hellen Icons/Texte in jedem Theme lesbar bleiben.
        color: "#D8000000"
        radius: 10
        height: 60
        visible: mediaplayer.playbackState !== MediaPlayer.PlayingState

        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 10

        MouseArea {
            id: controlBarMouseArea
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            propagateComposedEvents: false
            onClicked: (mouse) => { mouse.accepted = true }
            onPressed: (mouse) => { mouse.accepted = true }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            Button {
                icon.source: "../icons/back.svg"
                icon.width: 24
                icon.height: 24
                onClicked: multiMediaPlayerPage.StackView.view.pop()
                HoverHandler { cursorShape: Qt.PointingHandCursor }
            }
            Button {
                icon.source: "../icons/home.svg"
                icon.width: 24
                icon.height: 24
                onClicked: multiMediaPlayerPage.StackView.view.pop(null)
                HoverHandler { cursorShape: Qt.PointingHandCursor }
            }

            // OFFIZIELLER QT SLIDER (funktioniert garantiert)
            Slider {
                id: positionSlider
                Layout.fillWidth: true
                from: 0
                to: 1.0
                value: mediaplayer.duration > 0 ? mediaplayer.position / mediaplayer.duration : 0.0
                enabled: mediaplayer.seekable && mediaplayer.duration > 0

                onMoved: {
                    mediaplayer.position = value * mediaplayer.duration
                }
            }

            Text {
                text: {
                    var posM = Math.floor(mediaplayer.position / 60000)
                    var posS = Math.floor((mediaplayer.position % 60000) / 1000)
                    var durM = Math.floor(mediaplayer.duration / 60000)
                    var durS = Math.floor((mediaplayer.duration % 60000) / 1000)
                    return posM + ":" + (posS < 10 ? "0" : "") + posS + 
                        " / " + durM + ":" + (durS < 10 ? "0" : "") + durS
                }
                color: "white"
            }
        }
    }
}