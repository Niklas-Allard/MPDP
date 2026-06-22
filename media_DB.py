from PySide6.QtCore import QObject, Slot, Signal
import sqlite3
import random
from pathlib import Path

class Media_DB(QObject):
    historyChanged = Signal()

    def __init__(self):
        super().__init__()
        db_path = Path(__file__).resolve().parent / "database" / "media.sqlite"
        db_path.parent.mkdir(parents=True, exist_ok=True)
        self._db_path = str(db_path)

        self._init_schema()

    def _init_schema(self):
        with sqlite3.connect(self._db_path) as con:
            con.executescript("""
            CREATE TABLE IF NOT EXISTS log (
                id INTEGER PRIMARY KEY,
                msg TEXT NOT NULL,
                created_at TEXT DEFAULT (datetime('now'))
            );

            CREATE TABLE IF NOT EXISTS media_progress (
                id INTEGER PRIMARY KEY,
                media_path TEXT NOT NULL UNIQUE,
                progress INTEGER NOT NULL,
                updated_at TEXT DEFAULT (datetime('now'))
            );

            CREATE TABLE IF NOT EXISTS watch_history (
                id INTEGER PRIMARY KEY,
                media_path TEXT NOT NULL UNIQUE,
                corresponding_media TEXT NOT NULL,
                created_at TEXT DEFAULT (datetime('now'))
            );

            CREATE TABLE IF NOT EXISTS shuffle_watched (
                id INTEGER PRIMARY KEY,
                folder_path TEXT NOT NULL,
                media_path TEXT NOT NULL,
                watched_at TEXT DEFAULT (datetime('now')),
                UNIQUE(folder_path, media_path)
            );
            """)

    @Slot(str)
    def log(self, msg: str):
        with sqlite3.connect(self._db_path) as con:
            con.execute("INSERT INTO log(msg) VALUES (?)", (msg,))

    @Slot(str, float)
    def set_progress(self, media_path: str, progress: float):
        with sqlite3.connect(self._db_path) as con:
            con.execute("""
                INSERT INTO media_progress(media_path, progress)
                VALUES (?, ?)
                ON CONFLICT(media_path) DO UPDATE SET
                    progress = excluded.progress,
                    updated_at = datetime('now')
            """, (media_path, progress))

    @Slot(str, result=int)
    def get_progress(self, media_path: str) -> int:
        with sqlite3.connect(self._db_path) as con:
            cur = con.execute("""
                SELECT progress FROM media_progress
                WHERE media_path = ?
            """, (media_path,))
            row = cur.fetchone()
            if row:
                return row[0]
            else:
                return 0.0

    @Slot(str)
    def add_to_history(self, path: str):
        file_path = Path(path)
        dir_path = file_path.parent

        paths = self.part_path_desc(str(dir_path.as_posix()))
        for p in paths:
            with sqlite3.connect(self._db_path) as con:
                con.execute("""
                    INSERT INTO watch_history(media_path, corresponding_media)
                    VALUES (?, ?)
                    ON CONFLICT(media_path) DO UPDATE SET
                        corresponding_media = excluded.corresponding_media,
                        created_at = datetime('now')
                """, (p, path))
        self.historyChanged.emit()

    @Slot(str, result=str)
    def get_last_played_in_folder(self, folder_path: str) -> str:
        posix_path = Path(folder_path).as_posix()
        with sqlite3.connect(self._db_path) as con:
            cur = con.execute(
                "SELECT corresponding_media FROM watch_history WHERE media_path = ?",
                (posix_path,)
            )
            row = cur.fetchone()
            return row[0] if row else ""

    @Slot(str, "QVariantList", result=str)
    def get_random_unwatched(self, folder_path: str, candidates: list) -> str:
        if not candidates:
            return ""
        folder_key = Path(folder_path).as_posix()
        candidate_set = {Path(c).as_posix() for c in candidates}

        with sqlite3.connect(self._db_path) as con:
            cur = con.execute(
                "SELECT media_path FROM shuffle_watched WHERE folder_path = ?",
                (folder_key,)
            )
            watched = {row[0] for row in cur.fetchall()}

            unwatched = candidate_set - watched
            if not unwatched:
                # Alle Folgen schon gesehen -> Zyklus zurücksetzen
                con.execute(
                    "DELETE FROM shuffle_watched WHERE folder_path = ?",
                    (folder_key,)
                )
                unwatched = candidate_set

        return random.choice(list(unwatched))

    @Slot(str, str)
    def mark_shuffle_watched(self, folder_path: str, media_path: str):
        folder_key = Path(folder_path).as_posix()
        media_key = Path(media_path).as_posix()
        with sqlite3.connect(self._db_path) as con:
            con.execute("""
                INSERT INTO shuffle_watched(folder_path, media_path)
                VALUES (?, ?)
                ON CONFLICT(folder_path, media_path) DO UPDATE SET
                    watched_at = datetime('now')
            """, (folder_key, media_key))

    def part_path_desc(self, path: str) -> list[str]:
        p = Path(path)

        stop = p.anchor

        result = []
        current = p
        while str(current) != stop and str(current) != ".":
            result.append(current.as_posix())
            if current.parent == current:
                break
            current = current.parent

        return result
