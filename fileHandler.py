from pathlib import Path
import json

class fileHandler:

    def path_to_dict(self, path):
        # Basis-Objekt für die aktuelle Datei/Ordner
        d = {
            'name': Path(path).stem,
            'type': 'directory' if path.is_dir() else 'file'
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