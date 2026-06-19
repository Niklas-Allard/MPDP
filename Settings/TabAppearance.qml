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
            Label { text: "Karten-Mindestbreite"; Layout.preferredWidth: 220 }
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
            Label { text: "Karten-Mindesthöhe"; Layout.preferredWidth: 220 }
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
            Label { text: "Schriftgröße"; Layout.preferredWidth: 220 }
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
            Label { text: "Farbschema"; Layout.preferredWidth: 220 }
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
