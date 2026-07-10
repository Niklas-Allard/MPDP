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
                id: ttHost1
                HoverHandler { id: ttHost1Hover }
                text: "Vorlesen auslösen mit"
                Layout.preferredWidth: 220
                ToolTip {
                    visible: ttHost1Hover.hovered
                    delay: 500
                    text: "Legt fest, wie eine Kachel ausgewählt werden muss,\ndamit ihr Name von der Sprachausgabe vorgelesen wird.\n• Hover: Maus über der Kachel halten\n• Einfachklick: einmal klicken\n• Doppelklick: doppelt klicken"
                }
            }
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
            Label {
                id: ttHost2
                HoverHandler { id: ttHost2Hover }
                text: "Öffnen/Navigieren mit"
                Layout.preferredWidth: 220
                ToolTip {
                    visible: ttHost2Hover.hovered
                    delay: 500
                    text: "Legt fest, wie eine Kachel aktiviert wird,\num eine Datei abzuspielen oder in einen Ordner zu navigieren.\n• Hover: Maus über der Kachel halten\n• Einfachklick: einmal klicken\n• Doppelklick: doppelt klicken"
                }
            }
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
            Label {
                id: ttHost3
                HoverHandler { id: ttHost3Hover }
                text: "Hover-Verzögerung"
                Layout.preferredWidth: 220
                ToolTip {
                    visible: ttHost3Hover.hovered
                    delay: 500
                    text: "Zeit, die die Maus regungslos über einer Kachel bleiben muss,\nbevor die Hover-Aktion (Vorlesen oder Öffnen) ausgelöst wird.\nNur relevant wenn 'Hover' als Auslöser gewählt ist.\nKürzere Werte reagieren schneller, lange Werte verhindern versehentliche Auslösung."
                }
            }
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
            Label {
                id: ttHost4
                HoverHandler { id: ttHost4Hover }
                text: "Versteckte Dateien zeigen"
                Layout.preferredWidth: 220
                ToolTip {
                    visible: ttHost4Hover.hovered
                    delay: 500
                    text: "Zeigt auch Dateien und Ordner an, die als versteckt markiert sind\n(z. B. Dateien mit führendem Punkt oder Windows-Hidden-Attribut).\nNormalerweise sind solche Dateien unsichtbar."
                }
            }
            Switch {
                checked: settingsManager.showHiddenFiles
                onToggled: settingsManager.showHiddenFiles = checked
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Label {
                id: ttHost5
                HoverHandler { id: ttHost5Hover }
                text: "Deaktivierte Blättern-Buttons ausblenden"
                Layout.preferredWidth: 220
                ToolTip {
                    visible: ttHost5Hover.hovered
                    delay: 500
                    text: "Blendet die Vor-/Zurück-Blättern-Buttons vollständig aus,\nwenn kein weiteres Blättern möglich ist (erste oder letzte Seite).\nWenn deaktiviert, werden die Buttons nur ausgegraut angezeigt."
                }
            }
            Switch {
                checked: settingsManager.hideDisabledNavButtons
                onToggled: settingsManager.hideDisabledNavButtons = checked
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Label {
                id: ttHost6
                HoverHandler { id: ttHost6Hover }
                text: "Shuffle-Button außerhalb von Serien komplett ausblenden"
                Layout.preferredWidth: 220
                ToolTip {
                    visible: ttHost6Hover.hovered
                    delay: 500
                    text: "Versteckt den Shuffle-Button in Ordnern, die nicht als Serienordner\nkonfiguriert sind (Tab 'Shuffle').\nWenn deaktiviert, wird der Button in normalen Ordnern ausgegraut angezeigt."
                }
            }
            Switch {
                checked: settingsManager.hideShuffleButton
                onToggled: settingsManager.hideShuffleButton = checked
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Label {
                id: ttHost7
                HoverHandler { id: ttHost7Hover }
                text: "Sortierung"
                Layout.preferredWidth: 220
                ToolTip {
                    visible: ttHost7Hover.hovered
                    delay: 500
                    text: "Reihenfolge, in der Dateien und Ordner im Dateibrowser angezeigt werden.\n• Name A→Z / Z→A: alphabetisch\n• Datum (neu zuerst): zuletzt geänderte Dateien oben\n• Größe (groß zuerst): größte Dateien oben"
                }
            }
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
