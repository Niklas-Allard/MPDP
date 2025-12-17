import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: root
    
    // WICHTIG: Hier kommen die Daten für DIESE Seite rein
    property var folderData: null 

    property int minCardWidth: 150
    property int minCardHeight: 150
    property int currentPage: 0

    // Header mit aktuellem Pfad/Namen
    Text {
        id: headerText
        text: root.folderData ? root.folderData.name : "..."
        font.pixelSize: 20
        font.bold: true
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 10
    }

    GridLayout {
        id: grid
        anchors.top: headerText.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 10
        anchors.bottomMargin: 60
        
        columns: Math.max(1, Math.floor(width / minCardWidth))
        rows: Math.max(1, Math.floor(height / minCardHeight))
        property int cardsPerPage: columns * rows

        Repeater {
            // WICHTIG: Wir nutzen root.folderData.children
            model: root.folderData && root.folderData.children ? root.folderData.children : []
            
            delegate: Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                visible: index >= root.currentPage * grid.cardsPerPage && 
                         index < (root.currentPage + 1) * grid.cardsPerPage
                
                radius: 10
                color: modelData.type === "directory" ? "#e3f2fd" : "#f0f0f0"
                border.color: "#ddd"
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (modelData.type === "directory") {
                            console.log("Opened Directory", modelData.name)
                            
                            root.StackView.view.push("main.qml", {
                                "folderData": modelData
                            })
                        } else {
                            console.log("File:", modelData.name)
                        }
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    Text {
                        text: modelData.type === "directory" ? "📁" : "📄"
                        font.pixelSize: 40
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Text {
                        text: modelData.name
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                        elide: Text.ElideRight
                        Layout.maximumWidth: parent.width
                    }
                }
            }
        }
    }

    RowLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.margins: 10

        // Zurück-Button für Navigation (Wichtig!)
        Button {
            text: "Zurück"
            onClicked: root.StackView.view.pop()
        }

        // Pagination Buttons
        Button {
            text: "<"
            enabled: root.currentPage > 0
            onClicked: root.currentPage--
        }

        Text {
            property int totalItems: root.folderData && root.folderData.children ? root.folderData.children.length : 0
            text: (root.currentPage + 1) + " / " + Math.max(1, Math.ceil(totalItems / grid.cardsPerPage))
        }

        Button {
            text: ">"
            property int totalItems: root.folderData && root.folderData.children ? root.folderData.children.length : 0
            enabled: root.currentPage < Math.ceil(totalItems / grid.cardsPerPage) - 1
            onClicked: root.currentPage++
        }
    }
}
