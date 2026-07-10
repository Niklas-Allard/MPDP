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
                text: "Karten-Mindestbreite"
                Layout.preferredWidth: 220
                ToolTip {
                    visible: ttHost1Hover.hovered
                    delay: 500
                    text: "Minimale Breite jeder Kachel im Dateibrowser.\nKleinere Werte = mehr Kacheln nebeneinander, größere Werte = weniger, aber breitere Kacheln."
                }
            }
            Slider {
                id: cardWidthSlider
                Layout.fillWidth: true
                from: 100; to: 400; stepSize: 10
                value: settingsManager.cardMinWidth
                onMoved: settingsManager.cardMinWidth = value
            }
            Label { text: Math.round(cardWidthSlider.value) + " px"; Layout.preferredWidth: 70 }
        }

        RowLayout {
            Layout.fillWidth: true
            Label {
                id: ttHost2
                HoverHandler { id: ttHost2Hover }
                text: "Karten-Mindesthöhe"
                Layout.preferredWidth: 220
                ToolTip {
                    visible: ttHost2Hover.hovered
                    delay: 500
                    text: "Minimale Höhe jeder Kachel im Dateibrowser.\nKleinere Werte = mehr Kacheln untereinander, größere Werte = weniger, aber höhere Kacheln."
                }
            }
            Slider {
                id: cardHeightSlider
                Layout.fillWidth: true
                from: 100; to: 400; stepSize: 10
                value: settingsManager.cardMinHeight
                onMoved: settingsManager.cardMinHeight = value
            }
            Label { text: Math.round(cardHeightSlider.value) + " px"; Layout.preferredWidth: 70 }
        }

        RowLayout {
            Layout.fillWidth: true
            Label {
                id: ttHost3
                HoverHandler { id: ttHost3Hover }
                text: "Schriftgröße"
                Layout.preferredWidth: 220
                ToolTip {
                    visible: ttHost3Hover.hovered
                    delay: 500
                    text: "Skalierungsfaktor für alle Texte in der App.\n1,0 = Normalgröße · 1,5 = 50 % größer · 2,0 = doppelt so groß.\nEmpfohlen für sehbeeinträchtigte Nutzer: 1,3–1,8."
                }
            }
            Slider {
                id: fontScaleSlider
                Layout.fillWidth: true
                from: 0.8; to: 2.0; stepSize: 0.1
                value: settingsManager.fontScale
                onMoved: settingsManager.fontScale = value
            }
            Label { text: fontScaleSlider.value.toFixed(1) + "×"; Layout.preferredWidth: 70 }
        }

        RowLayout {
            Layout.fillWidth: true
            Label {
                id: ttHost4
                HoverHandler { id: ttHost4Hover }
                text: "Farbschema"
                Layout.preferredWidth: 220
                ToolTip {
                    visible: ttHost4Hover.hovered
                    delay: 500
                    text: "Farbdesign der gesamten Anwendung.\n• Hell: weißer Hintergrund für helle Umgebungen\n• Dunkel: dunkler Hintergrund, augenschonend bei wenig Licht\n• Hoher Kontrast: maximaler Kontrast für sehbeeinträchtigte Nutzer"
                }
            }
            ComboBox {
                id: themeCombo
                Layout.fillWidth: true
                textRole: "label"
                valueRole: "value"
                model: [
                    { label: "Hell",           value: "light" },
                    { label: "Dunkel",         value: "dark" },
                    { label: "Hoher Kontrast", value: "highContrast" }
                ]
                Component.onCompleted: currentIndex = indexOfValue(settingsManager.theme)
                onActivated: settingsManager.theme = currentValue
            }
        }

        Connections {
            target: settingsManager
            function onThemeChanged() {
                themeCombo.currentIndex = themeCombo.indexOfValue(settingsManager.theme)
            }
        }

        Item { Layout.fillHeight: true }
    }
}
