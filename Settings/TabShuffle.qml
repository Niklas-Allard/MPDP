import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs

ScrollView {
    id: root
    clip: true
    contentWidth: availableWidth

    property var shuffleFoldersModel: []

    Component.onCompleted: reload()

    function reload() {
        shuffleFoldersModel = settingsManager.get_shuffle_folders()
    }

    Connections {
        target: settingsManager
        function onShuffle_folders_changed() { root.reload() }
    }

    FolderDialog {
        id: newFolderDialog
        title: "Serienordner für Shuffle auswählen"
        onAccepted: {
            var url = newFolderDialog.selectedFolder.toString()
            var localPath = decodeURIComponent(url.replace(/^file:\/{2,3}/, ""))
            newPathField.text = localPath
            if (newNameField.text.length === 0) {
                var parts = localPath.replace(/\/+$/, "").split("/")
                newNameField.text = parts[parts.length - 1]
            }
        }
    }

    ColumnLayout {
        width: parent.availableWidth
        spacing: 20

        Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: "Ordner, die hier eingetragen sind, gelten als Serien im Shuffle-Modus. " +
                  "Im Dateibrowser erscheint dort unten ein Shuffle-Button, der eine zufällige, " +
                  "noch nicht gesehene Folge abspielt."
            color: settingsManager.colorText
        }

        GroupBox {
            Layout.fillWidth: true
            title: "Shuffle-Ordner (Serien)"

            ColumnLayout {
                anchors.fill: parent
                spacing: 8

                Repeater {
                    model: root.shuffleFoldersModel

                    delegate: RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Label {
                            Layout.preferredWidth: 160
                            text: modelData.name
                            elide: Text.ElideRight
                            color: settingsManager.colorText
                        }

                        Label {
                            Layout.fillWidth: true
                            text: modelData.path
                            elide: Text.ElideMiddle
                            color: settingsManager.colorText
                        }

                        Button {
                            id: ttHost1
                            text: "Entfernen"
                            onClicked: settingsManager.remove_shuffle_folder(index)
                            ToolTip {
                                visible: ttHost1.hovered
                                delay: 500
                                text: "Diesen Ordner aus dem Shuffle-Modus entfernen.\nDer Shuffle-Button verschwindet dann im Dateibrowser für diesen Ordner.\nDie Dateien auf der Festplatte bleiben unberührt."
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
                        placeholderText: "Name (z. B. Serienname)"
                    }

                    TextField {
                        id: newPathField
                        Layout.fillWidth: true
                        placeholderText: "Pfad zum Serienordner"
                    }

                    Button {
                        id: ttHost2
                        text: "Durchsuchen…"
                        onClicked: newFolderDialog.open()
                        ToolTip {
                            visible: ttHost2.hovered
                            delay: 500
                            text: "Serienordner über den Datei-Dialog auswählen.\nDer Name wird automatisch aus dem Ordnernamen übernommen."
                        }
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                    }

                    Button {
                        id: ttHost3
                        text: "Hinzufügen"
                        enabled: newNameField.text.length > 0 && newPathField.text.length > 0
                        onClicked: {
                            settingsManager.add_shuffle_folder(newNameField.text, newPathField.text)
                            newNameField.text = ""
                            newPathField.text = ""
                        }
                        ToolTip {
                            visible: ttHost3.hovered
                            delay: 500
                            text: "Ordner als Serienordner für den Shuffle-Modus hinzufügen.\nIm Dateibrowser erscheint dann ein Shuffle-Button für diesen Ordner,\nder eine zufällige, noch nicht gesehene Folge abspielt."
                        }
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
