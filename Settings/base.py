from pathlib import Path


class SettingsBase:
    ORG_NAME = "MPDP"
    APP_NAME = "MediaPlayer"

    DEFAULTS = {
        "cardMinWidth": 150,
        "cardMinHeight": 150,
        "fontScale": 1.0,
        "theme": "light",
        "ttsEnabled": True,
        "ttsVoice": "",
        "ttsRate": 0.0,
        "ttsVolume": 1.0,
        "ttsDashPauseEnabled": True,
        "ttsDashPauseLevel": "short",
        "clickSpeakDelay": 400,
        "speakTrigger": "singleClick",
        "openTrigger": "doubleClick",
        "hoverDelay": 3000,
        "showHiddenFiles": False,
        "sortOrder": "name_asc",
        "hideDisabledNavButtons": False,
        "hideShuffleButton": False,
        "defaultVolume": 1.0,
        "resumePlayback": True,
        "cursorHideTimeout": 5000,
        "autoPlayNext": False,
        "announceNextFile": True,
        "autoPlayOnOpen": True,
        "screensaverEnabled": True,
        "screensaverTimeout": 120000,
        "screensaverImageDirectory": "",
        "screensaverImageInterval": 5000,
        "wordPronunciations": "[]",
        "tmdbPosterQuality": "w500",
    }

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

    def _migrate_from_json_if_needed(self):
        if self._settings.value("migrated_from_json", False, type=bool):
            return

        legacy_path = Path(__file__).resolve().parent.parent / "database" / "user_data.json"
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
        self._settings.setValue("global_image_directory", config.get("global_image_directory", ""))
        self._settings.setValue("migrated_from_json", True)
        self._settings.sync()
        print(f"[SettingsManager] {len(main_dirs)} Verzeichnisse aus JSON migriert.")

    def _get(self, key, type_):
        return self._settings.value(key, self.DEFAULTS[key], type=type_)

    def _set(self, key, value, signal):
        current = self._settings.value(key, self.DEFAULTS[key])
        if current != value:
            self._settings.setValue(key, value)
            self._settings.sync()
            signal.emit()
