import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: fileBrowserPage
    property int minCardWidth: 150
    property int minCardHeight: 150
    property int currentPage: 0

    GridLayout {
        id: grid
        anchors.fill: parent
        anchors.margins: 10
        anchors.bottomMargin: 60
        columns: Math.max(1, Math.floor(width / minCardWidth))
        rows: Math.max(1, Math.floor(height / minCardHeight))
        property int cardsPerPage: columns * rows

        Repeater {
            model: myModel
            delegate: Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.maximumHeight: 250
                visible: index >= fileBrowserPage.currentPage * grid.cardsPerPage && 
                         index < (fileBrowserPage.currentPage + 1) * grid.cardsPerPage
                
                radius: 10
                color: "#f0f0f0"
                border.color: "#ddd"
                border.width: 1
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    
                    Image {
                        Layout.fillWidth: true
                        Layout.fillHeight: true 
                        Layout.maximumHeight: 200
                        Layout.preferredHeight: 180
                        source: model.image
                        fillMode: Image.PreserveAspectCrop
                    }
                    
                    Text {
                        Layout.fillWidth: true
                        text: model.title
                        wrapMode: Text.WordWrap
                        font.pixelSize: 14
                        font.bold: true
                    }
                }
            }
        }
    }

    RowLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.margins: 10

        Button {
            text: "Vorherige"
            enabled: fileBrowserPage.currentPage > 0
            onClicked: fileBrowserPage.currentPage--
        }

        Text {
            text: (fileBrowserPage.currentPage + 1) + " / " + 
                  Math.ceil(myModel.rowCount() / grid.cardsPerPage)
        }

        Button {
            text: "Nächste"
            enabled: fileBrowserPage.currentPage < Math.ceil(myModel.rowCount() / grid.cardsPerPage) - 1
            onClicked: fileBrowserPage.currentPage++
        }
    }
}
