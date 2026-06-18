import QtQuick
import QtQuick.Controls

Rectangle {
    id: screensaver
    color: "black"
    focus: true

    property var images: []
    property int currentIndex: 0
    property bool showingA: true

    Component.onCompleted: {
        images = settingsManager.get_screensaver_images()
        if (images.length > 0) {
            imgA.source = images[0]
            imgA.opacity = 1
        }
        forceActiveFocus()
    }

    // Bild A
    Image {
        id: imgA
        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
        opacity: 0
        Behavior on opacity { NumberAnimation { duration: 800 } }
    }

    // Bild B (wird abwechselnd mit A eingeblendet)
    Image {
        id: imgB
        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
        opacity: 0
        z: 1
        Behavior on opacity { NumberAnimation { duration: 800 } }
    }

    Timer {
        id: slideTimer
        interval: settingsManager.screensaverImageInterval
        repeat: true
        running: screensaver.images.length > 1
        onTriggered: {
            screensaver.currentIndex = (screensaver.currentIndex + 1) % screensaver.images.length
            var src = screensaver.images[screensaver.currentIndex]
            if (screensaver.showingA) {
                imgB.source = src
                imgA.opacity = 0
                imgB.opacity = 1
            } else {
                imgA.source = src
                imgB.opacity = 0
                imgA.opacity = 1
            }
            screensaver.showingA = !screensaver.showingA
        }
    }

    // Hinweis: Eingabe wird in main.qml via activityMonitor abgefangen →
    // der Screensaver muss hier keine Eingabe selbst behandeln.
    Text {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 24
        text: "Zum Beenden berühren"
        color: "#66ffffff"
        font.pixelSize: 16
    }
}
