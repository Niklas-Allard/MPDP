from PySide6.QtCore import Slot


class RegexRulesMixin:
    def _write_regex_rules(self, rules: list):
        self._settings.remove("regex_rules")
        self._settings.beginWriteArray("regex_rules", len(rules))
        for i, rule in enumerate(rules):
            self._settings.setArrayIndex(i)
            self._settings.setValue("pattern", rule.get("pattern", ""))
            self._settings.setValue("replacement", rule.get("replacement", ""))
        self._settings.endArray()
        self._settings.sync()

    @Slot(result="QVariantList")
    def get_regex_rules(self) -> list:
        result = []
        size = self._settings.beginReadArray("regex_rules")
        for i in range(size):
            self._settings.setArrayIndex(i)
            result.append({
                "pattern": self._settings.value("pattern", "", type=str),
                "replacement": self._settings.value("replacement", "", type=str),
            })
        self._settings.endArray()
        return result

    @Slot(str, str)
    def add_regex_rule(self, pattern: str, replacement: str):
        rules = self.get_regex_rules()
        rules.append({"pattern": pattern, "replacement": replacement})
        self._write_regex_rules(rules)

    @Slot(int)
    def remove_regex_rule(self, index: int):
        rules = self.get_regex_rules()
        if 0 <= index < len(rules):
            rules.pop(index)
            self._write_regex_rules(rules)

    @Slot(int, str, str)
    def update_regex_rule(self, index: int, pattern: str, replacement: str):
        rules = self.get_regex_rules()
        if 0 <= index < len(rules):
            rules[index] = {"pattern": pattern, "replacement": replacement}
            self._write_regex_rules(rules)
