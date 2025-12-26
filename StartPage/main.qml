import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtTextToSpeech

Item {
    id: startPage

    // Damit das Grid genauso wie im FileBrowser funktioniert:
    property var folderData: null
    property int minCardWidth: 150
    property int minCardHeight: 150
    property int currentPage: 0

    TextToSpeech {
        id: tts
    }

    // Header mit aktuellem Pfad/Namen
    Text {
        id: headerText
        text: startPage.folderData ? startPage.folderData.name : "..."
        font.pixelSize: 20
        font.bold: true
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
            model: startPage.folderData && startPage.folderData.children ? startPage.folderData.children : []

            delegate: Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true

                visible: index >= startPage.currentPage * grid.cardsPerPage &&
                         index < (startPage.currentPage + 1) * grid.cardsPerPage

                radius: 10
                color: modelData.type === "directory" ? "#e3f2fd" : "#f0f0f0"
                border.color: "#ddd"

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

                            startPage.StackView.view.push("main.qml", {
                                "folderData": modelData
                            })
                        } else {
                            if (modelData.path) {
                                var urlPath = "file:///" + modelData.path.replace(/\\/g, "/")

                                startPage.StackView.view.push("../MultiMediaPlayer/main.qml", {
                                    "mediaSource": urlPath
                                })
                                console.log("File:", modelData.name)
                            } else {
                                console.error("Fehler: Kein Pfad für Datei gefunden!", modelData.name)
                            }
                        }
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent
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
                        Layout.maximumWidth: parent.width
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
            onClicked: startPage.currentPage--
            HoverHandler { cursorShape: Qt.PointingHandCursor }
        }

        Text {
            id: pageIndicator
            property int totalItems: startPage.folderData && startPage.folderData.children
                                     ? startPage.folderData.children.length : 0
            text: (startPage.currentPage + 1) + " / " + Math.max(1, Math.ceil(totalItems / grid.cardsPerPage))
            color: "#ffffffff"
            font.pixelSize: 16
            font.bold: true

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    tts.say("Seite " + (startPage.currentPage + 1) + " von " +
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
            onClicked: startPage.currentPage++
            HoverHandler { cursorShape: Qt.PointingHandCursor }
        }
    }
}
