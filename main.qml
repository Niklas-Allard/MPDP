import QtQuick
import QtQuick.Window
import QtQuick.Controls

ApplicationWindow {
    visible: true
    width: 800; height: 600
    title: "MPDP"

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: "StartPage/main.qml"
    }
}