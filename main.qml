import QtQuick
import QtQuick.Controls

ApplicationWindow {
    id: window
    width: 800
    height: 600
    visible: true
    title: "File Browser"

    StackView {
        id: stack
        anchors.fill: parent
        
        initialItem: null 

        Component.onCompleted: {
            stack.push("StartPage/main.qml")
        }
    }
}
