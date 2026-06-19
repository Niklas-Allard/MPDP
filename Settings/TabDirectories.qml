import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs

ScrollView {
    id: root
    clip: true
    contentWidth: availableWidth

    property var mainDirsModel: []

    Component.onCompleted: reload()

    function reload() {
        mainDirsModel = settingsManager.get_main_directories()
        imageDirField.text = settingsManager.get_global_image_directory()
    }

    Connections {
        target: settingsManager
        function onMain_directories_changed() { root.reload() }
        function onGlobal_image_directory_changed() { root.reload() }
    }

    FolderDialog {
        id: imageDirDialog
        title: "Bilderverzeichnis auswählen"
        onAccepted: {
            var url = imageDirDialog.selectedFolder.toString()
            var localPath = url.replace(/^file:\/{2,3}/, "")
            imageDirField.text = decodeURIComponent(localPath)
        }
    }

    ColumnLayout {
        width: parent.availableWidth
        spacing: 20

        // Globales Bilderverzeichnis
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

        // Hauptverzeichnisse
        GroupBox {
            Layout.fillWidth: true
            title: "Hauptverzeichnisse"

            ColumnLayout {
                anchors.fill: parent
                spacing: 8

                Repeater {
                    model: root.mainDirsModel

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

        Item { Layout.fillHeight: true }
    }
}
