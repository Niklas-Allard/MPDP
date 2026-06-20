from PySide6.QtCore import QObject, QSettings, Slot

from Settings.base import SettingsBase
from Settings.appearance import AppearanceMixin
from Settings.tts import TTSMixin
from Settings.navigation import NavigationMixin
from Settings.media import MediaMixin
from Settings.screensaver import ScreensaverMixin
from Settings.directories import DirectoriesMixin
from Settings.regex_rules import RegexRulesMixin
from Settings.word_pronunciation import WordPronunciationMixin


class SettingsManager(
    AppearanceMixin,
    TTSMixin,
    WordPronunciationMixin,
    NavigationMixin,
    MediaMixin,
    ScreensaverMixin,
    DirectoriesMixin,
    RegexRulesMixin,
    SettingsBase,
    QObject,
):
    def __init__(self):
        super().__init__()
        self._settings = QSettings(self.ORG_NAME, self.APP_NAME)
        self._migrate_from_json_if_needed()

    @Slot()
    def reset_to_defaults(self):
        for key, default in self.DEFAULTS.items():
            self._settings.setValue(key, default)
        self._settings.sync()
        for sig in [
            self.cardMinWidthChanged, self.cardMinHeightChanged,
            self.fontScaleChanged, self.themeChanged,
            self.ttsEnabledChanged, self.ttsVoiceChanged,
            self.ttsRateChanged, self.ttsVolumeChanged,
            self.ttsDashPauseEnabledChanged, self.ttsDashPauseDurationChanged,
            self.clickSpeakDelayChanged,
            self.speakTriggerChanged, self.openTriggerChanged, self.hoverDelayChanged,
            self.showHiddenFilesChanged, self.sortOrderChanged, self.hideDisabledNavButtonsChanged,
            self.defaultVolumeChanged, self.resumePlaybackChanged,
            self.cursorHideTimeoutChanged, self.autoPlayNextChanged,
            self.announceNextFileChanged, self.autoPlayOnOpenChanged,
            self.screensaverEnabledChanged, self.screensaverTimeoutChanged,
            self.screensaverImageDirectoryChanged, self.screensaverImageIntervalChanged,
            self.wordPronunciationsChanged,
        ]:
            sig.emit()
