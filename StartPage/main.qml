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

    TextToSpeech {
        id: tts
        volume: settingsManager.ttsVolume
        rate: settingsManager.ttsRate
        Component.onCompleted: startPage.applyTtsVoice()
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

    Connections {
        target: settingsManager
        function onTtsVoiceChanged() { startPage.applyTtsVoice() }
    }

    function speakIfEnabled(text) {
        if (settingsManager.ttsEnabled) tts.say(text)
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

                MouseArea {
                    id: mouseAreaCard
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
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

                ColumnLayout {
                    anchors.centerIn: parent
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
