# 🎬 MPDP (Media Player For Disabled People)

![Python](https://img.shields.io/badge/Python-3.x-blue?style=for-the-badge&logo=python)
![PySide6](https://img.shields.io/badge/PySide6-Qt_Quick-41CD52?style=for-the-badge&logo=qt)
![SQLite](https://img.shields.io/badge/SQLite-Database-003B57?style=for-the-badge&logo=sqlite)

**MPDP** ist eine Desktop-Anwendung, die entwickelt wurde, um Menschen mit Behinderungen ein zugängliches, inklusives und intuitives Medienwiedergabe-Erlebnis zu bieten. 
Das Projekt kombiniert eine leistungsstarke Python-Backend-Logik mit einer modernen, reaktionsschnellen Qt Quick (QML) Benutzeroberfläche.

---

## ✨ Hauptfunktionen

- ♿ **Barrierefreiheit im Fokus**: Speziell entwickelt für eine einfache und intuitive Bedienung.
- 📁 **Integrierter Datei-Browser**: Reibungslose Navigation durch lokale Medien.
- ⏯️ **Smarte Medienwiedergabe**: Automatische Speicherung des Wiedergabefortschritts und Verwaltung des Wiedergabeverlaufs (Watch History).
- 🎨 **Theme-Unterstützung**: Anpassbare Benutzeroberfläche durch JSON-basierte Themes (z. B. `classic.json`).
- 💾 **Lokale Datenbank**: Effiziente Datenspeicherung (Logs, Fortschritt, Historie) mittels SQLite.

---

## 🛠️ Technologie-Stack

- **Frontend**: Qt 6 / QML (Qt Quick) für flüssige und moderne UI-Komponenten.
- **Backend**: Python 3 mit PySide6.
- **Datenbank**: SQLite (`media.sqlite` für History & Fortschritt).
- **Konfiguration**: JSON (User-Data & Themes).

---

## 🏗️ Projektarchitektur

Das Projekt ist in klar strukturierte Module unterteilt, die Frontend und Backend trennen:

*   **`main.py`**: Der Haupteinstiegspunkt. Initialisiert die App, lädt die QML-Engine und verbindet Python-Logik mit dem Frontend.
*   **`media_DB.py`**: Interagiert mit der SQLite-Datenbank (Speichert den Wiedergabestatus, Historie und Logs).
*   **`fileHandler.py`**: Übernimmt die Navigation und Verwaltung von Dateien im System.
*   **`theme.py`**: Steuert die visuelle Darstellung und Themes.
*   **Ordnerstruktur (QML)**:
    *   `StartPage/` - Der Startbildschirm der Anwendung.
    *   `FileBrowser/` - Visuelle Darstellung des Dateimanagements.
    *   `MultiMediaPlayer/` - Die eigentlichen Player-Controls und das Interface.

---

## 🚀 Installation & Start

### Voraussetzungen
- Python 3 installiert
- Git (optional, zum Klonen des Repos)

### Schritt-für-Schritt Anleitung

1. **Repository klonen**
   ```bash
   git clone https://github.com/Niklas-Allard/MPDP.git
   cd MPDP
   ```

2. **Virtuelle Umgebung erstellen und aktivieren (Empfohlen)**
   *Windows:*
   ```bash
   python -m venv .venv
   .venv\Scripts\Activate.ps1
   ```
   *Linux/macOS:*
   ```bash
   python3 -m venv .venv
   source .venv/bin/activate
   ```

3. **Abhängigkeiten installieren**
   ```bash
   pip install -r requirements.txt
   ```

4. **Anwendung starten**
   ```bash
   python main.py
   ```

---

## 🧑‍💻 Entwicklung & Build

- **Signale & Slots**: Das Projekt nutzt den Signal-Slot-Mechanismus von Qt, um nahtlos zwischen Python und QML zu kommunizieren. (Kontext-Properties wie `fileManager` und `media_DB` sind direkt in QML verfügbar).
- **Ressourcen**: Grafiken und Icons werden über die kompilierte Ressourcen-Datei `resources.rcc` geladen.
- **Build für Deployment**: Die App kann mithilfe der `pysidedeploy.spec` Konfiguration für die Veröffentlichung gebaut werden.

---

## 🤝 Mitwirken (Contributing)

Da dieses Projekt auf Barrierefreiheit abzielt, sind Vorschläge zur Verbesserung der Accessibility (z. B. Screen-Reader-Kompatibilität, Kontrast-Updates oder Navigations-Erleichterungen) besonders willkommen!
Erstelle gerne ein Issue oder eröffne einen Pull Request.