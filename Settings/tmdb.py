from PySide6.QtCore import Signal, Property

POSTER_SIZES = ["w92", "w154", "w185", "w342", "w500", "w780", "original"]


class TmdbMixin:
    tmdbPosterQualityChanged = Signal()

    @Property(str, notify=tmdbPosterQualityChanged)
    def tmdbPosterQuality(self) -> str:
        return self._settings.value("tmdbPosterQuality", "w500", type=str)

    @tmdbPosterQuality.setter
    def tmdbPosterQuality(self, value: str):
        if value not in POSTER_SIZES:
            value = "w500"
        if self._settings.value("tmdbPosterQuality", "w500", type=str) != value:
            self._settings.setValue("tmdbPosterQuality", value)
            self._settings.sync()
            self.tmdbPosterQualityChanged.emit()