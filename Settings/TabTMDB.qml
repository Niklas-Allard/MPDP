import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ScrollView {
    id: root
    clip: true
    contentWidth: availableWidth

    property bool showKey: false
    property bool bulkRunning: false
    property real bulkProgress: 0.0
    property string bulkCurrent: ""
    property string bulkSummary: ""

    property bool   analyzing:     false
    property int    analysisTotal:  0
    property int    analysisFound:  0
    property var    missingList:    []
    property bool   analysisRun:    false   // wurde Analyse schon einmal ausgeführt?

    readonly property var posterSizeKeys: ["w92", "w154", "w185", "w342", "w500", "w780", "original"]
    readonly property var posterSizeLabels: [
        "w92  – sehr klein (~7 KB)",
        "w154 – klein     (~15 KB)",
        "w185 – klein     (~20 KB)",
        "w342 – mittel    (~50 KB)",
        "w500 – empfohlen (~90 KB)",
        "w780 – groß      (~200 KB)",
        "original – maximale Qualität"
    ]

    Component.onCompleted: {
        apiKeyField.text = tmdbManager.get_api_key()
        var idx = posterSizeKeys.indexOf(settingsManager.tmdbPosterQuality)
        qualityCombo.currentIndex = idx >= 0 ? idx : 4
    }

    Connections {
        target: tmdbManager

        function onStatus_changed(msg) { apiKeyStatus.text = msg }

        function onBulk_progress(current, total, name) {
            root.bulkRunning = true
            root.bulkProgress = total > 0 ? current / total : 0
            root.bulkCurrent = current + " / " + total + "  –  " + name
        }

        function onBulk_finished(downloaded, skipped, errors) {
            root.bulkRunning = false
            root.bulkProgress = 1.0
            root.bulkCurrent = ""
            root.bulkSummary =
                downloaded + " heruntergeladen,  " +
                skipped    + " übersprungen,  " +
                errors     + " nicht gefunden."
        }

        function onBulk_cancelled() {
            root.bulkRunning = false
            root.bulkCurrent = ""
            root.bulkSummary = "Abgebrochen."
        }

        function onAnalysis_ready(total, found, missing) {
            root.analyzing     = false
            root.analysisTotal = total
            root.analysisFound = found
            root.missingList   = missing
            root.analysisRun   = true
        }
    }

    ColumnLayout {
        width: parent.availableWidth
        spacing: 20

        // API-Key
        GroupBox {
            Layout.fillWidth: true
            title: "TMDB API-Key"

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                Label {
                    text: "Kostenlosen API-Key auf themoviedb.org/settings/api erstellen."
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    font.pixelSize: 13 * settingsManager.fontScale
                    color: settingsManager.colorText
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    TextField {
                        id: apiKeyField
                        Layout.fillWidth: true
                        placeholderText: "API-Key (v3 auth) eingeben…"
                        echoMode: root.showKey ? TextInput.Normal : TextInput.Password
                        font.pixelSize: 14 * settingsManager.fontScale
                        onAccepted: tmdbManager.save_api_key(text)
                    }

                    Button {
                        text: root.showKey ? "Verbergen" : "Anzeigen"
                        font.pixelSize: 13 * settingsManager.fontScale
                        onClicked: root.showKey = !root.showKey
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                    }

                    Button {
                        text: "Speichern"
                        font.pixelSize: 13 * settingsManager.fontScale
                        enabled: apiKeyField.text.length > 0
                        onClicked: tmdbManager.save_api_key(apiKeyField.text)
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                    }

                    Button {
                        text: "Löschen"
                        font.pixelSize: 13 * settingsManager.fontScale
                        visible: apiKeyField.text.length > 0
                        onClicked: {
                            apiKeyField.text = ""
                            tmdbManager.save_api_key("")
                        }
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                    }
                }

                Label {
                    id: apiKeyStatus
                    text: ""
                    color: settingsManager.colorAccent
                    font.pixelSize: 12 * settingsManager.fontScale
                }

                Label {
                    text: "Der API-Key wird sicher im Windows Credential Manager gespeichert."
                    color: settingsManager.colorText
                    opacity: 0.65
                    font.pixelSize: 12 * settingsManager.fontScale
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }

        // Poster-Qualität
        GroupBox {
            Layout.fillWidth: true
            title: "Poster-Qualität"

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                Label {
                    text: "Qualität der heruntergeladenen Poster. Höhere Qualität = größere Dateigröße."
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    font.pixelSize: 13 * settingsManager.fontScale
                    color: settingsManager.colorText
                }

                ComboBox {
                    id: qualityCombo
                    model: root.posterSizeLabels
                    font.pixelSize: 14 * settingsManager.fontScale
                    Layout.fillWidth: true
                    onActivated: {
                        settingsManager.tmdbPosterQuality = root.posterSizeKeys[currentIndex]
                    }
                }
            }
        }

        // Massen-Download
        GroupBox {
            Layout.fillWidth: true
            title: "Alle Poster auf einmal herunterladen"

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                Label {
                    text: "Durchsucht alle konfigurierten Hauptverzeichnisse und lädt für jeden " +
                          "Unterordner das erste TMDB-Ergebnis herunter. " +
                          "Ordner mit vorhandenem Poster werden übersprungen."
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    font.pixelSize: 13 * settingsManager.fontScale
                    color: settingsManager.colorText
                }

                Button {
                    text: root.bulkRunning ? "Abbrechen" : "Alle Poster herunterladen"
                    font.pixelSize: 14 * settingsManager.fontScale
                    enabled: tmdbManager.has_api_key()
                    ToolTip.text: tmdbManager.has_api_key()
                        ? ""
                        : "Bitte zuerst einen API-Key eingeben."
                    ToolTip.visible: !tmdbManager.has_api_key() && hovered
                    onClicked: {
                        if (root.bulkRunning) {
                            tmdbManager.cancel_bulk_download()
                        } else {
                            root.bulkSummary  = ""
                            root.bulkProgress = 0.0
                            root.bulkCurrent  = ""
                            root.bulkRunning  = true
                            tmdbManager.start_bulk_download()
                        }
                    }
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                }

                ProgressBar {
                    Layout.fillWidth: true
                    visible: root.bulkRunning || root.bulkProgress > 0
                    value: root.bulkProgress
                    // Unbestimmter Modus solange noch kein Fortschritt gemeldet
                    indeterminate: root.bulkRunning && root.bulkProgress === 0
                }

                Label {
                    visible: root.bulkCurrent.length > 0
                    text: root.bulkCurrent
                    color: settingsManager.colorText
                    font.pixelSize: 13 * settingsManager.fontScale
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Label {
                    visible: root.bulkSummary.length > 0
                    text: root.bulkSummary
                    color: settingsManager.colorAccent
                    font.pixelSize: 13 * settingsManager.fontScale
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }

        // Poster-Analyse
        GroupBox {
            Layout.fillWidth: true
            title: "Fehlende Poster analysieren"

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                Label {
                    text: "Zeigt an, welche Ordner in den Hauptverzeichnissen noch kein Poster haben."
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    font.pixelSize: 13 * settingsManager.fontScale
                    color: settingsManager.colorText
                }

                RowLayout {
                    spacing: 8

                    Button {
                        text: "Analyse starten"
                        font.pixelSize: 14 * settingsManager.fontScale
                        enabled: !root.analyzing && !root.bulkRunning
                        onClicked: {
                            root.analyzing   = true
                            root.analysisRun = false
                            root.missingList = []
                            tmdbManager.analyze_missing_posters()
                        }
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                    }

                    BusyIndicator {
                        running: root.analyzing
                        visible: root.analyzing
                        width: 24; height: 24
                    }
                }

                // Zusammenfassung
                Label {
                    visible: root.analysisRun
                    font.pixelSize: 14 * settingsManager.fontScale
                    font.bold: true
                    color: root.missingList.length === 0
                           ? settingsManager.colorAccent
                           : settingsManager.colorText
                    text: {
                        if (!root.analysisRun) return ""
                        var miss = root.missingList.length
                        if (miss === 0)
                            return "✓  Alle " + root.analysisTotal + " Ordner haben ein Poster."
                        return miss + " von " + root.analysisTotal +
                               " Ordnern haben kein Poster."
                    }
                    Layout.fillWidth: true
                }

                // Liste der fehlenden Ordner
                Rectangle {
                    visible: root.analysisRun && root.missingList.length > 0
                    Layout.fillWidth: true
                    height: Math.min(root.missingList.length, 8) * 32 + 2
                    color: settingsManager.colorBase
                    border.color: settingsManager.colorCardBorder
                    radius: 4
                    clip: true

                    ListView {
                        id: missingListView
                        anchors.fill: parent
                        model: root.missingList
                        clip: true

                        ScrollBar.vertical: ScrollBar {}

                        delegate: Rectangle {
                            width: missingListView.width
                            height: 32
                            color: index % 2 === 0
                                   ? "transparent"
                                   : Qt.rgba(0, 0, 0, settingsManager.theme === "dark" ? 0.15 : 0.04)

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 0

                                Label {
                                    text: modelData.name
                                    color: settingsManager.colorText
                                    font.pixelSize: 13 * settingsManager.fontScale
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Label {
                                    text: modelData.parent
                                    color: settingsManager.colorText
                                    opacity: 0.5
                                    font.pixelSize: 12 * settingsManager.fontScale
                                    Layout.preferredWidth: 100
                                    horizontalAlignment: Text.AlignRight
                                    elide: Text.ElideLeft
                                }
                            }
                        }
                    }
                }

                // Hinweis + Button zum direkten Herunterladen
                RowLayout {
                    visible: root.analysisRun && root.missingList.length > 0
                    spacing: 12

                    Label {
                        text: "Direkt alle fehlenden Poster herunterladen:"
                        color: settingsManager.colorText
                        font.pixelSize: 13 * settingsManager.fontScale
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }

                    Button {
                        text: root.bulkRunning ? "Läuft…" : "Herunterladen"
                        font.pixelSize: 13 * settingsManager.fontScale
                        enabled: !root.bulkRunning && !root.analyzing && tmdbManager.has_api_key()
                        onClicked: {
                            root.bulkSummary  = ""
                            root.bulkProgress = 0.0
                            root.bulkCurrent  = ""
                            root.bulkRunning  = true
                            tmdbManager.start_bulk_download()
                        }
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}