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
            Label { text: "Bildschirmschoner aktiv"; Layout.preferredWidth: 220 }
            Switch {
                checked: settingsManager.screensaverEnabled
                onToggled: settingsManager.screensaverEnabled = checked
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Label { text: "Wartezeit bis Aktivierung"; Layout.preferredWidth: 220 }
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
            Label { text: "Anzeigedauer pro Bild"; Layout.preferredWidth: 220 }
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

            Label { text: "Bilderordner"; Layout.preferredWidth: 220 }

            TextField {
                id: ssDirField
                Layout.fillWidth: true
                enabled: settingsManager.screensaverEnabled
                text: settingsManager.screensaverImageDirectory
                placeholderText: "z. B. C:/Bilder/Bildschirmschoner"
            }

            Button {
                text: "Durchsuchen…"
                enabled: settingsManager.screensaverEnabled
                onClicked: ssDirDialog.open()
            }

            Button {
                text: "Speichern"
                enabled: settingsManager.screensaverEnabled
                onClicked: settingsManager.screensaverImageDirectory = ssDirField.text
            }
        }

        Item { Layout.fillHeight: true }
    }
}
