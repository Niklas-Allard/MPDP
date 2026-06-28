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

        Item { Layout.fillHeight: true }
    }
}