import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtTextToSpeech

Item {
    id: root
    
    // WICHTIG: Hier kommen die Daten für DIESE Seite rein
    property var folderData: null 

    property int minCardWidth: 150
    property int minCardHeight: 150
    property int currentPage: 0

    Component.onDestruction: {
        tts.stop()
    }

    // Header mit aktuellem Pfad/Namen
    Text {
        id: headerText
        text: root.folderData ? root.folderData.name : "..."
        font.pixelSize: 20
        font.bold: true
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 10
    }

    TextToSpeech { 
        id: tts 
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
                color: modelData.type === "directory" ? "#e3f2fd" : "#f0f0f0"
                border.color: "#ddd"
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

                    Timer {
                        id: speakTimer
                        interval: Qt.styleHints.mouseDoubleClickInterval
                        repeat: false
                        onTriggered: tts.say(mouseAreaCard.pendingSpeak)
                    }

                    onClicked: {
                        mouseAreaCard.pendingSpeak = modelData.name
                        speakTimer.restart()
                    }

                    onDoubleClicked: (mouse) => {
                        speakTimer.stop()
                        if (modelData.type === "directory") {
                            console.log("Opened Directory", modelData.name)
                            // Navigiert in den Ordner
                            root.StackView.view.push("main.qml", {
                                "folderData": modelData
                            })
                        } else {
                            if (modelData.path) {
                                var urlPath = "file:///" + modelData.path.replace(/\\/g, "/")
                                // Öffnet den MediaPlayer
                                root.StackView.view.push("../MultiMediaPlayer/main.qml", {
                                    "mediaSource": urlPath
                                })
                                console.log("File:", modelData.name)
                            } else {
                                console.error("Fehler: Kein Pfad für Datei gefunden!", modelData.name)
                            }
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
                        font.pixelSize: 40
                        Layout.alignment: Qt.AlignHCenter
                    }
                    
                    Text {
                        text: modelData.name
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                        elide: Text.ElideRight
                        Layout.maximumWidth: card.width - 10
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
            onClicked: root.currentPage--
            HoverHandler {
                cursorShape: Qt.PointingHandCursor
            }
        }

        Text {
            id: pageIndicator
            property int totalItems: root.folderData && root.folderData.children ? root.folderData.children.length : 0
            text: (root.currentPage + 1) + " / " + Math.max(1, Math.ceil(totalItems / grid.cardsPerPage))
            color: "#ffffffff"
            font.pixelSize: 16
            font.bold: true
            MouseArea {
                anchors.fill: parent

                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    tts.say("Seite " + (root.currentPage + 1) + " von " + Math.max(1, Math.ceil(pageIndicator.totalItems / grid.cardsPerPage)))
                }
            }
        }

        Button {
            icon.source: "../icons/arrow_forward.png"
            icon.width: 24
            icon.height: 24
            property int totalItems: root.folderData && root.folderData.children ? root.folderData.children.length : 0
            enabled: root.currentPage < Math.ceil(totalItems / grid.cardsPerPage) - 1
            onClicked: root.currentPage++
            HoverHandler {
                cursorShape: Qt.PointingHandCursor
            }
        }
    }
}
