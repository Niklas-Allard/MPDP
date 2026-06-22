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
            Label { text: "Vorlesen auslösen mit"; Layout.preferredWidth: 220 }
            ComboBox {
                id: speakTriggerCombo
                Layout.fillWidth: true
                textRole: "label"
                valueRole: "value"
                model: [
                    { label: "Hover",        value: "hover" },
                    { label: "Einfachklick", value: "singleClick" },
                    { label: "Doppelklick",  value: "doubleClick" }
                ]
                Component.onCompleted: currentIndex = indexOfValue(settingsManager.speakTrigger)
                onActivated: settingsManager.speakTrigger = currentValue
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Label { text: "Öffnen/Navigieren mit"; Layout.preferredWidth: 220 }
            ComboBox {
                id: openTriggerCombo
                Layout.fillWidth: true
                textRole: "label"
                valueRole: "value"
                model: [
                    { label: "Hover",        value: "hover" },
                    { label: "Einfachklick", value: "singleClick" },
                    { label: "Doppelklick",  value: "doubleClick" }
                ]
                Component.onCompleted: currentIndex = indexOfValue(settingsManager.openTrigger)
                onActivated: settingsManager.openTrigger = currentValue
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Label { text: "Hover-Verzögerung"; Layout.preferredWidth: 220 }
            Slider {
                id: hoverDelaySlider
                Layout.fillWidth: true
                enabled: settingsManager.speakTrigger === "hover" || settingsManager.openTrigger === "hover"
                from: 200; to: 10000; stepSize: 100
                value: settingsManager.hoverDelay
                onMoved: settingsManager.hoverDelay = value
            }
            Label {
                text: (hoverDelaySlider.value / 1000).toFixed(1) + " s"
                Layout.preferredWidth: 70
                opacity: hoverDelaySlider.enabled ? 1.0 : 0.5
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Label { text: "Versteckte Dateien zeigen"; Layout.preferredWidth: 220 }
            Switch {
                checked: settingsManager.showHiddenFiles
                onToggled: settingsManager.showHiddenFiles = checked
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Label { text: "Deaktivierte Blättern-Buttons ausblenden"; Layout.preferredWidth: 220 }
            Switch {
                checked: settingsManager.hideDisabledNavButtons
                onToggled: settingsManager.hideDisabledNavButtons = checked
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Label { text: "Shuffle-Button außerhalb von Serien komplett ausblenden"; Layout.preferredWidth: 220 }
            Switch {
                checked: settingsManager.hideShuffleButton
                onToggled: settingsManager.hideShuffleButton = checked
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Label { text: "Sortierung"; Layout.preferredWidth: 220 }
            ComboBox {
                id: sortCombo
                Layout.fillWidth: true
                textRole: "label"
                valueRole: "value"
                model: [
                    { label: "Name (A → Z)",       value: "name_asc"  },
                    { label: "Name (Z → A)",       value: "name_desc" },
                    { label: "Datum (neu zuerst)", value: "date_desc" },
                    { label: "Größe (groß zuerst)", value: "size_desc" }
                ]
                Component.onCompleted: currentIndex = indexOfValue(settingsManager.sortOrder)
                onActivated: settingsManager.sortOrder = currentValue
            }
        }

        Connections {
            target: settingsManager
            function onSpeakTriggerChanged() {
                speakTriggerCombo.currentIndex = speakTriggerCombo.indexOfValue(settingsManager.speakTrigger)
            }
            function onOpenTriggerChanged() {
                openTriggerCombo.currentIndex = openTriggerCombo.indexOfValue(settingsManager.openTrigger)
            }
            function onSortOrderChanged() {
                sortCombo.currentIndex = sortCombo.indexOfValue(settingsManager.sortOrder)
            }
        }

        Item { Layout.fillHeight: true }
    }
}
