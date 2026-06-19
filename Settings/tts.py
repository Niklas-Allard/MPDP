from PySide6.QtCore import Signal, Property


class TTSMixin:
    ttsEnabledChanged = Signal()
    ttsVoiceChanged = Signal()
    ttsRateChanged = Signal()
    ttsVolumeChanged = Signal()
    ttsDashPauseEnabledChanged = Signal()
    ttsDashPauseDurationChanged = Signal()
    clickSpeakDelayChanged = Signal()

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

    @Property(bool, notify=ttsDashPauseEnabledChanged)
    def ttsDashPauseEnabled(self):
        return self._get("ttsDashPauseEnabled", bool)

    @ttsDashPauseEnabled.setter
    def ttsDashPauseEnabled(self, value):
        self._set("ttsDashPauseEnabled", bool(value), self.ttsDashPauseEnabledChanged)

    @Property(int, notify=ttsDashPauseDurationChanged)
    def ttsDashPauseDuration(self):
        return self._get("ttsDashPauseDuration", int)

    @ttsDashPauseDuration.setter
    def ttsDashPauseDuration(self, value):
        self._set("ttsDashPauseDuration", int(value), self.ttsDashPauseDurationChanged)

    @Property(int, notify=clickSpeakDelayChanged)
    def clickSpeakDelay(self):
        return self._get("clickSpeakDelay", int)

    @clickSpeakDelay.setter
    def clickSpeakDelay(self, value):
        self._set("clickSpeakDelay", int(value), self.clickSpeakDelayChanged)
