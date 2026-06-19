from PySide6.QtCore import Signal, Property


class AppearanceMixin:
    cardMinWidthChanged = Signal()
    cardMinHeightChanged = Signal()
    fontScaleChanged = Signal()
    themeChanged = Signal()

    @Property(int, notify=cardMinWidthChanged)
    def cardMinWidth(self):
        return self._get("cardMinWidth", int)

    @cardMinWidth.setter
    def cardMinWidth(self, value):
        self._set("cardMinWidth", int(value), self.cardMinWidthChanged)

    @Property(int, notify=cardMinHeightChanged)
    def cardMinHeight(self):
        return self._get("cardMinHeight", int)

    @cardMinHeight.setter
    def cardMinHeight(self, value):
        self._set("cardMinHeight", int(value), self.cardMinHeightChanged)

    @Property(float, notify=fontScaleChanged)
    def fontScale(self):
        return self._get("fontScale", float)

    @fontScale.setter
    def fontScale(self, value):
        self._set("fontScale", float(value), self.fontScaleChanged)

    @Property(str, notify=themeChanged)
    def theme(self):
        return self._get("theme", str)

    @theme.setter
    def theme(self, value):
        self._set("theme", str(value), self.themeChanged)

    def _theme_color(self, key: str) -> str:
        theme = self._get("theme", str)
        palette = self.THEME_PALETTES.get(theme, self.THEME_PALETTES["light"])
        return palette[key]

    @Property(str, notify=themeChanged)
    def colorBackground(self):
        return self._theme_color("background")

    @Property(str, notify=themeChanged)
    def colorText(self):
        return self._theme_color("text")

    @Property(str, notify=themeChanged)
    def colorBase(self):
        return self._theme_color("base")

    @Property(str, notify=themeChanged)
    def colorButton(self):
        return self._theme_color("button")

    @Property(str, notify=themeChanged)
    def colorAccent(self):
        return self._theme_color("accent")

    @Property(str, notify=themeChanged)
    def colorCardDirectory(self):
        return self._theme_color("cardDirectory")

    @Property(str, notify=themeChanged)
    def colorCardFile(self):
        return self._theme_color("cardFile")

    @Property(str, notify=themeChanged)
    def colorCardBorder(self):
        return self._theme_color("cardBorder")

    @Property(str, notify=themeChanged)
    def colorCardText(self):
        return self._theme_color("cardText")
