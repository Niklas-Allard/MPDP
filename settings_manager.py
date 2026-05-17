from pathlib import Path
from PySide6.QtCore import QObject, QSettings, Slot, Signal


class SettingsManager(QObject):
    """QSettings-basierte Konfigurationsverwaltung.

    Ersetzt die alte JSON-Datei (database/user_data.json).
    Beim ersten Start werden vorhandene JSON-Daten einmalig migriert.
    """

    main_directories_changed = Signal()
    global_image_directory_changed = Signal()

    ORG_NAME = "MPDP"
    APP_NAME = "MediaPlayer"

    def __init__(self):
        super().__init__()
        self._settings = QSettings(self.ORG_NAME, self.APP_NAME)
        self._migrate_from_json_if_needed()

    def _migrate_from_json_if_needed(self):
        if self._settings.value("migrated_from_json", False, type=bool):
            return

        legacy_path = Path(__file__).resolve().parent / "database" / "user_data.json"
        if not legacy_path.exists():
            self._settings.setValue("migrated_from_json", True)
            self._settings.sync()
            return

        import json
        try:
            with open(legacy_path, "r", encoding="utf-8") as f:
                config = json.load(f)
        except (OSError, json.JSONDecodeError) as e:
            print(f"[SettingsManager] Migration übersprungen: {e}")
            return

        main_dirs = config.get("main_directories", [])
        self._write_main_directories(main_dirs)

        self._settings.setValue(
            "global_image_directory",
            config.get("global_image_directory", ""),
        )
        self._settings.setValue("migrated_from_json", True)
        self._settings.sync()
        print(f"[SettingsManager] {len(main_dirs)} Verzeichnisse aus JSON migriert.")

    def _write_main_directories(self, dirs: list):
        # Alte Einträge sicher entfernen, damit kürzere Listen korrekt gespeichert werden
        self._settings.remove("main_directories")
        self._settings.beginWriteArray("main_directories", len(dirs))
        for i, entry in enumerate(dirs):
            self._settings.setArrayIndex(i)
            self._settings.setValue("name", entry.get("name", ""))
            self._settings.setValue("path", entry.get("path", ""))
        self._settings.endArray()
        self._settings.sync()

    @Slot(result="QVariantList")
    def get_main_directories(self) -> list:
        result = []
        size = self._settings.beginReadArray("main_directories")
        for i in range(size):
            self._settings.setArrayIndex(i)
            result.append({
                "name": self._settings.value("name", "", type=str),
                "path": self._settings.value("path", "", type=str),
            })
        self._settings.endArray()
        return result

    @Slot("QVariantList")
    def set_main_directories(self, dirs):
        normalized = [
            {"name": str(d.get("name", "")), "path": str(d.get("path", ""))}
            for d in dirs
        ]
        self._write_main_directories(normalized)
        self.main_directories_changed.emit()

    @Slot(str, str)
    def add_main_directory(self, name: str, path: str):
        dirs = self.get_main_directories()
        dirs.append({"name": name, "path": path})
        self._write_main_directories(dirs)
        self.main_directories_changed.emit()

    @Slot(int)
    def remove_main_directory(self, index: int):
        dirs = self.get_main_directories()
        if 0 <= index < len(dirs):
            dirs.pop(index)
            self._write_main_directories(dirs)
            self.main_directories_changed.emit()

    @Slot(int, str, str)
    def update_main_directory(self, index: int, name: str, path: str):
        dirs = self.get_main_directories()
        if 0 <= index < len(dirs):
            dirs[index] = {"name": name, "path": path}
            self._write_main_directories(dirs)
            self.main_directories_changed.emit()

    @Slot(result=str)
    def get_global_image_directory(self) -> str:
        return self._settings.value("global_image_directory", "", type=str)

    @Slot(str)
    def set_global_image_directory(self, path: str):
        self._settings.setValue("global_image_directory", path)
        self._settings.sync()
        self.global_image_directory_changed.emit()