# This Python file uses the following encoding: utf-8
import sys
from pathlib import Path

from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import QAbstractListModel, QModelIndex, Qt, QResource, QFile

from fileHandler import fileHandler
from media_DB import Media_DB

if __name__ == "__main__":
    app = QGuiApplication(sys.argv)
    engine = QQmlApplicationEngine()

    rcc_path = Path(__file__).resolve().parent / "resources.rcc"
    ok = QResource.registerResource(str(rcc_path), "/")  # mount unter :/
    print("registerResource:", ok)
    print("exists:", QFile.exists(":/icons/arrow_forward.png"))
    
    # create fileHandler instance
    fileManager = fileHandler()
    engine.rootContext().setContextProperty("fileManager", fileManager)

    # Create an instance that handles database operations
    media_DB = Media_DB()
    engine.rootContext().setContextProperty("m/creditedia_DB", media_DB)

    # get main directories from database
    main_dirs = media_DB.get_main_directories()
    engine.rootContext().setContextProperty("mainDirs", main_dirs)
    
    # QML Datei laden
    qml_file = Path(__file__).resolve().parent / "main.qml"
    engine.load(qml_file)
    
    if not engine.rootObjects():
        sys.exit(-1)
    sys.exit(app.exec())