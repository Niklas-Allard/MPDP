from PySide6.QtCore import Signal, Property


class NavigationMixin:
    speakTriggerChanged = Signal()
    openTriggerChanged = Signal()
    hoverDelayChanged = Signal()
    showHiddenFilesChanged = Signal()
    sortOrderChanged = Signal()
    hideDisabledNavButtonsChanged = Signal()

    @Property(str, notify=speakTriggerChanged)
    def speakTrigger(self):
        return self._get("speakTrigger", str)

    @speakTrigger.setter
    def speakTrigger(self, value):
        self._set("speakTrigger", str(value), self.speakTriggerChanged)

    @Property(str, notify=openTriggerChanged)
    def openTrigger(self):
        return self._get("openTrigger", str)

    @openTrigger.setter
    def openTrigger(self, value):
        self._set("openTrigger", str(value), self.openTriggerChanged)

    @Property(int, notify=hoverDelayChanged)
    def hoverDelay(self):
        return self._get("hoverDelay", int)

    @hoverDelay.setter
    def hoverDelay(self, value):
        self._set("hoverDelay", int(value), self.hoverDelayChanged)

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
