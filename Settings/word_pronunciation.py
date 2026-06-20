import json
from PySide6.QtCore import Signal, Property, Slot


class WordPronunciationMixin:
    wordPronunciationsChanged = Signal()

    @Property(str, notify=wordPronunciationsChanged)
    def wordPronunciations(self):
        return self._get("wordPronunciations", str)

    @wordPronunciations.setter
    def wordPronunciations(self, value: str):
        self._set("wordPronunciations", str(value), self.wordPronunciationsChanged)

    @Slot(str, str)
    def addWordPronunciation(self, word: str, voice: str):
        try:
            entries = json.loads(self._get("wordPronunciations", str) or "[]")
        except (ValueError, TypeError):
            entries = []
        entries = [e for e in entries if e.get("word", "").lower() != word.lower()]
        entries.append({"word": word, "voice": voice})
        self.wordPronunciations = json.dumps(entries, ensure_ascii=False)

    @Slot(str)
    def removeWordPronunciation(self, word: str):
        try:
            entries = json.loads(self._get("wordPronunciations", str) or "[]")
        except (ValueError, TypeError):
            entries = []
        entries = [e for e in entries if e.get("word", "").lower() != word.lower()]
        self.wordPronunciations = json.dumps(entries, ensure_ascii=False)
