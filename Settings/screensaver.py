import os
from pathlib import Path
from PySide6.QtCore import Signal, Property, Slot


class ScreensaverMixin:
    screensaverEnabledChanged = Signal()
    screensaverTimeoutChanged = Signal()
    screensaverImageDirectoryChanged = Signal()
    screensaverImageIntervalChanged = Signal()

    @Property(bool, notify=screensaverEnabledChanged)
    def screensaverEnabled(self):
        return self._get("screensaverEnabled", bool)

    @screensaverEnabled.setter
    def screensaverEnabled(self, value):
        self._set("screensaverEnabled", bool(value), self.screensaverEnabledChanged)

    @Property(int, notify=screensaverTimeoutChanged)
    def screensaverTimeout(self):
        return self._get("screensaverTimeout", int)

    @screensaverTimeout.setter
    def screensaverTimeout(self, value):
        self._set("screensaverTimeout", int(value), self.screensaverTimeoutChanged)

    @Property(str, notify=screensaverImageDirectoryChanged)
    def screensaverImageDirectory(self):
        return self._get("screensaverImageDirectory", str)

    @screensaverImageDirectory.setter
    def screensaverImageDirectory(self, value):
        self._set("screensaverImageDirectory", str(value), self.screensaverImageDirectoryChanged)

    @Property(int, notify=screensaverImageIntervalChanged)
    def screensaverImageInterval(self):
        return self._get("screensaverImageInterval", int)

    @screensaverImageInterval.setter
    def screensaverImageInterval(self, value):
        self._set("screensaverImageInterval", int(value), self.screensaverImageIntervalChanged)

    @Slot(result="QVariantList")
    def get_screensaver_images(self) -> list:
        directory = self._get("screensaverImageDirectory", str)
        if not directory:
            return []
        image_extensions = {".jpg", ".jpeg", ".png", ".gif", ".bmp", ".webp"}
        try:
            files = sorted(
                Path(directory) / f
                for f in os.listdir(directory)
                if Path(f).suffix.lower() in image_extensions
            )
            return [p.as_uri() for p in files if p.is_file()]
        except OSError:
            return []
