import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: startPage
    property int minCardWidth: 150
    property int minCardHeight: 150
    property int currentPage: 0

    Item {
        anchors.fill: parent
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        Text {
            text: "This is the File Browser Page"
            font.pixelSize: 24
        }
        Button {
            text: "Go to Start Page"
            anchors.top: parent.top
            anchors.topMargin: 50
            anchors.horizontalCenter: parent.horizontalCenter
            onClicked: {
                startPage.StackView.view.push("../FileBrowser/main.qml", {
                    "folderData": folderData
                }) 
            }
        }
    }
}
