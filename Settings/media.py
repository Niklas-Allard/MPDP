from PySide6.QtCore import Signal, Property


class MediaMixin:
    defaultVolumeChanged = Signal()
    resumePlaybackChanged = Signal()
    cursorHideTimeoutChanged = Signal()
    autoPlayNextChanged = Signal()
    announceNextFileChanged = Signal()
    autoPlayOnOpenChanged = Signal()

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
