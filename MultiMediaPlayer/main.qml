import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia

Item {
    id: multiMediaPlayerPage

    property string mediaSource: ""
    property int cursorHideTimeout: 5000

    Component.onCompleted: {
        if (typeof media_DB !== "undefined") {
            media_DB.add_to_history(mediaSource.replace("file:///", ""))    
        }
    }

    Timer {
        id: progressTimer
        interval: 5000
        repeat: true
        running: true
        onTriggered: {
            if (typeof media_DB !== "undefined") {
                media_DB.set_progress(multiMediaPlayerPage.mediaSource.replace("file:///", ""), Math.floor(mediaplayer.position / 1000)) // saves progress in seconds
            }
        }
    }

    MediaPlayer {
        id: mediaplayer
        source: multiMediaPlayerPage.mediaSource
        audioOutput: AudioOutput {
            id: audioOutput
            muted: true
        }
        videoOutput: videoOutput
        position: { 
            if (typeof media_DB !== "undefined") {
                var pos = media_DB.get_progress(multiMediaPlayerPage.mediaSource.replace("file:///", ""))
                console.log("Restoring position: " + pos)
                if (pos !== null) {
                    return pos * 1000 // convert seconds to milliseconds
                }
            }
            return 0
        }
        autoPlay: true
    }

    // loads the saved position after a short delay to ensure media is ready
    Timer {
        interval: 200
        repeat: false
        running: true
        onTriggered: {
            mediaplayer.pause()
            if (typeof media_DB !== "undefined") {
                var pos = media_DB.get_progress(multiMediaPlayerPage.mediaSource.replace("file:///", ""))
                console.log("Restoring position: " + pos)
                if (pos !== null) {
                    mediaplayer.position = pos * 1000 // convert seconds to milliseconds
                }
            }
            audioOutput.muted = false
            mediaplayer.play()
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
        color: "#00000080"
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
                icon.color: "white"
                icon.width: 32
                icon.height: 32
                implicitWidth: 48
                implicitHeight: 48
                background: Rectangle { color: "transparent" }
                onClicked: multiMediaPlayerPage.StackView.view.pop()
            }
            Button {
                icon.source: "../icons/home.svg"
                icon.color: "white"
                icon.width: 32
                icon.height: 32
                implicitWidth: 48
                implicitHeight: 48
                background: Rectangle { color: "transparent" }
                onClicked: multiMediaPlayerPage.StackView.view.pop(null)
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