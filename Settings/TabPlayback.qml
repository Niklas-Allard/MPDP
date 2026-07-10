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
            Label {
                text: "Standardlautstärke"
                Layout.preferredWidth: 220
                ToolTip.visible: hovered
                ToolTip.delay: 500
                ToolTip.text: "Lautstärke beim Öffnen einer Mediendatei.\n0 % = stumm · 100 % = volle Systemlautstärke.\nDie Lautstärke kann jederzeit im Player angepasst werden."
            }
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
            Label {
                text: "Wiedergabe fortsetzen"
                Layout.preferredWidth: 220
                ToolTip.visible: hovered
                ToolTip.delay: 500
                ToolTip.text: "Setzt ein Video automatisch an der zuletzt gestoppten Stelle fort,\nanstatt von vorne zu beginnen.\nDie gespeicherte Position wird in der Datenbank gespeichert."
            }
            Switch {
                checked: settingsManager.resumePlayback
                onToggled: settingsManager.resumePlayback = checked
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Label {
                text: "Cursor ausblenden nach"
                Layout.preferredWidth: 220
                ToolTip.visible: hovered
                ToolTip.delay: 500
                ToolTip.text: "Zeit ohne Mausbewegung im Player, nach der der Mauszeiger\nautomatisch ausgeblendet wird.\nBei der nächsten Mausbewegung erscheint er wieder."
            }
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
            Label {
                text: "Video sofort abspielen"
                Layout.preferredWidth: 220
                ToolTip.visible: hovered
                ToolTip.delay: 500
                ToolTip.text: "Startet die Wiedergabe automatisch, sobald eine Mediendatei geöffnet wird.\nWenn deaktiviert, muss die Wiedergabe manuell über den Play-Button gestartet werden."
            }
            Switch {
                checked: settingsManager.autoPlayOnOpen
                onToggled: settingsManager.autoPlayOnOpen = checked
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Label {
                text: "Nächste Datei automatisch"
                Layout.preferredWidth: 220
                ToolTip.visible: hovered
                ToolTip.delay: 500
                ToolTip.text: "Spielt nach dem Ende einer Datei automatisch die nächste Datei\nim selben Ordner ab (Playlist-Modus).\nDie Reihenfolge richtet sich nach der gewählten Sortierung."
            }
            Switch {
                checked: settingsManager.autoPlayNext
                onToggled: settingsManager.autoPlayNext = checked
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Label {
                text: "Nächste Folge ansagen"
                Layout.preferredWidth: 220
                ToolTip.visible: hovered
                ToolTip.delay: 500
                ToolTip.text: "Liest den Dateinamen der nächsten Datei vor, bevor sie automatisch startet.\nNur verfügbar wenn 'Nächste Datei automatisch' UND die Sprachausgabe aktiv sind."
            }
            Switch {
                enabled: settingsManager.autoPlayNext && settingsManager.ttsEnabled
                checked: settingsManager.announceNextFile
                onToggled: settingsManager.announceNextFile = checked
            }
        }

        Item { Layout.fillHeight: true }
    }
}
