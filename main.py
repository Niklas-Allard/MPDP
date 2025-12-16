# This Python file uses the following encoding: utf-8
import sys
from pathlib import Path

from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import QAbstractListModel, QModelIndex, Qt

# ImageModel Klasse für QML Repeater
class ImageItem:
    def __init__(self, image, title):
        self.image = image
        self.title = title

class ImageModel(QAbstractListModel):
    ImageRole = Qt.UserRole + 1
    TitleRole = Qt.UserRole + 2

    def __init__(self, parent=None):
        super().__init__(parent)
        self._items = []

    def rowCount(self, parent=QModelIndex()):
        return len(self._items)

    def data(self, index, role=Qt.DisplayRole):
        if not index.isValid():
            return None  # QVariant() durch None ersetzt
        item = self._items[index.row()]
        if role == self.ImageRole:
            return item.image
        elif role == self.TitleRole:
            return item.title
        return None  # QVariant() durch None ersetzt

    def roleNames(self):
        return {
            self.ImageRole: b"image",
            self.TitleRole: b"title"
        }

    def addItem(self, image, title):
        self.beginInsertRows(QModelIndex(), len(self._items), len(self._items))
        self._items.append(ImageItem(image, title))
        self.endInsertRows()

if __name__ == "__main__":
    app = QGuiApplication(sys.argv)
    engine = QQmlApplicationEngine()
    
    # ImageModel erstellen und mit Testdaten füllen
    image_model = ImageModel()
    image_model.addItem("https://picsum.photos/200/300", "Erster Titel")
    image_model.addItem("https://picsum.photos/200/300", "Zweiter Titel")
    image_model.addItem("https://picsum.photos/200/300", "Dritter Titel")
    image_model.addItem("https://picsum.photos/200/300", "Vierter Titel")
    image_model.addItem("https://picsum.photos/200/300", "Fünfter Titel")
    image_model.addItem("https://picsum.photos/200/300", "Sechster Titel")
    image_model.addItem("https://picsum.photos/200/300", "Siebter Titel")
    
    # Modell als Context Property für QML verfügbar machen
    engine.rootContext().setContextProperty("myModel", image_model)
    
    # QML Datei laden
    qml_file = Path(__file__).resolve().parent / "main.qml"
    engine.load(qml_file)
    
    if not engine.rootObjects():
        sys.exit(-1)
    sys.exit(app.exec())
