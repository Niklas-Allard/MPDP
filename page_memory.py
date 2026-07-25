# This Python file uses the following encoding: utf-8
from PySide6.QtCore import QObject, Slot


class PageMemory(QObject):
    """Merkt sich pro Ordnerpfad die zuletzt angezeigte Seite im Dateibrowser.

    Nur im Arbeitsspeicher (nicht persistiert) - wird geleert, sobald sich die
    Kachelgröße ändert, da sich dann die Seitenzahl je Ordner verschiebt.
    """

    def __init__(self, settings_manager=None, parent=None):
        super().__init__(parent)
        self._pages = {}
        if settings_manager is not None:
            settings_manager.cardMinWidthChanged.connect(self.clear)
            settings_manager.cardMinHeightChanged.connect(self.clear)

    @Slot(str, result=int)
    def get_page(self, path):
        return self._pages.get(path, 0)

    @Slot(str, int)
    def set_page(self, path, page):
        self._pages[path] = page

    @Slot()
    def clear(self):
        self._pages = {}
