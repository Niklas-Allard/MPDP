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
                    ToolTip {
                        visible: imageDirField.hovered
                        delay: 500
                        text: "Ordner, in dem Poster/Cover für Serien und Filme gespeichert sind.\nDateien müssen den gleichen Namen wie der zugehörige Ordner tragen\n(z. B. 'Breaking Bad.jpg' für den Ordner 'Breaking Bad')."
                    }
                }

                Button {
                    id: ttHost1
                    text: "Durchsuchen…"
                    onClicked: imageDirDialog.open()
                    ToolTip {
                        visible: ttHost1.hovered
                        delay: 500
                        text: "Ordner über den Datei-Dialog auswählen."
                    }
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                }

                Button {
                    id: ttHost2
                    text: "Speichern"
                    onClicked: settingsManager.set_global_image_directory(imageDirField.text)
                    ToolTip {
                        visible: ttHost2.hovered
                        delay: 500
                        text: "Den eingegebenen Pfad als globales Bilderverzeichnis speichern."
                    }
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
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
                            id: ttHost3
                            text: "Speichern"
                            onClicked: settingsManager.update_main_directory(index, nameField.text, pathField.text)
                            ToolTip {
                                visible: ttHost3.hovered
                                delay: 500
                                text: "Änderungen an Name und Pfad dieses Hauptverzeichnisses speichern."
                            }
                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                        }

                        Button {
                            id: ttHost4
                            text: "Entfernen"
                            onClicked: settingsManager.remove_main_directory(index)
                            ToolTip {
                                visible: ttHost4.hovered
                                delay: 500
                                text: "Dieses Hauptverzeichnis aus der Liste entfernen.\nDie Dateien auf der Festplatte bleiben unberührt."
                            }
                            HoverHandler { cursorShape: Qt.PointingHandCursor }
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
                        ToolTip {
                            visible: newNameField.hovered
                            delay: 500
                            text: "Anzeigename für das Hauptverzeichnis (z. B. 'Filme' oder 'Serien').\nDieser Name erscheint auf der Startseite der App."
                        }
                    }

                    TextField {
                        id: newPathField
                        Layout.fillWidth: true
                        placeholderText: "Neuer Pfad"
                        ToolTip {
                            visible: newPathField.hovered
                            delay: 500
                            text: "Vollständiger Pfad zum Verzeichnis auf der Festplatte\n(z. B. D:/Filme oder \\\\NAS\\Videos)."
                        }
                    }

                    Button {
                        id: ttHost5
                        text: "Hinzufügen"
                        enabled: newNameField.text.length > 0 && newPathField.text.length > 0
                        onClicked: {
                            settingsManager.add_main_directory(newNameField.text, newPathField.text)
                            newNameField.text = ""
                            newPathField.text = ""
                        }
                        ToolTip {
                            visible: ttHost5.hovered
                            delay: 500
                            text: "Das neue Hauptverzeichnis zur Liste hinzufügen.\nEs erscheint danach auf der Startseite."
                        }
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
