from pathlib import Path
from PySide6.QtCore import Slot, QObject, QUrl

class fileHandler(QObject):

    # Supported image formats in priority order
    SUPPORTED_IMAGE_FORMATS = ['.jpg', '.jpeg', '.png', '.webp', '.bmp', '.ico']

    def __init__(self, settings_manager=None):
        super().__init__()
        self._settings_manager = settings_manager

    def set_settings_manager(self, settings_manager):
        self._settings_manager = settings_manager

    # -- Hilfen ---------------------------------------------------------------
    def _is_hidden(self, path: Path) -> bool:
        if path.name.startswith("."):
            return True
        # Windows-Versteckt-Attribut
        try:
            import os
            attrs = getattr(path.stat(), "st_file_attributes", None)
            if attrs is not None:
                FILE_ATTRIBUTE_HIDDEN = 0x2
                FILE_ATTRIBUTE_SYSTEM = 0x4
                if attrs & (FILE_ATTRIBUTE_HIDDEN | FILE_ATTRIBUTE_SYSTEM):
                    return True
        except (FileNotFoundError, OSError):
            pass
        return False

    def _sort_children(self, items: list) -> list:
        order = "name_asc"
        if self._settings_manager is not None:
            order = self._settings_manager.sortOrder or "name_asc"

        def by_name(it):
            return it.name.lower()

        def by_mtime(it):
            try:
                return it.stat().st_mtime
            except (FileNotFoundError, OSError):
                return 0

        def by_size(it):
            try:
                return it.stat().st_size if it.is_file() else 0
            except (FileNotFoundError, OSError):
                return 0

        # Ordner vor Dateien anzeigen (sinnvoll für Browser)
        dirs = [p for p in items if p.is_dir()]
        files = [p for p in items if not p.is_dir()]

        if order == "name_desc":
            dirs.sort(key=by_name, reverse=True)
            files.sort(key=by_name, reverse=True)
        elif order == "date_desc":
            dirs.sort(key=by_mtime, reverse=True)
            files.sort(key=by_mtime, reverse=True)
        elif order == "size_desc":
            dirs.sort(key=by_name)
            files.sort(key=by_size, reverse=True)
        else:  # name_asc
            dirs.sort(key=by_name)
            files.sort(key=by_name)

        return dirs + files

    def get_thumbnail_for_dir(self, path_str: str) -> str:
        if not path_str:
            return ""
        path = Path(path_str)
        global_image_dir = ""
        if self._settings_manager is not None:
            global_image_dir = self._settings_manager.get_global_image_directory()
        if not global_image_dir:
            return ""
        for ext in self.SUPPORTED_IMAGE_FORMATS:
            thumbnail_file = Path(global_image_dir) / f"{path.name}{ext}"
            if thumbnail_file.exists():
                return QUrl.fromLocalFile(str(thumbnail_file)).toString()
        return ""

    @Slot(str, result=dict)
    def path_to_dict(self, path) -> dict:
        path = Path(path)

        thumbnail_path = ""
        global_image_dir = ""
        if self._settings_manager is not None:
            global_image_dir = self._settings_manager.get_global_image_directory()

        if global_image_dir:
            if path.is_dir():
                for ext in self.SUPPORTED_IMAGE_FORMATS:
                    thumbnail_file = Path(global_image_dir) / f"{path.name}{ext}"
                    if thumbnail_file.exists():
                        thumbnail_path = QUrl.fromLocalFile(str(thumbnail_file)).toString()
                        break
            else:
                for ext in self.SUPPORTED_IMAGE_FORMATS:
                    thumbnail_file = Path(global_image_dir) / f"{path.stem}{ext}"
                    if thumbnail_file.exists():
                        thumbnail_path = QUrl.fromLocalFile(str(thumbnail_file)).toString()
                        break

                if not thumbnail_path:
                    parent_folder_name = path.parent.name
                    for ext in self.SUPPORTED_IMAGE_FORMATS:
                        parent_thumbnail_file = Path(global_image_dir) / f"{parent_folder_name}{ext}"
                        if parent_thumbnail_file.exists():
                            thumbnail_path = QUrl.fromLocalFile(str(parent_thumbnail_file)).toString()
                            break

        d = {
            'name': path.stem,
            'type': 'directory' if path.is_dir() else 'file',
            'path': str(path),
            'thumbnail': thumbnail_path
        }

        if path.is_dir():
            d['children'] = []
            show_hidden = False
            if self._settings_manager is not None:
                show_hidden = self._settings_manager.showHiddenFiles

            try:
                items = list(path.iterdir())
                if not show_hidden:
                    items = [it for it in items if not self._is_hidden(it)]
                items = self._sort_children(items)
                for item in items:
                    d['children'].append(self.path_to_dict(item))
            except PermissionError:
                d['error'] = 'Zugriff verweigert'
        else:
            try:
                d['size'] = path.stat().st_size
            except FileNotFoundError:
                d['size'] = 0

        return d
