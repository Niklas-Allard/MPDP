# This Python file uses the following encoding: utf-8
import sys
from pathlib import Path

from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import QAbstractListModel, QModelIndex, Qt

from fileHandler import fileHandler
from media_DB import Media_DB
import json

if __name__ == "__main__":
    app = QGuiApplication(sys.argv)
    engine = QQmlApplicationEngine()
    
    # create fileHandler instance
    fileManager = fileHandler()
    files = fileManager.path_to_dict(Path(r'C:\Users\Nikla\Videos'))

    # Create an instance that handles database operations
    media_DB = Media_DB()
    engine.rootContext().setContextProperty("media_DB", media_DB)

    # Modell als Context Property für QML verfügbar machen
    engine.rootContext().setContextProperty("folderData", files)
    
    # QML Datei laden
    qml_file = Path(__file__).resolve().parent / "main.qml"
    engine.load(qml_file)
    
    if not engine.rootObjects():
        sys.exit(-1)
    sys.exit(app.exec())