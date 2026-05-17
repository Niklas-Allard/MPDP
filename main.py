# This Python file uses the following encoding: utf-8
import sys
from pathlib import Path

from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import QResource, QFile, QCoreApplication

from fileHandler import fileHandler
from media_DB import Media_DB
from settings_manager import SettingsManager

if __name__ == "__main__":
    # Organisation/Anwendungsnamen setzen, damit QSettings konsistent funktioniert
    QCoreApplication.setOrganizationName(SettingsManager.ORG_NAME)
    QCoreApplication.setApplicationName(SettingsManager.APP_NAME)

    app = QGuiApplication(sys.argv)
    engine = QQmlApplicationEngine()

    rcc_path = Path(__file__).resolve().parent / "resources.rcc"
    ok = QResource.registerResource(str(rcc_path), "/")  # mount unter :/
    print("registerResource:", ok)
    print("exists:", QFile.exists(":/icons/arrow_forward.png"))

    # Settings (QSettings-basiert) – ersetzt die alte user_data.json
    settings_manager = SettingsManager()
    engine.rootContext().setContextProperty("settingsManager", settings_manager)

    # create fileHandler instance (nutzt den SettingsManager für globalImageDirectory)
    fileManager = fileHandler(settings_manager=settings_manager)
    engine.rootContext().setContextProperty("fileManager", fileManager)

    # Create an instance that handles database operations
    media_DB = Media_DB()
    engine.rootContext().setContextProperty("media_DB", media_DB)

    # Hauptverzeichnisse jetzt direkt aus QSettings
    main_dirs = settings_manager.get_main_directories()
    engine.rootContext().setContextProperty("mainDirs", main_dirs)

    # Bei Änderung der Hauptverzeichnisse den Context Property aktualisieren
    def _refresh_main_dirs():
        engine.rootContext().setContextProperty(
            "mainDirs", settings_manager.get_main_directories()
        )

    settings_manager.main_directories_changed.connect(_refresh_main_dirs)

    # QML Datei laden
    qml_file = Path(__file__).resolve().parent / "main.qml"
    engine.load(qml_file)

    if not engine.rootObjects():
        sys.exit(-1)
    sys.exit(app.exec())