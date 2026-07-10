import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs

ScrollView {
    clip: true
    contentWidth: availableWidth

    FolderDialog {
        id: ssDirDialog
        title: "Bildschirmschoner-Bilderordner auswählen"
        onAccepted: {
            var url = ssDirDialog.selectedFolder.toString()
            var localPath = url.replace(/^file:\/{2,3}/, "")
            ssDirField.text = decodeURIComponent(localPath)
            settingsManager.screensaverImageDirectory = ssDirField.text
        }
    }

    Connections {
        target: settingsManager
        function onScreensaverImageDirectoryChanged() {
            ssDirField.text = settingsManager.screensaverImageDirectory
        }
    }

    ColumnLayout {
        width: parent.availableWidth
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            Label {
                id: ttHost1
                HoverHandler { id: ttHost1Hover }
                text: "Bildschirmschoner aktiv"
                Layout.preferredWidth: 220
                ToolTip {
                    visible: ttHost1Hover.hovered
                    delay: 500
                    text: "Aktiviert den integrierten Bildschirmschoner.\nBei Inaktivität (kein Klick, keine Mausbewegung) werden Bilder\naus dem eingestellten Ordner im Vollbild angezeigt.\nEin Klick oder eine Mausbewegung beendet den Bildschirmschoner."
                }
            }
            Switch {
                checked: settingsManager.screensaverEnabled
                onToggled: settingsManager.screensaverEnabled = checked
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Label {
                id: ttHost2
                HoverHandler { id: ttHost2Hover }
                text: "Wartezeit bis Aktivierung"
                Layout.preferredWidth: 220
                ToolTip {
                    visible: ttHost2Hover.hovered
                    delay: 500
                    text: "Zeit der Inaktivität, nach der der Bildschirmschoner automatisch startet.\nKurze Wartezeit: Bildschirmschoner startet schnell bei Pause.\nLange Wartezeit: Nur bei längerer Untätigkeit."
                }
            }
            Slider {
                id: ssTimeoutSlider
                Layout.fillWidth: true
                enabled: settingsManager.screensaverEnabled
                from: 30000; to: 1800000; stepSize: 30000
                value: settingsManager.screensaverTimeout
                onMoved: settingsManager.screensaverTimeout = value
            }
            Label {
                text: {
                    var sec = Math.round(ssTimeoutSlider.value / 1000)
                    return sec >= 60
                        ? Math.floor(sec / 60) + " min " + (sec % 60 > 0 ? sec % 60 + " s" : "")
                        : sec + " s"
                }
                Layout.preferredWidth: 80
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Label {
                id: ttHost3
                HoverHandler { id: ttHost3Hover }
                text: "Anzeigedauer pro Bild"
                Layout.preferredWidth: 220
                ToolTip {
                    visible: ttHost3Hover.hovered
                    delay: 500
                    text: "Wie lange jedes Bild angezeigt wird, bevor zum nächsten gewechselt wird.\n1 s = schnelle Diashow · 10 s = ruhige Betrachtung · 60 s = sehr langsam.\nDie Bilder werden zufällig aus dem Bilderordner ausgewählt."
                }
            }
            Slider {
                id: ssIntervalSlider
                Layout.fillWidth: true
                enabled: settingsManager.screensaverEnabled
                from: 1000; to: 60000; stepSize: 1000
                value: settingsManager.screensaverImageInterval
                onMoved: settingsManager.screensaverImageInterval = value
            }
            Label {
                text: (ssIntervalSlider.value / 1000).toFixed(0) + " s"
                Layout.preferredWidth: 50
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Label {
                id: ttHost4
                HoverHandler { id: ttHost4Hover }
                text: "Bilderordner"
                Layout.preferredWidth: 220
                ToolTip {
                    visible: ttHost4Hover.hovered
                    delay: 500
                    text: "Ordner, aus dem der Bildschirmschoner zufällige Bilder lädt.\nUnterstützte Formate: JPG, PNG, BMP, GIF.\nAlle Bilder direkt im Ordner werden verwendet (keine Unterordner)."
                }
            }

            TextField {
                id: ssDirField
                Layout.fillWidth: true
                enabled: settingsManager.screensaverEnabled
                text: settingsManager.screensaverImageDirectory
                placeholderText: "z. B. C:/Bilder/Bildschirmschoner"
            }

            Button {
                id: ttHost5
                text: "Durchsuchen…"
                enabled: settingsManager.screensaverEnabled
                onClicked: ssDirDialog.open()
                ToolTip {
                    visible: ttHost5.hovered
                    delay: 500
                    text: "Ordner über den Datei-Dialog auswählen."
                }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
            }

            Button {
                id: ttHost6
                text: "Speichern"
                enabled: settingsManager.screensaverEnabled
                onClicked: settingsManager.screensaverImageDirectory = ssDirField.text
                ToolTip {
                    visible: ttHost6.hovered
                    delay: 500
                    text: "Den eingegebenen Pfad als Bilderordner speichern."
                }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
