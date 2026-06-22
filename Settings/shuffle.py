from pathlib import Path

from PySide6.QtCore import Signal, Slot


class ShuffleMixin:
    shuffle_folders_changed = Signal()

    def _write_shuffle_folders(self, dirs: list):
        self._settings.remove("shuffle_folders")
        self._settings.beginWriteArray("shuffle_folders", len(dirs))
        for i, entry in enumerate(dirs):
            self._settings.setArrayIndex(i)
            self._settings.setValue("name", entry.get("name", ""))
            self._settings.setValue("path", entry.get("path", ""))
        self._settings.endArray()
        self._settings.sync()

    @Slot(result="QVariantList")
    def get_shuffle_folders(self) -> list:
        result = []
        size = self._settings.beginReadArray("shuffle_folders")
        for i in range(size):
            self._settings.setArrayIndex(i)
            result.append({
                "name": self._settings.value("name", "", type=str),
                "path": self._settings.value("path", "", type=str),
            })
        self._settings.endArray()
        return result

    @Slot("QVariantList")
    def set_shuffle_folders(self, dirs):
        normalized = [
            {"name": str(d.get("name", "")), "path": str(d.get("path", ""))}
            for d in dirs
        ]
        self._write_shuffle_folders(normalized)
        self.shuffle_folders_changed.emit()

    @Slot(str, str)
    def add_shuffle_folder(self, name: str, path: str):
        dirs = self.get_shuffle_folders()
        dirs.append({"name": name, "path": path})
        self._write_shuffle_folders(dirs)
        self.shuffle_folders_changed.emit()

    @Slot(int)
    def remove_shuffle_folder(self, index: int):
        dirs = self.get_shuffle_folders()
        if 0 <= index < len(dirs):
            dirs.pop(index)
            self._write_shuffle_folders(dirs)
            self.shuffle_folders_changed.emit()

    @Slot(str, result=bool)
    def is_shuffle_folder(self, path: str) -> bool:
        if not path:
            return False
        norm = Path(path).as_posix().lower()
        for entry in self.get_shuffle_folders():
            entry_path = entry.get("path", "")
            if entry_path and Path(entry_path).as_posix().lower() == norm:
                return True
        return False
