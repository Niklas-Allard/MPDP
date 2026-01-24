from pathlib import Path
from PySide6.QtCore import Slot, QObject, QUrl
import json

class fileHandler(QObject):

    # Supported image formats in priority order
    SUPPORTED_IMAGE_FORMATS = ['.jpg', '.jpeg', '.png', '.webp', '.bmp', '.ico']

    def __init__(self):
        super().__init__()

    @Slot(str, result=dict)
    def path_to_dict(self, path) -> dict:
        # Konvertiere String zu Path-Objekt
        path = Path(path)

        # Load global image directory from user_data.json
        thumbnail_path = ""
        try:
            config_path = Path(__file__).parent / "database" / "user_data.json"
            with open(config_path, 'r', encoding='utf-8') as f:
                config = json.load(f)
                global_image_dir = config.get('global_image_directory', '')

                print(f"[DEBUG] Global image dir: {global_image_dir}")

                if global_image_dir:
                    if path.is_dir():
                        # For directories, check for image with multiple formats
                        for ext in self.SUPPORTED_IMAGE_FORMATS:
                            thumbnail_file = Path(global_image_dir) / f"{path.name}{ext}"
                            print(f"[DEBUG] Looking for dir thumbnail: {thumbnail_file} (exists: {thumbnail_file.exists()})")
                            if thumbnail_file.exists():
                                # Convert to proper file URL for QML
                                thumbnail_path = QUrl.fromLocalFile(str(thumbnail_file)).toString()
                                print(f"[DEBUG] Dir thumbnail URL: {thumbnail_path}")
                                break  # Stop at first match
                    else:
                        # For files: try direct match first, then parent folder fallback
                        # 1. Direct match: MyFile.[ext]
                        for ext in self.SUPPORTED_IMAGE_FORMATS:
                            thumbnail_file = Path(global_image_dir) / f"{path.stem}{ext}"
                            print(f"[DEBUG] Looking for file thumbnail: {thumbnail_file} (exists: {thumbnail_file.exists()})")
                            if thumbnail_file.exists():
                                # Convert to proper file URL for QML
                                thumbnail_path = QUrl.fromLocalFile(str(thumbnail_file)).toString()
                                print(f"[DEBUG] File thumbnail URL: {thumbnail_path}")
                                break  # Stop at first match

                        # 2. Parent folder fallback if no direct match found
                        if not thumbnail_path:
                            parent_folder_name = path.parent.name
                            for ext in self.SUPPORTED_IMAGE_FORMATS:
                                parent_thumbnail_file = Path(global_image_dir) / f"{parent_folder_name}{ext}"
                                print(f"[DEBUG] Looking for parent thumbnail: {parent_thumbnail_file} (exists: {parent_thumbnail_file.exists()})")
                                if parent_thumbnail_file.exists():
                                    # Convert to proper file URL for QML
                                    thumbnail_path = QUrl.fromLocalFile(str(parent_thumbnail_file)).toString()
                                    print(f"[DEBUG] Parent thumbnail URL: {thumbnail_path}")
                                    break  # Stop at first match
        except (FileNotFoundError, json.JSONDecodeError, KeyError) as e:
            print(f"[DEBUG] Error loading config: {e}")
            pass

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
                # Iteriere durch alle Elemente im Ordner
                for item in path.iterdir():
                    # Rekursiver Aufruf für jedes Unterelement
                    d['children'].append(self.path_to_dict(item))
            except PermissionError:
                # Falls Zugriff verweigert wird (z.B. Systemordner)
                d['error'] = 'Zugriff verweigert'
        else:
            # Optional: Metadaten für Dateien hinzufügen (z.B. Größe in Bytes)
            try:
                d['size'] = path.stat().st_size
            except FileNotFoundError:
                d['size'] = 0

        return d