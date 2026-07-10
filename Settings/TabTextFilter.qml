import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ScrollView {
    id: root
    clip: true
    contentWidth: availableWidth

    property var rulesModel: []

    Component.onCompleted: rulesModel = regexFilter.get_rules()

    ColumnLayout {
        width: parent.availableWidth
        spacing: 8

        Label {
            id: ttHost1
            HoverHandler { id: ttHost1Hover }
            text: "Regeln werden der Reihe nach auf Datei-/Ordnernamen angewendet, bevor der Text gesprochen wird."
            wrapMode: Text.Wrap
            Layout.fillWidth: true
            color: settingsManager.colorText
            font.pixelSize: 12 * settingsManager.fontScale
            ToolTip {
                visible: ttHost1Hover.hovered
                delay: 500
                text: "Reguläre Ausdrücke (Regex) erlauben komplexe Suchmuster.\nBeispiele:\n• \\.[a-z]+$ → entfernt Dateiendungen (.mp4, .mkv, …)\n• ^\\[.*?\\]\\s* → entfernt führende Klammern wie '[HD] '\n• S\\d+E\\d+ → findet Staffel-/Folgenbezeichnungen wie S01E03\nRote Farbe im Muster-Feld = ungültiger regulärer Ausdruck."
            }
        }

        // Header
        RowLayout {
            Layout.fillWidth: true
            Label {
                id: ttHost2
                HoverHandler { id: ttHost2Hover }
                text: "Muster (Regex)"
                Layout.fillWidth: true
                font.bold: true
                ToolTip {
                    visible: ttHost2Hover.hovered
                    delay: 500
                    text: "Regulärer Ausdruck, der im Datei-/Ordnernamen gesucht wird.\nRot = ungültiges Muster. Groß-/Kleinschreibung wird ignoriert."
                }
            }
            Label {
                id: ttHost3
                HoverHandler { id: ttHost3Hover }
                text: "Ersetzung"
                Layout.fillWidth: true
                font.bold: true
                ToolTip {
                    visible: ttHost3Hover.hovered
                    delay: 500
                    text: "Text, durch den das gefundene Muster ersetzt wird.\nLeer lassen = gefundener Text wird einfach gelöscht."
                }
            }
            Item  { width: 170 }
        }

        // Existing rules
        Repeater {
            model: root.rulesModel

            delegate: RowLayout {
                Layout.fillWidth: true
                spacing: 6

                TextField {
                    id: patternField
                    Layout.fillWidth: true
                    text: modelData.pattern
                    placeholderText: "z. B. \\.[a-z]+$"
                    color: regexFilter.validate_pattern(text) ? settingsManager.colorText : "#cc0000"
                }

                TextField {
                    id: replacementField
                    Layout.fillWidth: true
                    text: modelData.replacement
                    placeholderText: "Ersetzung (leer = löschen)"
                }

                Button {
                    text: "Speichern"
                    width: 80
                    onClicked: {
                        regexFilter.update_rule(index, patternField.text, replacementField.text)
                        root.rulesModel = regexFilter.get_rules()
                    }
                }

                Button {
                    text: "Entfernen"
                    width: 80
                    onClicked: {
                        regexFilter.remove_rule(index)
                        root.rulesModel = regexFilter.get_rules()
                    }
                }
            }
        }

        // Add new rule
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            TextField {
                id: newPatternField
                Layout.fillWidth: true
                placeholderText: "Neues Muster (Regex)"
                color: text.length === 0 || regexFilter.validate_pattern(text)
                       ? settingsManager.colorText : "#cc0000"
            }

            TextField {
                id: newReplacementField
                Layout.fillWidth: true
                placeholderText: "Neue Ersetzung"
            }

            Button {
                text: "Hinzufügen"
                width: 80
                enabled: newPatternField.text.length > 0 && regexFilter.validate_pattern(newPatternField.text)
                onClicked: {
                    regexFilter.add_rule(newPatternField.text, newReplacementField.text)
                    root.rulesModel = regexFilter.get_rules()
                    newPatternField.text = ""
                    newReplacementField.text = ""
                }
            }
        }

        // Test field
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Label {
                id: ttHost4
                HoverHandler { id: ttHost4Hover }
                text: "Testtext:"
                Layout.preferredWidth: 80
                ToolTip {
                    visible: ttHost4Hover.hovered
                    delay: 500
                    text: "Gibt einen Beispielnamen ein, um das Ergebnis aller Filterregeln live zu sehen.\nDer Pfeil zeigt den Text nach Anwendung aller Regeln."
                }
            }

            TextField {
                id: regexTestInput
                Layout.fillWidth: true
                placeholderText: "Beispiel-Dateiname eingeben"
            }

            Label {
                text: "→ " + (regexTestInput.text.length > 0 ? regexFilter.apply(regexTestInput.text) : "")
                Layout.fillWidth: true
                color: settingsManager.colorText
                wrapMode: Text.Wrap
            }
        }

        Item { Layout.fillHeight: true }
    }
}
