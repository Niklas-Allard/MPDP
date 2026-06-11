from pathlib import Path
from PySide6.QtCore import QObject, QSettings, Slot, Signal, Property


class SettingsManager(QObject):
    """QSettings-basierte Konfigurationsverwaltung.

    Properties (Qt Property) ermöglichen Live-Binding aus QML.
    Beim ersten Start werden vorhandene JSON-Daten einmalig migriert.
    """

    ORG_NAME = "MPDP"
    APP_NAME = "MediaPlayer"

    # ---- Signals (bestehend) -------------------------------------------------
    main_directories_changed = Signal()
    global_image_directory_changed = Signal()

    # ---- Signals (neu, je Property) ------------------------------------------
    cardMinWidthChanged = Signal()
    cardMinHeightChanged = Signal()
    fontScaleChanged = Signal()
    themeChanged = Signal()

    ttsEnabledChanged = Signal()
    ttsVoiceChanged = Signal()
    ttsRateChanged = Signal()
    ttsVolumeChanged = Signal()
    clickSpeakDelayChanged = Signal()

    openOnSingleClickChanged = Signal()
    showHiddenFilesChanged = Signal()
    sortOrderChanged = Signal()
    hideDisabledNavButtonsChanged = Signal()

    defaultVolumeChanged = Signal()
    resumePlaybackChanged = Signal()
    cursorHideTimeoutChanged = Signal()
    autoPlayNextChanged = Signal()
    announceNextFileChanged = Signal()
    autoPlayOnOpenChanged = Signal()

    DEFAULTS = {
        # Darstellung
        "cardMinWidth": 150,
        "cardMinHeight": 150,
        "fontScale": 1.0,
        "theme": "light",  # "light" | "dark" | "highContrast"
        # Sprachausgabe
        "ttsEnabled": True,
        "ttsVoice": "",
        "ttsRate": 0.0,        # -1.0 .. 1.0
        "ttsVolume": 1.0,      # 0.0 .. 1.0
        "clickSpeakDelay": 400,  # ms
        # Navigation
        "openOnSingleClick": False,
        "showHiddenFiles": False,
        "sortOrder": "name_asc",  # name_asc | name_desc | date_desc | size_desc
        "hideDisabledNavButtons": False,  # deaktivierte Blättern-Buttons unsichtbar (Platz bleibt)
        # Wiedergabe
        "defaultVolume": 1.0,
        "resumePlayback": True,
        "cursorHideTimeout": 5000,  # ms
        "autoPlayNext": False,
        "announceNextFile": True,   # nächste Folge per TTS ansagen
        "autoPlayOnOpen": True,     # Video beim Öffnen sofort abspielen
    }

    # Farbpaletten je Theme. Werden über die color*-Properties an QML
    # weitergereicht (Window.palette + explizite Text-/Karten-Farben).
    THEME_PALETTES = {
        "light": {
            "background": "#f5f5f5",
            "text": "#202020",
            "base": "#ffffff",
            "button": "#e0e0e0",
            "accent": "#1976d2",
            "cardDirectory": "#e3f2fd",
            "cardFile": "#f0f0f0",
            "cardBorder": "#dddddd",
            "cardText": "#202020",
        },
        "dark": {
            "background": "#121212",
            "text": "#ffffff",
            "base": "#1e1e1e",
            "button": "#2d2d2d",
            "accent": "#bb86fc",
            "cardDirectory": "#1e3a5f",
            "cardFile": "#2a2a2a",
            "cardBorder": "#444444",
            "cardText": "#ffffff",
        },
        "highContrast": {
            "background": "#000000",
            "text": "#ffff00",
            "base": "#000000",
            "button": "#000000",
            "accent": "#ffff00",
            "cardDirectory": "#000000",
            "cardFile": "#000000",
            "cardBorder": "#ffffff",
            "cardText": "#ffff00",
        },
    }

    def __init__(self):
        super().__init__()
        self._settings = QSettings(self.ORG_NAME, self.APP_NAME)
        self._migrate_from_json_if_needed()

    # ---- Migration -----------------------------------------------------------
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

    # ---- generische Helfer ---------------------------------------------------
    def _get(self, key, type_):
        return self._settings.value(key, self.DEFAULTS[key], type=type_)

    def _set(self, key, value, signal):
        current = self._settings.value(key, self.DEFAULTS[key])
        if current != value:
            self._settings.setValue(key, value)
            self._settings.sync()
            signal.emit()

    # ---- Hauptverzeichnisse (bestehend) --------------------------------------
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

    # ---- Darstellung ---------------------------------------------------------
    @Property(int, notify=cardMinWidthChanged)
    def cardMinWidth(self):
        return self._get("cardMinWidth", int)

    @cardMinWidth.setter
    def cardMinWidth(self, value):
        self._set("cardMinWidth", int(value), self.cardMinWidthChanged)

    @Property(int, notify=cardMinHeightChanged)
    def cardMinHeight(self):
        return self._get("cardMinHeight", int)

    @cardMinHeight.setter
    def cardMinHeight(self, value):
        self._set("cardMinHeight", int(value), self.cardMinHeightChanged)

    @Property(float, notify=fontScaleChanged)
    def fontScale(self):
        return self._get("fontScale", float)

    @fontScale.setter
    def fontScale(self, value):
        self._set("fontScale", float(value), self.fontScaleChanged)

    @Property(str, notify=themeChanged)
    def theme(self):
        return self._get("theme", str)

    @theme.setter
    def theme(self, value):
        self._set("theme", str(value), self.themeChanged)

    # ---- abgeleitete Theme-Farben (read-only, ändern sich mit dem Theme) -----
    def _theme_color(self, key: str) -> str:
        theme = self._get("theme", str)
        palette = self.THEME_PALETTES.get(theme, self.THEME_PALETTES["light"])
        return palette[key]

    @Property(str, notify=themeChanged)
    def colorBackground(self):
        return self._theme_color("background")

    @Property(str, notify=themeChanged)
    def colorText(self):
        return self._theme_color("text")

    @Property(str, notify=themeChanged)
    def colorBase(self):
        return self._theme_color("base")

    @Property(str, notify=themeChanged)
    def colorButton(self):
        return self._theme_color("button")

    @Property(str, notify=themeChanged)
    def colorAccent(self):
        return self._theme_color("accent")

    @Property(str, notify=themeChanged)
    def colorCardDirectory(self):
        return self._theme_color("cardDirectory")

    @Property(str, notify=themeChanged)
    def colorCardFile(self):
        return self._theme_color("cardFile")

    @Property(str, notify=themeChanged)
    def colorCardBorder(self):
        return self._theme_color("cardBorder")

    @Property(str, notify=themeChanged)
    def colorCardText(self):
        return self._theme_color("cardText")

    # ---- Sprachausgabe -------------------------------------------------------
    @Property(bool, notify=ttsEnabledChanged)
    def ttsEnabled(self):
        return self._get("ttsEnabled", bool)

    @ttsEnabled.setter
    def ttsEnabled(self, value):
        self._set("ttsEnabled", bool(value), self.ttsEnabledChanged)

    @Property(str, notify=ttsVoiceChanged)
    def ttsVoice(self):
        return self._get("ttsVoice", str)

    @ttsVoice.setter
    def ttsVoice(self, value):
        self._set("ttsVoice", str(value), self.ttsVoiceChanged)

    @Property(float, notify=ttsRateChanged)
    def ttsRate(self):
        return self._get("ttsRate", float)

    @ttsRate.setter
    def ttsRate(self, value):
        self._set("ttsRate", float(value), self.ttsRateChanged)

    @Property(float, notify=ttsVolumeChanged)
    def ttsVolume(self):
        return self._get("ttsVolume", float)

    @ttsVolume.setter
    def ttsVolume(self, value):
        self._set("ttsVolume", float(value), self.ttsVolumeChanged)

    @Property(int, notify=clickSpeakDelayChanged)
    def clickSpeakDelay(self):
        return self._get("clickSpeakDelay", int)

    @clickSpeakDelay.setter
    def clickSpeakDelay(self, value):
        self._set("clickSpeakDelay", int(value), self.clickSpeakDelayChanged)

    # ---- Navigation ----------------------------------------------------------
    @Property(bool, notify=openOnSingleClickChanged)
    def openOnSingleClick(self):
        return self._get("openOnSingleClick", bool)

    @openOnSingleClick.setter
    def openOnSingleClick(self, value):
        self._set("openOnSingleClick", bool(value), self.openOnSingleClickChanged)

    @Property(bool, notify=showHiddenFilesChanged)
    def showHiddenFiles(self):
        return self._get("showHiddenFiles", bool)

    @showHiddenFiles.setter
    def showHiddenFiles(self, value):
        self._set("showHiddenFiles", bool(value), self.showHiddenFilesChanged)

    @Property(str, notify=sortOrderChanged)
    def sortOrder(self):
        return self._get("sortOrder", str)

    @sortOrder.setter
    def sortOrder(self, value):
        self._set("sortOrder", str(value), self.sortOrderChanged)

    @Property(bool, notify=hideDisabledNavButtonsChanged)
    def hideDisabledNavButtons(self):
        return self._get("hideDisabledNavButtons", bool)

    @hideDisabledNavButtons.setter
    def hideDisabledNavButtons(self, value):
        self._set("hideDisabledNavButtons", bool(value), self.hideDisabledNavButtonsChanged)

    # ---- Wiedergabe ----------------------------------------------------------
    @Property(float, notify=defaultVolumeChanged)
    def defaultVolume(self):
        return self._get("defaultVolume", float)

    @defaultVolume.setter
    def defaultVolume(self, value):
        self._set("defaultVolume", float(value), self.defaultVolumeChanged)

    @Property(bool, notify=resumePlaybackChanged)
    def resumePlayback(self):
        return self._get("resumePlayback", bool)

    @resumePlayback.setter
    def resumePlayback(self, value):
        self._set("resumePlayback", bool(value), self.resumePlaybackChanged)

    @Property(int, notify=cursorHideTimeoutChanged)
    def cursorHideTimeout(self):
        return self._get("cursorHideTimeout", int)

    @cursorHideTimeout.setter
    def cursorHideTimeout(self, value):
        self._set("cursorHideTimeout", int(value), self.cursorHideTimeoutChanged)

    @Property(bool, notify=autoPlayNextChanged)
    def autoPlayNext(self):
        return self._get("autoPlayNext", bool)

    @autoPlayNext.setter
    def autoPlayNext(self, value):
        self._set("autoPlayNext", bool(value), self.autoPlayNextChanged)

    @Property(bool, notify=announceNextFileChanged)
    def announceNextFile(self):
        return self._get("announceNextFile", bool)

    @announceNextFile.setter
    def announceNextFile(self, value):
        self._set("announceNextFile", bool(value), self.announceNextFileChanged)

    @Property(bool, notify=autoPlayOnOpenChanged)
    def autoPlayOnOpen(self):
        return self._get("autoPlayOnOpen", bool)

    @autoPlayOnOpen.setter
    def autoPlayOnOpen(self, value):
        self._set("autoPlayOnOpen", bool(value), self.autoPlayOnOpenChanged)

    # ---- Reset ---------------------------------------------------------------
    @Slot()
    def reset_to_defaults(self):
        """Setzt alle einzelnen Einstellungen auf Defaults zurück
        (Hauptverzeichnisse und globales Bilderverzeichnis bleiben unangetastet)."""
        for key, default in self.DEFAULTS.items():
            self._settings.setValue(key, default)
        self._settings.sync()
        # alle Signals feuern
        for sig in [
            self.cardMinWidthChanged, self.cardMinHeightChanged,
            self.fontScaleChanged, self.themeChanged,
            self.ttsEnabledChanged, self.ttsVoiceChanged,
            self.ttsRateChanged, self.ttsVolumeChanged,
            self.clickSpeakDelayChanged,
            self.openOnSingleClickChanged, self.showHiddenFilesChanged,
            self.sortOrderChanged, self.hideDisabledNavButtonsChanged,
            self.defaultVolumeChanged, self.resumePlaybackChanged,
            self.cursorHideTimeoutChanged, self.autoPlayNextChanged,
            self.announceNextFileChanged, self.autoPlayOnOpenChanged,
        ]:
            sig.emit()
