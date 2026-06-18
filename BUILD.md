# MPDP – Build-Anleitung

Dieses Dokument beschreibt vollständig, wie MPDP für **Windows**, **macOS** und **Linux** auf allen gängigen Prozessorarchitekturen gebaut wird.

---

## Inhaltsverzeichnis

1. [Grundlagen & Architektur-Prinzip](#1-grundlagen--architektur-prinzip)
2. [Voraussetzungen](#2-voraussetzungen)
3. [Qt-Module und Plugins](#3-qt-module-und-plugins)
4. [Lokaler Build (Development)](#4-lokaler-build-development)
   - [Windows x64](#41-windows-x64)
   - [Windows ARM64](#42-windows-arm64)
   - [macOS Intel (x86\_64)](#43-macos-intel-x86_64)
   - [macOS Apple Silicon (arm64)](#44-macos-apple-silicon-arm64)
   - [macOS Universal Binary](#45-macos-universal-binary)
   - [Linux x86\_64](#46-linux-x86_64)
   - [Linux aarch64 (ARM64)](#47-linux-aarch64-arm64)
5. [CI/CD mit GitHub Actions](#5-cicd-mit-github-actions)
6. [Build-Konfigurationsdateien](#6-build-konfigurationsdateien)
7. [Externe Datendateien & Ressourcen](#7-externe-datendateien--ressourcen)
8. [Häufige Probleme & Lösungen](#8-häufige-probleme--lösungen)
9. [Glossar](#9-glossar)

---

## 1. Grundlagen & Architektur-Prinzip

### Kein echtes Cross-Compiling

`pyside6-deploy` und Nuitka unterstützen **kein echtes Cross-Compilation** für Qt-Anwendungen. Das bedeutet:

> **Jede Zielplattform muss nativ gebaut werden.**

| Zielplattform   | Anforderung                                         |
|-----------------|-----------------------------------------------------|
| Windows x64     | Windows-Maschine mit x64-Python + PySide6           |
| Windows ARM64   | Windows-Maschine mit ARM64-Python + PySide6         |
| macOS Intel     | macOS-Maschine mit Intel-CPU oder mit `--macos-target-arch` |
| macOS ARM64     | macOS-Maschine mit Apple Silicon (M1/M2/M3)         |
| macOS Universal | macOS-Maschine (beide Architekturen via `lipo`)     |
| Linux x86\_64   | Linux auf x86_64 (nativ oder VM/Container)          |
| Linux aarch64   | Linux auf aarch64 (nativ oder QEMU-Container)       |

Die praktische Lösung dafür ist eine **CI/CD-Pipeline** (z. B. GitHub Actions), die alle Zielplattformen gleichzeitig baut. Die fertige Pipeline liegt unter `.github/workflows/build.yml`.

### Build-Werkzeuge

| Werkzeug         | Rolle                                                        |
|------------------|--------------------------------------------------------------|
| `pyside6-deploy` | Frontends für Nuitka; analysiert Qt-Abhängigkeiten automatisch |
| `Nuitka`         | Kompiliert Python-Code zu nativem C-Code und bindet Qt ein   |
| `rcc`            | Qt Resource Compiler: wandelt `.qrc` zu `.rcc` um            |

---

## 2. Voraussetzungen

### Alle Plattformen

- **Python 3.11 oder 3.12** (empfohlen: 3.12)
  - Wichtig: Python-Version muss zur Zielarchitektur passen
- **PySide6** (aktuell: 6.8.x oder neuer)
- **Nuitka** (aktuell: 2.7.x)
- **Git**

### Windows

```powershell
# Visual Studio Build Tools (C++-Compiler für Nuitka)
winget install Microsoft.VisualStudio.2022.BuildTools

# Alternativ: MinGW oder LLVM/Clang
# Zig-Compiler (optional, aber empfohlen für Nuitka)
winget install ziglang.zig
```

### macOS

```bash
# Xcode Command Line Tools (beinhaltet clang)
xcode-select --install

# Homebrew (empfohlen für Abhängigkeiten)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Linux (Ubuntu/Debian)

```bash
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    libglib2.0-dev \
    libgl1-mesa-dev \
    libegl1-mesa-dev \
    libxcb-xinerama0 \
    libxcb-cursor0 \
    libxkbcommon-x11-0 \
    libxcb-keysyms1 \
    libxcb-icccm4 \
    libxcb-image0 \
    libxcb-randr0 \
    libxcb-render-util0 \
    libdbus-1-dev \
    libasound2-dev \
    libpulse-dev \
    libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev \
    speech-dispatcher \
    libspeechd-dev \
    patchelf \
    ccache
```

### Linux (Fedora/RHEL)

```bash
sudo dnf install -y \
    gcc gcc-c++ \
    glib2-devel \
    mesa-libGL-devel \
    mesa-libEGL-devel \
    libxcb-devel \
    libxkbcommon-x11-devel \
    dbus-devel \
    alsa-lib-devel \
    pulseaudio-libs-devel \
    gstreamer1-devel \
    gstreamer1-plugins-base-devel \
    speech-dispatcher-devel \
    patchelf
```

---

## 3. Qt-Module und Plugins

### Verwendete Qt-Module

Die App benötigt folgende Qt-Module (in `pysidedeploy.spec` unter `[qt] modules`):

| Modul              | Verwendung                                          |
|--------------------|-----------------------------------------------------|
| `Core`             | QObject, QSettings, QResource, QFile               |
| `Gui`              | QGuiApplication, Fenster-System                    |
| `Qml`              | QML-Engine, QQmlApplicationEngine                  |
| `Quick`            | Qt Quick (visuelle QML-Elemente)                   |
| `QuickControls2`   | Material-Stil, Button, Slider, ComboBox, etc.      |
| `Multimedia`       | MediaPlayer, VideoOutput, AudioOutput              |
| `TextToSpeech`     | Barrierefreiheit – Sprachausgabe                   |
| `Concurrent`       | Interne Qt-Threading-Hilfsmittel                   |
| `Network`          | Interne Qt-Netzwerkschicht                         |

### Qt-Plugins

Plugins werden von Qt beim Start dynamisch geladen. Fehlende Plugins führen zu Laufzeitfehlern.

| Plugin-Verzeichnis       | Zweck                                              | Windows | macOS | Linux |
|--------------------------|---------------------------------------------------|---------|-------|-------|
| `accessiblebridge`       | Screenreader-Unterstützung (AT-SPI, MSAA)         | ✓       | ✓     | ✓     |
| `generic`                | Generische Eingabe (Evdev auf Linux)              | ✓       | ✓     | ✓     |
| `iconengines`            | SVG-Icons (qsvgicon.dll/.so/.dylib)               | ✓       | ✓     | ✓     |
| `imageformats`           | Bildformate: PNG, JPG, SVG, WebP                  | ✓       | ✓     | ✓     |
| `multimedia`             | Medien-Backend (FFmpeg / WMF / AVFoundation)      | ✓       | ✓     | ✓     |
| `platforminputcontexts`  | Eingabemethoden / IME                             | ✓       | ✓     | ✓     |
| `platforms`              | Fenstersystem (windows/cocoa/xcb/wayland)         | ✓       | ✓     | ✓     |
| `platformthemes`         | Native Themes (GTK auf Linux)                     | –       | –     | ✓     |
| `qmllint`                | QML-Linting                                       | ✓       | ✓     | ✓     |
| `qmltooling`             | QML-Debugging                                     | ✓       | ✓     | ✓     |
| `scenegraph`             | Qt Quick Scene-Graph (OpenGL/Vulkan)              | ✓       | ✓     | ✓     |
| `tls`                    | TLS/SSL (für interne Qt-Verbindungen)             | ✓       | ✓     | ✓     |
| `wayland`                | Wayland-Backend (nur Linux)                       | –       | –     | ✓     |

### Ausgeschlossene QML-Plugins

Diese Module werden im Projekt nicht verwendet und sind vom Build ausgeschlossen, um die Binary-Größe zu reduzieren:

```
QtCharts, QtSensors, QtWebEngine, QtWebView, Qt3D, QtLocation, QtQuick3D, QtDataVisualization
```

---

## 4. Lokaler Build (Development)

### Virtuelles Environment einrichten (einmalig)

```bash
# Python-venv anlegen
python3 -m venv .venv

# Aktivieren
# Windows (PowerShell):
.venv\Scripts\Activate.ps1
# macOS / Linux:
source .venv/bin/activate

# Pakete installieren
pip install PySide6 Nuitka
```

### 4.1 Windows x64

**Voraussetzungen:** Windows 10/11 (x64), Python 3.12 x64, Visual Studio Build Tools oder LLVM

```powershell
# 1. venv aktivieren
.venv\Scripts\Activate.ps1

# 2. resources.rcc sicherstellen (falls noch nicht vorhanden)
# rcc.exe liegt im PySide6-Paket:
$rcc = python -c "import PySide6, os; print(os.path.join(os.path.dirname(PySide6.__file__), 'rcc.exe'))"
& $rcc -binary resources.qrc -o resources.rcc

# 3. Bauen
python -m pyside6deploy -c pysidedeploy.spec --verbose

# 4. Ergebnis
# dist\MPDP.exe  (onefile – alles in einer EXE)
```

**Konfigurationsdatei:** `pysidedeploy.spec` (Projektroot)

**Ausgabe:** `dist\main.exe` (umbenennen in `MPDP-windows-x64.exe`)

---

### 4.2 Windows ARM64

**Voraussetzungen:** Windows 11 ARM64-Gerät (z. B. Surface Pro X, Snapdragon X Elite), Python 3.12 ARM64

> **Wichtig:** Python für ARM64 muss separat heruntergeladen werden:
> https://www.python.org/downloads/windows/ → „ARM64 installer"

```powershell
# 1. ARM64-Python-venv anlegen (expliziter Pfad zur ARM64-Python.exe)
C:\Users\...\AppData\Local\Programs\Python\Python312-arm64\python.exe -m venv .venv

# 2. PySide6 + Nuitka (ARM64-kompatible Wheels werden automatisch gewählt)
.venv\Scripts\pip install PySide6 Nuitka

# 3. resources.rcc sicherstellen
$rcc = .venv\Scripts\python.exe -c "import PySide6, os; print(os.path.join(os.path.dirname(PySide6.__file__), 'rcc.exe'))"
& $rcc -binary resources.qrc -o resources.rcc

# 4. Bauen mit ARM64-spezifischer Konfiguration
.venv\Scripts\python.exe -m pyside6deploy -c build\pysidedeploy-windows-arm64.spec --verbose
```

**Konfigurationsdatei:** `build\pysidedeploy-windows-arm64.spec`

**Ausgabe:** `dist\main.exe` (ARM64-Binary)

---

### 4.3 macOS Intel (x86\_64)

**Voraussetzungen:** Mac mit Intel-CPU (oder Cross-Build via `--macos-target-arch`), macOS 12+, Xcode CLI Tools

```bash
# 1. venv aktivieren
source .venv/bin/activate

# 2. resources.rcc sicherstellen
RCC=$(python3 -c "import PySide6, os; print(os.path.join(os.path.dirname(PySide6.__file__), 'rcc'))")
"$RCC" -binary resources.qrc -o resources.rcc

# 3. Bauen (nur x86_64)
python3 -m pyside6deploy -c build/pysidedeploy-macos.spec --verbose

# 4. Ergebnis: dist/MPDP.app  (App Bundle)
```

**Konfigurationsdatei:** `build/pysidedeploy-macos.spec`

**Ausgabe:** `dist/MPDP.app` (macOS App Bundle)

Um nur x86_64 (ohne universal) zu bauen, `--macos-target-arch=universal` in der Spec durch `--macos-target-arch=x86_64` ersetzen.

---

### 4.4 macOS Apple Silicon (arm64)

**Voraussetzungen:** Mac mit Apple Silicon (M1/M2/M3/M4), macOS 13+, Xcode CLI Tools

```bash
# Identisch mit Intel, da Python + PySide6 automatisch ARM64-Wheels verwenden
source .venv/bin/activate

RCC=$(python3 -c "import PySide6, os; print(os.path.join(os.path.dirname(PySide6.__file__), 'rcc'))")
"$RCC" -binary resources.qrc -o resources.rcc

# Für reines arm64 (ohne Universal):
python3 -m pyside6deploy -c build/pysidedeploy-macos.spec --verbose
# In pysidedeploy-macos.spec: --macos-target-arch=arm64
```

---

### 4.5 macOS Universal Binary

Ein **Universal Binary** enthält sowohl den x86_64- als auch den arm64-Code in einer einzigen Datei.

**Methode A: Auf Apple Silicon bauen mit `--macos-target-arch=universal`**

> Erfordert, dass PySide6 als Universal Wheel vorliegt (pip install PySide6 gibt auf Apple Silicon automatisch Universal Wheels zurück).

```bash
# In build/pysidedeploy-macos.spec ist bereits --macos-target-arch=universal gesetzt
source .venv/bin/activate
python3 -m pyside6deploy -c build/pysidedeploy-macos.spec --verbose
# Ergibt ein Universal-Binary direkt
```

**Methode B: Einzelne Binaries mit `lipo` zusammenführen**

```bash
# Voraussetzung: Intel-Binary und ARM64-Binary liegen vor
lipo -create \
    MPDP-macos-x86_64 \
    MPDP-macos-arm64 \
    -output MPDP-macos-universal

# Architektur prüfen
lipo -info MPDP-macos-universal
# Ausgabe: Architectures in the fat file: MPDP-macos-universal are: x86_64 arm64
```

---

### 4.6 Linux x86\_64

**Voraussetzungen:** Ubuntu 20.04+ / Debian 11+ / Fedora 36+ (x86_64), Python 3.12

```bash
# 1. System-Pakete installieren (siehe Abschnitt 2)
sudo apt-get install -y libglib2.0-dev libgl1-mesa-dev ...  # (vollständige Liste in Abschnitt 2)

# 2. venv aktivieren
source .venv/bin/activate

# 3. resources.rcc sicherstellen
RCC=$(python3 -c "import PySide6, os; print(os.path.join(os.path.dirname(PySide6.__file__), 'rcc'))")
"$RCC" -binary resources.qrc -o resources.rcc

# 4. Bauen
python3 -m pyside6deploy -c build/pysidedeploy-linux.spec --verbose

# 5. Ergebnis: dist/main  (ausführbare Datei)
chmod +x dist/main
mv dist/main dist/MPDP-linux-x86_64
```

**Konfigurationsdatei:** `build/pysidedeploy-linux.spec`

**Ausgabe:** `dist/MPDP-linux-x86_64` (selbstständige Binary)

---

### 4.7 Linux aarch64 (ARM64)

**Methode A: Nativer aarch64-Rechner / SBC (Raspberry Pi 5, NVIDIA Jetson, etc.)**

```bash
# Identisch mit Linux x86_64 – auf aarch64-Hardware ausführen
# Python und PySide6 verwenden automatisch aarch64-Wheels
source .venv/bin/activate
python3 -m pyside6deploy -c build/pysidedeploy-linux.spec --verbose
```

**Methode B: Docker mit QEMU-Emulation (auf x86_64-Host)**

```bash
# QEMU-Unterstützung aktivieren
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

# aarch64-Container starten
docker run --platform linux/arm64 -it \
    -v $(pwd):/workspace \
    -w /workspace \
    arm64v8/ubuntu:22.04 bash

# Im Container:
apt-get update && apt-get install -y python3 python3-pip python3-venv \
    libglib2.0-dev libgl1-mesa-dev libegl1-mesa-dev \
    libxcb-xinerama0 libxcb-cursor0 libxkbcommon-x11-0 \
    libdbus-1-dev libasound2-dev libpulse-dev patchelf

python3 -m venv .venv
source .venv/bin/activate
pip install PySide6 Nuitka
python3 -m pyside6deploy -c build/pysidedeploy-linux.spec --verbose
```

> **Hinweis:** QEMU-Emulation ist ~5-10× langsamer als native Hardware. Für schnellere Builds: nativen aarch64-Runner oder GitHub Larger Runners verwenden.

---

## 5. CI/CD mit GitHub Actions

Die Pipeline unter `.github/workflows/build.yml` baut automatisch alle Plattformen, sobald ein Git-Tag gepusht wird.

### Workflow auslösen

```bash
# Release-Tag erstellen und pushen → startet automatisch alle Builds
git tag v1.0.0
git push origin v1.0.0
```

### Manueller Auslöser

Im GitHub-Repository unter **Actions → Build MPDP – All Platforms → Run workflow**

### Build-Matrix

| Job                    | Runner             | Ziel                    | Status    |
|------------------------|--------------------|-------------------------|-----------|
| `build-windows-x64`   | `windows-latest`   | Windows x64 `.exe`      | Standard  |
| `build-windows-arm64` | `windows-11-arm`   | Windows ARM64 `.exe`    | Kostenpflichtig |
| `build-macos-intel`   | `macos-13`         | macOS Intel `.app`      | Standard  |
| `build-macos-arm64`   | `macos-latest`     | macOS ARM64 `.app`      | Standard  |
| `build-macos-universal`| `macos-latest`    | Universal Binary        | Standard  |
| `build-linux-x64`     | `ubuntu-22.04`     | Linux x86_64 Binary     | Standard  |
| `build-linux-aarch64` | `ubuntu-22.04`+QEMU| Linux ARM64 Binary      | Standard  |
| `release`             | `ubuntu-latest`    | GitHub Release          | Nur bei Tag |

### GitHub Release

Bei Tag-Push wird automatisch ein GitHub Release mit allen Binaries erstellt. Die Artifacts sind 30 Tage verfügbar.

### Windows ARM64 Runner

Der `windows-11-arm`-Runner ist ein **GitHub Larger Runner** und kostenpflichtig (außer für open-source Repositories mit bestimmten Zugangsstufen). Alternativen:

- Selbst-gehosteten Runner auf einem ARM64-Windows-Gerät einrichten
- Build manuell auf einem ARM64-Gerät durchführen

Dokumentation: https://docs.github.com/en/actions/using-github-hosted-runners/about-larger-runners

---

## 6. Build-Konfigurationsdateien

| Datei                                  | Plattform            | Beschreibung                        |
|----------------------------------------|----------------------|-------------------------------------|
| `pysidedeploy.spec`                   | Windows x64          | Standard-Konfiguration (Entwicklung) |
| `build/pysidedeploy-windows-arm64.spec`| Windows ARM64        | ARM64-spezifische Einstellungen     |
| `build/pysidedeploy-macos.spec`       | macOS (universal2)   | Universal Binary, App-Bundle        |
| `build/pysidedeploy-linux.spec`       | Linux (x86_64/aarch64)| Wayland-Unterstützung, GStreamer   |

### Aufbau einer `.spec`-Datei

```ini
[app]
title = MPDP              # App-Name
input_file = main.py      # Einstiegspunkt
exec_directory = ./dist   # Ausgabeverzeichnis
icon =                    # Pfad zur Icon-Datei

[python]
python_path = .venv/bin/python3   # Pfad zur Python-Executable

[qt]
qml_files = ...           # Alle QML-Dateien des Projekts
excluded_qml_plugins = …  # Nicht benötigte QML-Plugins
modules = …               # Qt-Module (Core, Multimedia, …)
plugins = …               # Qt-Plugin-Verzeichnisse

[nuitka]
mode = onefile            # onefile oder standalone
extra_args = …            # Weitere Nuitka-Argumente
```

---

## 7. Externe Datendateien & Ressourcen

MPDP lädt zur Laufzeit externe Dateien, die in die Binary eingebettet werden müssen.

| Datei / Verzeichnis       | Zweck                                   | Nuitka-Flag                                        |
|---------------------------|-----------------------------------------|----------------------------------------------------|
| `resources.rcc`           | Kompilierte Qt-Ressourcen (Icons, etc.) | `--include-data-files=resources.rcc=resources.rcc` |
| `database/`               | SQLite-Datenbank + Themes               | `--include-data-dir=database=database/`            |
| `icons/`                  | SVG/PNG Icons                           | `--include-data-dir=icons=icons/`                  |
| `StartPage/`              | QML-Seite: Startseite                   | `--include-data-dir=StartPage=StartPage/`          |
| `FileBrowser/`            | QML-Seite: Dateibrowser                 | `--include-data-dir=FileBrowser=FileBrowser/`      |
| `MultiMediaPlayer/`       | QML-Seite: Medienwiedergabe             | `--include-data-dir=MultiMediaPlayer=MultiMediaPlayer/` |
| `Settings/`               | QML-Seite: Einstellungen                | `--include-data-dir=Settings=Settings/`            |

### resources.rcc erstellen

Die Datei `resources.rcc` wird aus `resources.qrc` generiert. Falls `resources.qrc` nicht im Repository liegt, kann sie manuell erstellt oder aus einem vorhandenen `resources.rcc` verwendet werden.

```bash
# rcc-Tool aus PySide6 verwenden
python3 -c "import PySide6, os; print(os.path.join(os.path.dirname(PySide6.__file__), 'rcc'))"
# Ausgabe: /path/to/site-packages/PySide6/rcc

# Kompilieren
/path/to/PySide6/rcc -binary resources.qrc -o resources.rcc
```

---

## 8. Häufige Probleme & Lösungen

### `ModuleNotFoundError: No module named 'PySide6'`

```bash
# Sicherstellen, dass das richtige venv aktiviert ist
source .venv/bin/activate
python3 -c "import PySide6; print(PySide6.__version__)"
```

### `resources.rcc not found` / Icons werden nicht angezeigt

```bash
# resources.rcc fehlt – neu erstellen
python3 -c "import PySide6, os; print(os.path.join(os.path.dirname(PySide6.__file__), 'rcc'))" | xargs -I{} {} -binary resources.qrc -o resources.rcc
```

### Multimedia-Wiedergabe funktioniert nicht (Linux)

```bash
# GStreamer-Plugins installieren
sudo apt-get install -y gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav

# Prüfen ob FFmpeg-Backend verfügbar ist
python3 -c "from PySide6.QtMultimedia import QMediaPlayer; print('OK')"
```

### `xcb`-Fehler auf Linux (kein Display)

```bash
# Für Headless-Build (z. B. CI ohne GUI): Offscreen-Platform verwenden
export QT_QPA_PLATFORM=offscreen
```

### macOS: `code signature invalid`

```bash
# Nach dem Bau re-signieren (für lokale Tests):
codesign --force --deep --sign - dist/MPDP.app

# Für Verteilung: Apple Developer-Zertifikat benötigt
# --macos-signed-app-name= in pysidedeploy-macos.spec ergänzen
```

### Windows: Antivirus blockiert die kompilierte EXE

Nuitka-kompilierte Binaries werden manchmal fälschlicherweise als Malware erkannt (False Positive). Lösungen:

1. EXE code-signieren (benötigt Code-Signing-Zertifikat)
2. Antivirus-Ausnahme hinzufügen
3. VirusTotal-Scan durchführen und Ergebnis mit Antivirus-Vendor teilen

### Binary-Größe zu groß

```ini
# In der .spec-Datei unter [nuitka] extra_args:
# Übersetzungsdateien weglassen (spart ~100 MB)
--noinclude-qt-translations

# Mehr QML-Plugins ausschließen (in [qt] excluded_qml_plugins):
excluded_qml_plugins = QtCharts,QtSensors,QtWebEngine,QtWebView,Qt3D,QtLocation,QtQuick3D,QtDataVisualization,QtBluetooth,QtNfc

# UPX-Komprimierung aktivieren (Nuitka-Argument):
--windows-dependency-tool=pefile
```

### Nuitka-Cache für schnellere Folge-Builds

```bash
# Nuitka cached kompilierte C-Dateien in ~/.nuitka
# Bei großen Projekten spart das 60-80% der Build-Zeit
# Der Cache wird automatisch verwendet, kein manueller Eingriff nötig
```

---

## 9. Glossar

| Begriff          | Erklärung                                                       |
|------------------|-----------------------------------------------------------------|
| **onefile**      | Alles in einer einzigen ausführbaren Datei (Nuitka extrahiert beim Start in ein Temp-Verzeichnis) |
| **standalone**   | Ausführbare Datei + Verzeichnis mit DLLs/SOs (kein Extrahieren) |
| **Universal Binary** | macOS-spezifisch: eine Datei enthält Code für x86_64 und arm64 |
| **lipo**         | macOS-Tool zum Zusammenführen/Analysieren von Universal Binaries |
| **rcc**          | Qt Resource Compiler: wandelt `.qrc`-Dateien in `.rcc`-Binärdaten um |
| **QML Plugin**   | Qt Quick-Erweiterungsmodul (z. B. `QtMultimedia`, `QtCharts`)  |
| **Qt Plugin**    | Zur Laufzeit ladbare Erweiterung für Qt-Core (z. B. `platforms/`, `imageformats/`) |
| **pysidedeploy** | PySide6-Wrapper um Nuitka; automatisiert Qt-Abhängigkeitsanalyse |
| **Nuitka**       | Python-zu-C-Compiler; erzeugt native Binaries ohne Python-Interpreter |
| **QEMU**         | Hardwareemulator: ermöglicht aarch64-Builds auf x86_64-Hosts   |
| **lipo**         | macOS CLI: kombiniert oder analysiert Universal Binaries        |
| **ARM64/aarch64**| 64-Bit ARM-Architektur (Apple M-Chips, Raspberry Pi 4/5, etc.) |
| **x86_64/AMD64** | Standard 64-Bit Intel/AMD-Architektur                          |
