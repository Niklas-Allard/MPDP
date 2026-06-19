from PySide6.QtCore import Signal, Slot


class DirectoriesMixin:
    main_directories_changed = Signal()
    global_image_directory_changed = Signal()

    def _write_main_directories(self, dirs: list):
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
