import re
from PySide6.QtCore import QObject, Slot, Signal


class RegexFilter(QObject):
    """Applies a list of regex substitution rules sequentially to TTS text."""

    rules_changed = Signal()

    def __init__(self, settings_manager):
        super().__init__()
        self._sm = settings_manager

    @Slot(str, result=str)
    def apply(self, text: str) -> str:
        for rule in self._sm.get_regex_rules():
            pattern = rule.get("pattern", "")
            replacement = rule.get("replacement", "")
            if not pattern:
                continue
            try:
                text = re.sub(pattern, replacement, text)
            except re.error:
                pass
        return text

    @Slot(result="QVariantList")
    def get_rules(self) -> list:
        return self._sm.get_regex_rules()

    @Slot(str, str)
    def add_rule(self, pattern: str, replacement: str):
        self._sm.add_regex_rule(pattern, replacement)
        self.rules_changed.emit()

    @Slot(int)
    def remove_rule(self, index: int):
        self._sm.remove_regex_rule(index)
        self.rules_changed.emit()

    @Slot(int, str, str)
    def update_rule(self, index: int, pattern: str, replacement: str):
        self._sm.update_regex_rule(index, pattern, replacement)
        self.rules_changed.emit()

    @Slot(str, result=bool)
    def validate_pattern(self, pattern: str) -> bool:
        try:
            re.compile(pattern)
            return True
        except re.error:
            return False
