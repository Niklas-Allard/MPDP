import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: root

    // Wird beim Pushen aus dem FileBrowser gesetzt
    property string searchQuery: ""
    property string targetFilename: ""

    property var searchResults: []
    property bool busy: false

    Component.onCompleted: {
        if (searchQuery)    searchField.text  = searchQuery
        if (targetFilename) saveAsField.text  = targetFilename
        if (!tmdbManager.has_api_key()) {
            statusText.text = "Kein API-Key gesetzt. Bitte unter Einstellungen → TMDB konfigurieren."
        }
    }

    Connections {
        target: tmdbManager

        function onSearch_results_ready(results) {
            root.searchResults = results
            root.busy = false
        }

        function onDownload_finished(path) {
            root.busy = false
        }

        function onDownload_error(msg) {
            root.busy = false
            statusText.text = "Fehler: " + msg
        }

        function onStatus_changed(msg) {
            statusText.text = msg
        }
    }

    function doSearch() {
        var q = searchField.text.trim()
        if (!q) return
        root.busy = true
        root.searchResults = []
        var types = ["movie", "tv", "multi"]
        tmdbManager.search(q, types[mediaTypeCombo.currentIndex])
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        // ── Kopfzeile ──────────────────────────────────────────────────────
        Text {
            text: "TMDB Poster suchen"
            font.pixelSize: 22 * settingsManager.fontScale
            font.bold: true
            color: settingsManager.colorText
            Layout.alignment: Qt.AlignHCenter
        }

        // ── Suchzeile ──────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            TextField {
                id: searchField
                Layout.fillWidth: true
                placeholderText: "Titel suchen…"
                font.pixelSize: 15 * settingsManager.fontScale
                onAccepted: root.doSearch()
            }

            ComboBox {
                id: mediaTypeCombo
                model: ["Filme", "Serien", "Beides"]
                font.pixelSize: 14 * settingsManager.fontScale
                implicitWidth: 110
            }

            Button {
                text: "Suchen"
                font.pixelSize: 14 * settingsManager.fontScale
                enabled: !root.busy && searchField.text.trim().length > 0
                onClicked: root.doSearch()
                HoverHandler { cursorShape: Qt.PointingHandCursor }
            }
        }

        // ── Speichern-als-Zeile ────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Label {
                text: "Speichern als:"
                color: settingsManager.colorText
                font.pixelSize: 14 * settingsManager.fontScale
            }

            TextField {
                id: saveAsField
                Layout.fillWidth: true
                placeholderText: "Dateiname (ohne .jpg)"
                font.pixelSize: 14 * settingsManager.fontScale
            }

            Label {
                text: ".jpg"
                color: settingsManager.colorText
                opacity: 0.6
                font.pixelSize: 14 * settingsManager.fontScale
            }
        }

        // ── Status ─────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            BusyIndicator {
                running: root.busy
                visible: root.busy
                width: 20
                height: 20
            }

            Text {
                id: statusText
                text: ""
                color: settingsManager.colorText
                font.pixelSize: 13 * settingsManager.fontScale
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }

        // ── Ergebnisse ─────────────────────────────────────────────────────
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            GridView {
                id: resultsGrid
                width: parent.width
                model: root.searchResults

                readonly property int cols: Math.max(2, Math.floor(width / 200))
                cellWidth:  Math.floor(width / cols)
                cellHeight: cellWidth * 1.9

                delegate: Item {
                    width:  resultsGrid.cellWidth
                    height: resultsGrid.cellHeight

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 6
                        radius: 8
                        color: settingsManager.colorCardFile
                        border.color: settingsManager.colorCardBorder
                        clip: true

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 0

                            // Poster-Bild
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: parent.height * 0.68
                                color: settingsManager.colorCardDirectory
                                clip: true

                                Image {
                                    anchors.fill: parent
                                    source: modelData.poster_path
                                        ? tmdbManager.poster_preview_url(modelData.poster_path)
                                        : ""
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true

                                    // Platzhalter solange das Bild lädt
                                    Rectangle {
                                        anchors.fill: parent
                                        color: settingsManager.colorCardDirectory
                                        visible: parent.status !== Image.Ready
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.media_type === "movie" ? "🎬" : "📺"
                                            font.pixelSize: 36
                                        }
                                    }
                                }
                            }

                            // Titel + Jahr
                            Text {
                                text: modelData.title + (modelData.year ? " (" + modelData.year + ")" : "")
                                color: settingsManager.colorCardText
                                font.pixelSize: 12 * settingsManager.fontScale
                                font.bold: true
                                wrapMode: Text.WordWrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                                Layout.topMargin: 6
                                Layout.leftMargin: 6
                                Layout.rightMargin: 6
                            }

                            // Typ-Badge
                            Text {
                                text: modelData.media_type === "movie" ? "Film" : "Serie"
                                color: settingsManager.colorAccent
                                font.pixelSize: 11 * settingsManager.fontScale
                                Layout.leftMargin: 6
                            }

                            Item { Layout.fillHeight: true }

                            // Download-Button
                            Button {
                                text: "Herunterladen"
                                font.pixelSize: 12 * settingsManager.fontScale
                                Layout.fillWidth: true
                                Layout.leftMargin: 6
                                Layout.rightMargin: 6
                                Layout.bottomMargin: 6
                                enabled: !root.busy && saveAsField.text.trim().length > 0
                                onClicked: {
                                    root.busy = true
                                    tmdbManager.download_poster(
                                        modelData.id,
                                        modelData.media_type,
                                        saveAsField.text.trim()
                                    )
                                }
                                HoverHandler { cursorShape: Qt.PointingHandCursor }
                            }
                        }
                    }
                }
            }
        }

        // ── Fußzeile ───────────────────────────────────────────────────────
        Button {
            text: "Zurück"
            font.pixelSize: 14 * settingsManager.fontScale
            onClicked: root.StackView.view.pop()
            HoverHandler { cursorShape: Qt.PointingHandCursor }
        }
    }
}