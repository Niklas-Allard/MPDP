from PySide6.QtCore import QObject, Signal, QEvent


class ActivityMonitor(QObject):
    """Globaler Aktivitäts-Detektor: fängt Maus- und Tastatur-Events app-weit ab."""

    activity_detected = Signal()

    def __init__(self, app):
        super().__init__(app)
        app.installEventFilter(self)

    def eventFilter(self, obj, event) -> bool:
        if event.type() in (
            QEvent.Type.MouseMove,
            QEvent.Type.MouseButtonPress,
            QEvent.Type.KeyPress,
            QEvent.Type.TouchBegin,
            QEvent.Type.TouchUpdate,
        ):
            self.activity_detected.emit()
        return False
