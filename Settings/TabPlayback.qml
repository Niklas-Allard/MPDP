import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ScrollView {
    clip: true
    contentWidth: availableWidth

    ColumnLayout {
        width: parent.availableWidth
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            Label { text: "Standardlautstärke"; Layout.preferredWidth: 220 }
            Slider {
                id: defVolSlider
                Layout.fillWidth: true
                from: 0.0; to: 1.0; stepSize: 0.05
                value: settingsManager.defaultVolume
                onMoved: settingsManager.defaultVolume = value
            }
            Label { text: Math.round(defVolSlider.value * 100) + " %"; Layout.preferredWidth: 50 }
        }

        RowLayout {
            Layout.fillWidth: true
            Label { text: "Wiedergabe fortsetzen"; Layout.preferredWidth: 220 }
            Switch {
                checked: settingsManager.resumePlayback
                onToggled: settingsManager.resumePlayback = checked
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Label { text: "Cursor ausblenden nach"; Layout.preferredWidth: 220 }
            Slider {
                id: cursorSlider
                Layout.fillWidth: true
                from: 1000; to: 30000; stepSize: 500
                value: settingsManager.cursorHideTimeout
                onMoved: settingsManager.cursorHideTimeout = value
            }
            Label { text: (cursorSlider.value / 1000).toFixed(1) + " s"; Layout.preferredWidth: 70 }
        }

        RowLayout {
            Layout.fillWidth: true
            Label { text: "Video sofort abspielen"; Layout.preferredWidth: 220 }
            Switch {
                checked: settingsManager.autoPlayOnOpen
                onToggled: settingsManager.autoPlayOnOpen = checked
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Label { text: "Nächste Datei automatisch"; Layout.preferredWidth: 220 }
            Switch {
                checked: settingsManager.autoPlayNext
                onToggled: settingsManager.autoPlayNext = checked
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Label { text: "Nächste Folge ansagen"; Layout.preferredWidth: 220 }
            Switch {
                enabled: settingsManager.autoPlayNext && settingsManager.ttsEnabled
                checked: settingsManager.announceNextFile
                onToggled: settingsManager.announceNextFile = checked
            }
        }

        Item { Layout.fillHeight: true }
    }
}
