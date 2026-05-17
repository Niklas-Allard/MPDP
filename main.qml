import QtQuick
import QtQuick.Controls

ApplicationWindow {
    id: window
    width: 800
    height: 600
    visible: true
    title: "File Browser"

    Image { source: "qrc:/icons/arrow_forward.png"; width: 32; height: 32 }

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