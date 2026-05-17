import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs

Item {
    id: settingsPage
    objectName: "settingsPage"

    property var mainDirsModel: []

    function reloadFromSettings() {
        mainDirsModel = settingsManager.get_main_directories()
        imageDirField.text = settingsManager.get_global_image_directory()
    }

    Component.onCompleted: reloadFromSettings()

    Connections {
        target: settingsManager
        function onMain_directories_changed() { reloadFromSettings() }
        function onGlobal_image_directory_changed() { reloadFromSettings() }
    }

    // Header
    Text {
        id: headerText
        text: "Einstellungen"
        font.pixelSize: 24
        font.bold: true
        color: "white"
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 16
    }

    ScrollView {
        id: scroll
        anchors.top: headerText.bottom
        anchors.bottom: footer.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 16
        clip: true

        ColumnLayout {
            width: scroll.availableWidth
            spacing: 20

            // Global Image Directory
            GroupBox {
                Layout.fillWidth: true
                title: "Globales Bilderverzeichnis (Cover/Thumbnails)"

                RowLayout {
                    anchors.fill: parent
                    spacing: 8

                    TextField {
                        id: imageDirField
                        Layout.fillWidth: true
                        placeholderText: "z. B. D:/Covers"
                    }

                    Button {
                        text: "Durchsuchen…"
                        onClicked: imageDirDialog.open()
                    }

                    Button {
                        text: "Speichern"
                        onClicked: settingsManager.set_global_image_directory(imageDirField.text)
                    }
                }
            }

            // Main Directories
            GroupBox {
                Layout.fillWidth: true
                title: "Hauptverzeichnisse"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 8

                    Repeater {
                        model: settingsPage.mainDirsModel

                        delegate: RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            TextField {
                                id: nameField
                                Layout.preferredWidth: 160
                                text: modelData.name
                                placeholderText: "Name"
                            }

                            TextField {
                                id: pathField
                                Layout.fillWidth: true
                                text: modelData.path
                                placeholderText: "Pfad"
                            }

                            Button {
                                text: "Speichern"
                                onClicked: settingsManager.update_main_directory(index, nameField.text, pathField.text)
                            }

                            Button {
                                text: "Entfernen"
                                onClicked: settingsManager.remove_main_directory(index)
                            }
                        }
                    }

                    // Add new entry
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        TextField {
                            id: newNameField
                            Layout.preferredWidth: 160
                            placeholderText: "Neuer Name"
                        }

                        TextField {
                            id: newPathField
                            Layout.fillWidth: true
                            placeholderText: "Neuer Pfad"
                        }

                        Button {
                            text: "Hinzufügen"
                            enabled: newNameField.text.length > 0 && newPathField.text.length > 0
                            onClicked: {
                                settingsManager.add_main_directory(newNameField.text, newPathField.text)
                                newNameField.text = ""
                                newPathField.text = ""
                            }
                        }
                    }
                }
            }
        }
    }

    // Footer with back button
    RowLayout {
        id: footer
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.margins: 10

        Button {
            text: "Zurück"
            onClicked: settingsPage.StackView.view.pop()
            HoverHandler { cursorShape: Qt.PointingHandCursor }
        }
    }

    FolderDialog {
        id: imageDirDialog
        title: "Bilderverzeichnis auswählen"
        onAccepted: {
            // FolderDialog liefert eine file:// URL, in lokalen Pfad umwandeln
            var url = imageDirDialog.selectedFolder.toString()
            var localPath = url.replace(/^file:\/{2,3}/, "")
            imageDirField.text = decodeURIComponent(localPath)
        }
    }
}