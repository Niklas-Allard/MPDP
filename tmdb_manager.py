import threading
import time
import urllib.request
from pathlib import Path

from PySide6.QtCore import QObject, Signal, Slot


class TmdbManager(QObject):
    search_results_ready = Signal(list)
    download_finished = Signal(str)
    download_error = Signal(str)
    status_changed = Signal(str)

    # current, total, folder_name
    bulk_progress = Signal(int, int, str)
    # downloaded, skipped, errors
    bulk_finished = Signal(int, int, int)
    bulk_cancelled = Signal()

    _KEYRING_SERVICE = "MPDP_TMDB"
    _KEYRING_USER = "api_key"
    _SUPPORTED_EXTS = ['.jpg', '.jpeg', '.png', '.webp', '.bmp', '.ico']

    def __init__(self, settings_manager=None):
        super().__init__()
        self._settings_manager = settings_manager
        self._api_key = self._load_api_key()
        self._bulk_running = False
        self._cancel_bulk = False

    # ── API-Key ──────────────────────────────────────────────────────────────

    def _load_api_key(self) -> str:
        try:
            import keyring
            key = keyring.get_password(self._KEYRING_SERVICE, self._KEYRING_USER)
            if key:
                return key
        except Exception:
            pass
        from PySide6.QtCore import QSettings
        return QSettings("MPDP", "MediaPlayer").value("tmdb_api_key_fb", "", type=str)

    @Slot(result=str)
    def get_api_key(self) -> str:
        return self._api_key

    @Slot(str)
    def save_api_key(self, key: str):
        key = key.strip()
        saved = False
        try:
            import keyring
            keyring.set_password(self._KEYRING_SERVICE, self._KEYRING_USER, key)
            saved = True
        except Exception:
            pass
        if not saved:
            from PySide6.QtCore import QSettings
            s = QSettings("MPDP", "MediaPlayer")
            s.setValue("tmdb_api_key_fb", key)
            s.sync()
        self._api_key = key
        self.status_changed.emit("API-Key gespeichert." if key else "API-Key gelöscht.")

    @Slot(result=bool)
    def has_api_key(self) -> bool:
        return bool(self._api_key)

    # ── Hilfsmethoden ────────────────────────────────────────────────────────

    def _init_tmdb(self):
        if not self._api_key:
            raise ValueError("Kein API-Key gesetzt. Bitte in den Einstellungen konfigurieren.")
        from tmdbv3api import TMDb
        tmdb = TMDb()
        tmdb.api_key = self._api_key
        tmdb.language = "de"
        return tmdb

    @Slot(str, result=str)
    def poster_preview_url(self, poster_path: str) -> str:
        if not poster_path:
            return ""
        return f"https://image.tmdb.org/t/p/w185{poster_path}"

    # ── Suche ────────────────────────────────────────────────────────────────

    @Slot(str, str)
    def search(self, query: str, media_type: str):
        """media_type: 'movie' | 'tv' | 'multi'"""
        self.status_changed.emit("Suche läuft…")
        threading.Thread(
            target=self._do_search, args=(query.strip(), media_type), daemon=True
        ).start()

    def _do_search(self, query: str, media_type: str):
        try:
            self._init_tmdb()
        except ValueError as e:
            self.status_changed.emit(str(e))
            self.search_results_ready.emit([])
            return

        results: list[dict] = []
        try:
            if media_type in ("movie", "multi"):
                from tmdbv3api import Movie
                for r in Movie().search(query)[:15]:
                    results.append({
                        "id": int(r.id),
                        "title": str(getattr(r, "title", "") or ""),
                        "poster_path": str(getattr(r, "poster_path", "") or ""),
                        "media_type": "movie",
                        "year": str(getattr(r, "release_date", "") or "")[:4],
                    })

            if media_type in ("tv", "multi"):
                from tmdbv3api import TV
                for r in TV().search(query)[:15]:
                    results.append({
                        "id": int(r.id),
                        "title": str(getattr(r, "name", "") or getattr(r, "title", "") or ""),
                        "poster_path": str(getattr(r, "poster_path", "") or ""),
                        "media_type": "tv",
                        "year": str(getattr(r, "first_air_date", "") or "")[:4],
                    })

            self.search_results_ready.emit(results[:30])
            n = len(results)
            self.status_changed.emit(
                f"{n} Ergebnis{'se' if n != 1 else ''} gefunden." if n else "Keine Ergebnisse."
            )
        except Exception as e:
            self.status_changed.emit(f"Suchfehler: {e}")
            self.search_results_ready.emit([])

    # ── Download ─────────────────────────────────────────────────────────────

    @Slot(int, str, str)
    def download_poster(self, tmdb_id: int, media_type: str, target_name: str):
        self.status_changed.emit("Poster wird heruntergeladen…")
        threading.Thread(
            target=self._do_download,
            args=(tmdb_id, media_type, target_name),
            daemon=True,
        ).start()

    def _do_download(self, tmdb_id: int, media_type: str, target_name: str):
        try:
            self._init_tmdb()
        except ValueError as e:
            self.download_error.emit(str(e))
            return

        image_dir = ""
        quality = "w500"
        if self._settings_manager:
            image_dir = self._settings_manager.get_global_image_directory()
            quality = getattr(self._settings_manager, "tmdbPosterQuality", "w500") or "w500"

        if not image_dir:
            self.download_error.emit(
                "Kein Bilderverzeichnis konfiguriert (Einstellungen → Verzeichnisse)."
            )
            return

        try:
            if media_type == "movie":
                from tmdbv3api import Movie
                details = Movie().details(tmdb_id)
            else:
                from tmdbv3api import TV
                details = TV().details(tmdb_id)

            poster_path = getattr(details, "poster_path", None)
            if not poster_path:
                self.download_error.emit("Kein Poster für diesen Titel verfügbar.")
                return

            url = f"https://image.tmdb.org/t/p/{quality}{poster_path}"
            dest = Path(image_dir) / f"{target_name}.jpg"
            urllib.request.urlretrieve(url, str(dest))
            self.download_finished.emit(str(dest))
            self.status_changed.emit(f"Gespeichert: {dest.name}")
        except Exception as e:
            self.download_error.emit(f"Download fehlgeschlagen: {e}")

    # ── Massen-Download ──────────────────────────────────────────────────────

    @Slot()
    def start_bulk_download(self):
        if self._bulk_running:
            return
        self._cancel_bulk = False
        self._bulk_running = True
        threading.Thread(target=self._do_bulk_download, daemon=True).start()

    @Slot()
    def cancel_bulk_download(self):
        self._cancel_bulk = True

    def _collect_folders(self) -> list[Path]:
        """Gibt alle Unterordner aus allen Hauptverzeichnissen zurück."""
        sm = self._settings_manager
        if not sm:
            return []
        folders: list[Path] = []
        for d in sm.get_main_directories():
            p = Path(d.get("path", ""))
            if p.is_dir():
                for sub in sorted(p.iterdir()):
                    if sub.is_dir():
                        folders.append(sub)
        return folders

    def _poster_exists(self, image_dir: str, name: str) -> bool:
        return any(
            (Path(image_dir) / f"{name}{ext}").exists()
            for ext in self._SUPPORTED_EXTS
        )

    def _do_bulk_download(self):
        try:
            self._run_bulk()
        finally:
            self._bulk_running = False

    def _run_bulk(self):
        sm = self._settings_manager
        if not sm:
            self.status_changed.emit("Kein SettingsManager verfügbar.")
            self.bulk_finished.emit(0, 0, 0)
            return

        try:
            self._init_tmdb()
        except ValueError as e:
            self.status_changed.emit(str(e))
            self.bulk_finished.emit(0, 0, 0)
            return

        image_dir = sm.get_global_image_directory()
        if not image_dir:
            self.status_changed.emit(
                "Kein Bilderverzeichnis konfiguriert (Einstellungen → Verzeichnisse)."
            )
            self.bulk_finished.emit(0, 0, 0)
            return

        quality = getattr(sm, "tmdbPosterQuality", "w500") or "w500"
        folders = self._collect_folders()
        total = len(folders)
        downloaded = skipped = errors = 0

        from tmdbv3api import Search

        for i, folder in enumerate(folders):
            if self._cancel_bulk:
                self.bulk_cancelled.emit()
                return

            name = folder.name
            self.bulk_progress.emit(i + 1, total, name)

            if self._poster_exists(image_dir, name):
                skipped += 1
                continue

            try:
                results = Search().multi(name)
                poster_path = None
                for r in results:
                    if getattr(r, "media_type", "") not in ("movie", "tv"):
                        continue
                    pp = getattr(r, "poster_path", None)
                    if pp:
                        poster_path = pp
                        break

                if not poster_path:
                    errors += 1
                else:
                    url = f"https://image.tmdb.org/t/p/{quality}{poster_path}"
                    dest = Path(image_dir) / f"{name}.jpg"
                    urllib.request.urlretrieve(url, str(dest))
                    downloaded += 1
            except Exception:
                errors += 1

            # Pause zwischen Anfragen, damit TMDB-Rate-Limit nicht überschritten wird
            time.sleep(0.3)

        self.bulk_finished.emit(downloaded, skipped, errors)
