import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material

ApplicationWindow {
    id: window
    width: 800
    height: 600
    visible: true
    title: "File Browser"

    // Zentrales Farbschema (aus den Einstellungen). Der Material-Stil themt damit
    // Buttons, ComboBoxen, ausgewählte Einträge usw. konsistent (inkl. Dark Mode).
    Material.theme: settingsManager.theme === "light" ? Material.Light : Material.Dark
    Material.background: settingsManager.colorBackground
    Material.foreground: settingsManager.colorText
    Material.accent: settingsManager.colorAccent

    // palette zusätzlich für reine Text-Elemente / Stil-Fallbacks
    color: settingsManager.colorBackground
    palette.window: settingsManager.colorBackground
    palette.windowText: settingsManager.colorText
    palette.base: settingsManager.colorBase
    palette.text: settingsManager.colorText
    palette.button: settingsManager.colorButton
    palette.buttonText: settingsManager.colorText
    palette.highlight: settingsManager.colorAccent
    palette.highlightedText: settingsManager.colorBackground
    palette.mid: settingsManager.colorCardBorder
    palette.placeholderText: settingsManager.colorText

    Image { source: "qrc:/icons/arrow_forward.png"; width: 32; height: 32 }

    // ---- Bildschirmschoner --------------------------------------------------

    Timer {
        id: idleTimer
        interval: settingsManager.screensaverTimeout
        repeat: false
        onTriggered: {
            if (!settingsManager.screensaverEnabled) return
            // Nicht aktivieren wenn Medien gerade abspielen
            var current = stack.currentItem
            if (current && current.isPlaying) {
                idleTimer.restart()
                return
            }
            screensaverLoader.active = true
        }
    }

    // Aktivität (Maus/Taste) → Bildschirmschoner beenden + Timer zurücksetzen
    Connections {
        target: activityMonitor
        function onActivity_detected() {
            if (screensaverLoader.active) {
                screensaverLoader.active = false
            }
            if (settingsManager.screensaverEnabled) {
                idleTimer.restart()
            } else {
                idleTimer.stop()
            }
        }
    }

    // Wenn Bildschirmschoner aktiviert/deaktiviert wird oder Timeout sich ändert
    Connections {
        target: settingsManager
        function onScreensaverEnabledChanged() {
            if (settingsManager.screensaverEnabled) {
                idleTimer.restart()
            } else {
                idleTimer.stop()
                screensaverLoader.active = false
            }
        }
        function onScreensaverTimeoutChanged() {
            idleTimer.interval = settingsManager.screensaverTimeout
            if (settingsManager.screensaverEnabled) {
                idleTimer.restart()
            }
        }
    }

    // Bildschirmschoner-Overlay (höchste Z-Ebene)
    Loader {
        id: screensaverLoader
        anchors.fill: parent
        z: 9999
        active: false
        source: active ? "Screensaver/main.qml" : ""
    }

    Component.onCompleted: {
        if (settingsManager.screensaverEnabled) {
            idleTimer.start()
        }
    }

    StackView {
        id: stack
        anchors.fill: parent

        initialItem: null

        Component.onCompleted: {
            stack.push("StartPage/main.qml")
            var win = Window.window
            if (win) win.showFullScreen()
        }
    }

    // AltGr + S öffnet die Einstellungen.
    // Hinweis: Windows liefert AltGr als Ctrl+Alt, daher die Sequenz "Ctrl+Alt+S".
    Shortcut {
        sequences: ["Ctrl+Alt+S"]
        context: Qt.ApplicationShortcut
        onActivated: {
            // Mehrfaches Pushen vermeiden
            var current = stack.currentItem
            if (!current || String(current.objectName) !== "settingsPage") {
                stack.push("Settings/main.qml")
            }
        }
    }
}