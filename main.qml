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
}
