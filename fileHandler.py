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

    @Slot(str, result=dict)
    def path_to_dict(self, path) -> dict:
        # Konvertiere String zu Path-Objekt
        path = Path(path)

        # Globales Bildverzeichnis aus QSettings laden
        thumbnail_path = ""
        global_image_dir = ""
        if self._settings_manager is not None:
            global_image_dir = self._settings_manager.get_global_image_directory()

        print(f"[DEBUG] Global image dir: {global_image_dir}")

        if global_image_dir:
            if path.is_dir():
                # For directories, check for image with multiple formats
                for ext in self.SUPPORTED_IMAGE_FORMATS:
                    thumbnail_file = Path(global_image_dir) / f"{path.name}{ext}"
                    print(f"[DEBUG] Looking for dir thumbnail: {thumbnail_file} (exists: {thumbnail_file.exists()})")
                    if thumbnail_file.exists():
                        thumbnail_path = QUrl.fromLocalFile(str(thumbnail_file)).toString()
                        print(f"[DEBUG] Dir thumbnail URL: {thumbnail_path}")
                        break
            else:
                # For files: try direct match first, then parent folder fallback
                for ext in self.SUPPORTED_IMAGE_FORMATS:
                    thumbnail_file = Path(global_image_dir) / f"{path.stem}{ext}"
                    print(f"[DEBUG] Looking for file thumbnail: {thumbnail_file} (exists: {thumbnail_file.exists()})")
                    if thumbnail_file.exists():
                        thumbnail_path = QUrl.fromLocalFile(str(thumbnail_file)).toString()
                        print(f"[DEBUG] File thumbnail URL: {thumbnail_path}")
                        break

                if not thumbnail_path:
                    parent_folder_name = path.parent.name
                    for ext in self.SUPPORTED_IMAGE_FORMATS:
                        parent_thumbnail_file = Path(global_image_dir) / f"{parent_folder_name}{ext}"
                        print(f"[DEBUG] Looking for parent thumbnail: {parent_thumbnail_file} (exists: {parent_thumbnail_file.exists()})")
                        if parent_thumbnail_file.exists():
                            thumbnail_path = QUrl.fromLocalFile(str(parent_thumbnail_file)).toString()
                            print(f"[DEBUG] Parent thumbnail URL: {thumbnail_path}")
                            break

        # Basis-Objekt für die aktuelle Datei/Ordner
        d = {
            'name': path.stem,
            'type': 'directory' if path.is_dir() else 'file',
            'path': str(path),
            'thumbnail': thumbnail_path
        }

        if path.is_dir():
            d['children'] = []
            try:
                for item in path.iterdir():
                    d['children'].append(self.path_to_dict(item))
            except PermissionError:
                d['error'] = 'Zugriff verweigert'
        else:
            try:
                d['size'] = path.stat().st_size
            except FileNotFoundError:
                d['size'] = 0

        return d