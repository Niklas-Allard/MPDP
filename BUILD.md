# MPDP – Build-Anleitung

Dieses Dokument beschreibt vollständig, wie MPDP für **Windows**, **macOS** und **Linux** auf allen gängigen Prozessorarchitekturen gebaut wird.

> **Stand:** Verifiziert mit Python 3.13.13, PySide6 6.11.1, Nuitka 4.1 (Windows x64 lokaler Build).

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
   - [Linux x86\_64](#45-linux-x86_64)
   - [Linux aarch64 (ARM64)](#46-linux-aarch64-arm64)
5. [CI/CD mit GitHub Actions](#5-cicd-mit-github-actions)
6. [Build-Konfigurationsdateien](#6-build-konfigurationsdateien)
7. [Externe Datendateien & Ressourcen](#7-externe-datendateien--ressourcen)
8. [Bekannte Probleme & Lösungen](#8-bekannte-probleme--lösungen)
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
| macOS Intel     | macOS-Maschine mit Intel-CPU                        |
| macOS ARM64     | macOS-Maschine mit Apple Silicon (M1/M2/M3)         |
| Linux x86\_64   | Linux auf x86_64 (nativ oder VM/Container)          |
| Linux aarch64   | Linux auf aarch64 (nativ oder QEMU-Container)       |

Die praktische Lösung dafür ist eine **CI/CD-Pipeline** (z. B. GitHub Actions), die alle Zielplattformen gleichzeitig baut. Die fertige Pipeline liegt unter `.github/workflows/build.yml`.

### Build-Werkzeuge

| Werkzeug         | Rolle                                                        |
|------------------|--------------------------------------------------------------|
| `pyside6-deploy` | Frontend für Nuitka; analysiert Qt-Abhängigkeiten automatisch |
| `Nuitka`         | Kompiliert Python-Code zu nativem C-Code und bindet Qt ein   |
| `rcc`            | Qt Resource Compiler: wandelt `.qrc` zu `.rcc` um            |

### Build-Ausgabe: `standalone` Verzeichnis

Der Build erzeugt **kein einzelnes `.exe`**, sondern ein Verzeichnis (`MPDP.dist/`) mit:
- `main.exe` (ca. 6 MB)
- Qt-DLLs (ca. 200 MB gesamt)
- `PySide6/` mit allen Qt-Plugins
- Alle eingebetteten Datendateien

Das Verzeichnis wird für die Auslieferung als ZIP verpackt.

### Kritisch: pyside6-deploy überschreibt die Spec-Datei

> **pyside6-deploy modifiziert `pysidedeploy.spec` bei jedem Aufruf automatisch.**

Konkret werden bei jedem Run überschrieben:
- `[qt] modules` → wird von `qmlimportscanner` neu berechnet und auf `Core,Gui,Qml,Quick,QuickControls2` zurückgesetzt
- `[app] icon` → wird auf einen absoluten Pfad gesetzt
- `[python] python_path` → wird auf einen absoluten Pfad gesetzt

**Konsequenz:** Die Module `Multimedia` und `TextToSpeech` müssen immer als CLI-Flag übergeben werden:

```
pyside6-deploy ... --extra-modules Multimedia,TextToSpeech
```

---

## 2. Voraussetzungen

### Alle Plattformen

- **Python 3.12 oder 3.13** (empfohlen: 3.13)
  - Wichtig: Python-Version muss zur Zielarchitektur passen
- **PySide6 6.11.x**
- **Nuitka 4.1** (nicht 2.7.x – die Spec-Dateien pinnen explizit `Nuitka==4.1`)
- **Git**

### Windows

```powershell
# Visual Studio Build Tools (C++-Compiler für Nuitka) – zwingend erforderlich
winget install Microsoft.VisualStudio.2022.BuildTools
# Im Installer: "Desktop development with C++" auswählen
```

> **Hinweis:** `dumpbin` (Visual Studio Tool zur DLL-Analyse) muss nicht separat installiert werden. Die Warnung `Unable to find dumpbin` im Build-Output ist harmlos und beeinflusst das Ergebnis nicht.

### macOS

```bash
# Xcode Command Line Tools (beinhaltet clang) – zwingend erforderlich
xcode-select --install
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

Die App benötigt folgende Qt-Module. Da pyside6-deploy die Spec-Datei bei jedem Run zurücksetzt, werden `Multimedia` und `TextToSpeech` **immer** per `--extra-modules` CLI-Flag übergeben.

| Modul              | Verwendung                                          | In Spec? |
|--------------------|-----------------------------------------------------|----------|
| `Core`             | QObject, QSettings, QResource, QFile               | Ja       |
| `Gui`              | QGuiApplication, Fenster-System                    | Ja       |
| `Qml`              | QML-Engine, QQmlApplicationEngine                  | Ja       |
| `Quick`            | Qt Quick (visuelle QML-Elemente)                   | Ja       |
| `QuickControls2`   | Material-Stil, Button, Slider, ComboBox, etc.      | Ja       |
| `Multimedia`       | MediaPlayer, VideoOutput, AudioOutput (FFmpeg)     | `--extra-modules` |
| `TextToSpeech`     | Barrierefreiheit – Sprachausgabe                   | `--extra-modules` |
| `Concurrent`       | Interne Qt-Threading-Hilfsmittel                   | Ja       |
| `Network`          | Interne Qt-Netzwerkschicht                         | Ja       |

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
| `texttospeech`           | TTS-Backends (SAPI/WinRT/AVSpeech/speech-dispatcher) | ✓    | ✓     | ✓     |
| `wayland`                | Wayland-Backend (nur Linux)                       | –       | –     | ✓     |

### Ausgeschlossene QML-Plugins

Diese Module werden im Projekt nicht verwendet und sind vom Build ausgeschlossen:

```
QtCharts, QtSensors, QtWebEngine, QtWebView, Qt3D, QtLocation, QtQuick3D, QtDataVisualization
```

---

## 4. Lokaler Build (Development)

### Wichtige Regel: pyside6-deploy korrekt aufrufen

`pyside6-deploy` ist ein **ausführbares Skript**, kein Python-Modul. Der Aufruf über `python -m pyside6deploy` schlägt fehl.

**Richtig:**
```powershell
# Windows – PATH und VIRTUAL_ENV müssen gesetzt sein
$env:PATH = "$PWD\.venv313\Scripts;$env:PATH"
$env:VIRTUAL_ENV = "$PWD\.venv313"
pyside6-deploy -c pysidedeploy.spec main.py --extra-modules Multimedia,TextToSpeech --mode standalone
```

```bash
# macOS / Linux
export PATH="$PWD/.venv/bin:$PATH"
export VIRTUAL_ENV="$PWD/.venv"
pyside6-deploy -c build/pysidedeploy-linux.spec main.py --extra-modules Multimedia,TextToSpeech --mode standalone
```

> **Warum PATH + VIRTUAL_ENV?** pyside6-deploy ruft intern Tools wie `pyside6-qmlimportscanner` auf. Diese müssen im PATH verfügbar sein. Ohne `VIRTUAL_ENV` erkennt pyside6-deploy das venv nicht und fragt interaktiv nach der Paketinstallation.

---

### 4.1 Windows x64

**Voraussetzungen:** Windows 10/11 (x64), Python 3.13 x64, Visual Studio Build Tools 2022

```powershell
# 1. Venv anlegen (Name .venv313 muss zur Spec-Datei passen)
python -m venv .venv313
.venv313\Scripts\python.exe -m pip install --upgrade pip
.venv313\Scripts\python.exe -m pip install PySide6 "Nuitka==4.1"

# 2. resources.rcc sicherstellen (falls noch nicht vorhanden)
$rcc = .venv313\Scripts\python.exe -c "import PySide6, os; print(os.path.join(os.path.dirname(PySide6.__file__), 'rcc.exe'))"
& $rcc -binary resources.qrc -o resources.rcc

# 3. Bauen
$env:PATH = "$PWD\.venv313\Scripts;$env:PATH"
$env:VIRTUAL_ENV = "$PWD\.venv313"
pyside6-deploy -c pysidedeploy.spec main.py --extra-modules Multimedia,TextToSpeech --mode standalone

# 4. Ergebnis
# dist\MPDP.dist\main.exe  (~6 MB, ~200 MB Verzeichnis gesamt)
```

**Konfigurationsdatei:** `pysidedeploy.spec` (Projektroot)

**Ausgabe:** `dist\MPDP.dist\` (Verzeichnis mit `main.exe` + Qt-DLLs)

**Multimedia-DLLs im Output:** Die FFmpeg-DLLs (`avcodec-61.dll`, `avformat-61.dll`, `avutil-59.dll`) werden automatisch eingebunden, wenn `Multimedia` als Modul inkludiert ist.

---

### 4.2 Windows ARM64

**Voraussetzungen:** Windows 11 ARM64-Gerät (z. B. Surface Pro X, Snapdragon X Elite), Python 3.13 ARM64

> **Wichtig:** Python für ARM64 muss separat heruntergeladen werden:
> https://www.python.org/downloads/windows/ → „ARM64 installer"

```powershell
# 1. ARM64-Python-venv anlegen
C:\Users\...\AppData\Local\Programs\Python\Python313-arm64\python.exe -m venv .venv313
.venv313\Scripts\python.exe -m pip install PySide6 "Nuitka==4.1"

# 2. resources.rcc sicherstellen
$rcc = .venv313\Scripts\python.exe -c "import PySide6, os; print(os.path.join(os.path.dirname(PySide6.__file__), 'rcc.exe'))"
& $rcc -binary resources.qrc -o resources.rcc

# 3. Bauen
$env:PATH = "$PWD\.venv313\Scripts;$env:PATH"
$env:VIRTUAL_ENV = "$PWD\.venv313"
pyside6-deploy -c build\pysidedeploy-windows-arm64.spec main.py --extra-modules Multimedia,TextToSpeech --mode standalone
```

**Konfigurationsdatei:** `build\pysidedeploy-windows-arm64.spec`

**Ausgabe:** `dist\MPDP.dist\` (ARM64-Binary)

---

### 4.3 macOS Intel (x86\_64)

**Voraussetzungen:** Mac mit Intel-CPU, macOS 12+, Xcode CLI Tools

```bash
# 1. Venv anlegen
python3 -m venv .venv
source .venv/bin/activate
pip install PySide6 "Nuitka==4.1"

# 2. resources.rcc sicherstellen
RCC=$(python3 -c "import PySide6, os; print(os.path.join(os.path.dirname(PySide6.__file__), 'rcc'))")
"$RCC" -binary resources.qrc -o resources.rcc

# 3. Bauen
export PATH="$PWD/.venv/bin:$PATH"
export VIRTUAL_ENV="$PWD/.venv"
pyside6-deploy -c build/pysidedeploy-macos.spec main.py --extra-modules Multimedia,TextToSpeech --mode standalone
```

**Konfigurationsdatei:** `build/pysidedeploy-macos.spec`

**Ausgabe:** `dist/MPDP.dist/MPDP.app` (macOS App Bundle)

---

### 4.4 macOS Apple Silicon (arm64)

**Voraussetzungen:** Mac mit Apple Silicon (M1/M2/M3/M4), macOS 13+, Xcode CLI Tools

```bash
# Identisch mit macOS Intel – Python/PySide6 verwenden automatisch arm64-Wheels
python3 -m venv .venv
source .venv/bin/activate
pip install PySide6 "Nuitka==4.1"

RCC=$(python3 -c "import PySide6, os; print(os.path.join(os.path.dirname(PySide6.__file__), 'rcc'))")
"$RCC" -binary resources.qrc -o resources.rcc

export PATH="$PWD/.venv/bin:$PATH"
export VIRTUAL_ENV="$PWD/.venv"
pyside6-deploy -c build/pysidedeploy-macos.spec main.py --extra-modules Multimedia,TextToSpeech --mode standalone
```

> **Hinweis:** `--macos-target-arch=universal` wird in der aktuellen Konfiguration **nicht** verwendet, da Nuitka 4.1 Universal Binaries unter PySide6 6.11.x nicht zuverlässig erzeugt. Jede Architektur baut separat.

---

### 4.5 Linux x86\_64

**Voraussetzungen:** Ubuntu 22.04+ / Debian 12+ (x86_64), Python 3.13

```bash
# 1. System-Pakete installieren (vollständige Liste in Abschnitt 2)
sudo apt-get install -y build-essential libglib2.0-dev libgl1-mesa-dev ...

# 2. Venv anlegen
python3 -m venv .venv
source .venv/bin/activate
pip install PySide6 "Nuitka==4.1"

# 3. resources.rcc sicherstellen
RCC=$(python3 -c "import PySide6, os; print(os.path.join(os.path.dirname(PySide6.__file__), 'rcc'))")
"$RCC" -binary resources.qrc -o resources.rcc

# 4. Bauen
export PATH="$PWD/.venv/bin:$PATH"
export VIRTUAL_ENV="$PWD/.venv"
pyside6-deploy -c build/pysidedeploy-linux.spec main.py --extra-modules Multimedia,TextToSpeech --mode standalone
```

**Konfigurationsdatei:** `build/pysidedeploy-linux.spec`

**Ausgabe:** `dist/MPDP.dist/` (Verzeichnis mit ausführbarer Datei `main`)

---

### 4.6 Linux aarch64 (ARM64)

**Methode A: Nativer aarch64-Rechner / SBC (Raspberry Pi 5, NVIDIA Jetson, etc.)**

```bash
# Identisch mit Linux x86_64 – auf aarch64-Hardware ausführen
python3 -m venv .venv
source .venv/bin/activate
pip install PySide6 "Nuitka==4.1"

export PATH="$PWD/.venv/bin:$PATH"
export VIRTUAL_ENV="$PWD/.venv"
pyside6-deploy -c build/pysidedeploy-linux.spec main.py --extra-modules Multimedia,TextToSpeech --mode standalone
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
    build-essential libglib2.0-dev libgl1-mesa-dev libegl1-mesa-dev \
    libxcb-xinerama0 libxcb-cursor0 libxkbcommon-x11-0 \
    libdbus-1-dev libasound2-dev libpulse-dev patchelf

python3 -m venv .venv
source .venv/bin/activate
pip install PySide6 "Nuitka==4.1"

export PATH="$PWD/.venv/bin:$PATH"
export VIRTUAL_ENV="$PWD/.venv"
pyside6-deploy -c build/pysidedeploy-linux.spec main.py --extra-modules Multimedia,TextToSpeech --mode standalone
```

> **Hinweis:** QEMU-Emulation ist ~5-10× langsamer als native Hardware.

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

| Job                    | Runner             | Ziel                    |
|------------------------|--------------------|-------------------------|
| `build-windows-x64`   | `windows-latest`   | Windows x64 ZIP         |
| `build-windows-arm64` | `windows-11-arm`   | Windows ARM64 ZIP        |
| `build-macos-intel`   | `macos-13`         | macOS Intel ZIP          |
| `build-macos-arm64`   | `macos-latest`     | macOS ARM64 ZIP          |
| `build-linux-x64`     | `ubuntu-22.04`     | Linux x86_64 ZIP         |
| `build-linux-aarch64` | `ubuntu-22.04`+QEMU| Linux ARM64 ZIP          |
| `release`             | `ubuntu-latest`    | GitHub Release (nur Tag) |

### Kernschritte jedes Jobs (Beispiel Windows x64)

```yaml
- name: Abhängigkeiten installieren
  shell: pwsh
  run: |
    python -m venv .venv313
    .venv313\Scripts\python.exe -m pip install --upgrade pip
    .venv313\Scripts\python.exe -m pip install PySide6 "Nuitka==4.1"

- name: pyside6-deploy
  shell: pwsh
  run: |
    $env:PATH = "$PWD\.venv313\Scripts;$env:PATH"
    $env:VIRTUAL_ENV = "$PWD\.venv313"
    pyside6-deploy -c pysidedeploy.spec main.py --extra-modules Multimedia,TextToSpeech --mode standalone

- name: Unnötige Verzeichnisse aus dist entfernen
  shell: pwsh
  run: |
    $distDir = Get-ChildItem dist -Directory | Select-Object -First 1
    if ($distDir) {
      @('.venv313', '.venv', '.github', '.git', '__pycache__', 'build') | ForEach-Object {
        $p = Join-Path $distDir.FullName $_
        if (Test-Path $p) { Remove-Item $p -Recurse -Force }
      }
    }

- name: Artifact als ZIP verpacken
  shell: pwsh
  run: |
    $distDir = Get-ChildItem dist -Directory | Select-Object -First 1
    if ($distDir) {
      Compress-Archive -Path $distDir.FullName -DestinationPath dist/MPDP-windows-x64.zip
    }
```

> **Warum Cleanup?** pyside6-deploy scannt das gesamte Projektverzeichnis und kopiert alle Unterverzeichnisse in das Dist-Verzeichnis – inklusive `.venv313`, `.github`, `build` etc. Der Cleanup-Schritt entfernt diese vor dem Verpacken.

### Windows ARM64 Runner

Der `windows-11-arm`-Runner ist ein **GitHub Larger Runner** und ggf. kostenpflichtig. Alternativen:

- Selbst-gehosteten Runner auf einem ARM64-Windows-Gerät einrichten
- Build manuell auf einem ARM64-Gerät durchführen

---

## 6. Build-Konfigurationsdateien

| Datei                                  | Plattform             | Beschreibung                        |
|----------------------------------------|-----------------------|-------------------------------------|
| `pysidedeploy.spec`                   | Windows x64           | Standard-Konfiguration (Entwicklung) |
| `build/pysidedeploy-windows-arm64.spec`| Windows ARM64         | ARM64-spezifische Einstellungen     |
| `build/pysidedeploy-macos.spec`       | macOS (Intel + ARM64) | App-Bundle, kein Universal Binary   |
| `build/pysidedeploy-linux.spec`       | Linux (x86_64/aarch64)| Wayland-Unterstützung               |

### Aufbau einer `.spec`-Datei

```ini
[app]
title = MPDP              # App-Name
input_file = main.py      # Einstiegspunkt
exec_directory = ./dist   # Ausgabeverzeichnis
icon =                    # Leer lassen – absoluter Pfad wird von pyside6-deploy gesetzt

[python]
python_path = .venv313\Scripts\python.exe   # Relativer Pfad zur Python-Executable
                                             # Wird von pyside6-deploy auf absoluten Pfad gesetzt

[qt]
qml_files = main.qml,...  # Alle QML-Dateien des Projekts
excluded_qml_plugins = …  # Nicht benötigte QML-Plugins
modules = Core,Gui,Qml,Quick,QuickControls2,Concurrent,Network
# ACHTUNG: modules wird bei jedem pyside6-deploy-Run überschrieben!
# Multimedia und TextToSpeech immer per --extra-modules CLI-Flag übergeben.
plugins = …               # Qt-Plugin-Verzeichnisse

[nuitka]
mode = standalone         # NICHT onefile – Nuitka 4.1 hat einen Bug mit onefile+PySide6 6.11.x
extra_args = --quiet --noinclude-qt-translations \
             --include-data-files=resources.rcc=resources.rcc \
             --include-data-dir=database=database \   # Kein trailing Slash!
             --include-data-dir=icons=icons \
             --include-data-dir=StartPage=StartPage \
             --include-data-dir=FileBrowser=FileBrowser \
             --include-data-dir=MultiMediaPlayer=MultiMediaPlayer \
             --include-data-dir=Settings=Settings
```

---

## 7. Externe Datendateien & Ressourcen

MPDP lädt zur Laufzeit externe Dateien, die in das Dist-Verzeichnis eingebettet werden müssen.

| Datei / Verzeichnis       | Zweck                                   | Nuitka-Flag                                        |
|---------------------------|-----------------------------------------|----------------------------------------------------|
| `resources.rcc`           | Kompilierte Qt-Ressourcen (Icons, etc.) | `--include-data-files=resources.rcc=resources.rcc` |
| `database`                | SQLite-Datenbank + Themes               | `--include-data-dir=database=database`             |
| `icons`                   | SVG/PNG Icons                           | `--include-data-dir=icons=icons`                   |
| `StartPage`               | QML-Seite: Startseite                   | `--include-data-dir=StartPage=StartPage`           |
| `FileBrowser`             | QML-Seite: Dateibrowser                 | `--include-data-dir=FileBrowser=FileBrowser`       |
| `MultiMediaPlayer`        | QML-Seite: Medienwiedergabe             | `--include-data-dir=MultiMediaPlayer=MultiMediaPlayer` |
| `Settings`                | QML-Seite: Einstellungen                | `--include-data-dir=Settings=Settings`             |

> **Kein trailing Slash** bei `--include-data-dir`! `database=database` ist korrekt, `database=database/` kann unter Nuitka 4.1 zu Pfadproblemen führen.

### resources.rcc erstellen

```bash
# rcc-Pfad aus PySide6 ermitteln
python3 -c "import PySide6, os; print(os.path.join(os.path.dirname(PySide6.__file__), 'rcc'))"

# Kompilieren
/path/to/PySide6/rcc -binary resources.qrc -o resources.rcc
```

Beide Dateien (`resources.rcc` und `resources.qrc`) sind im Repository eingecheckt.

---

## 8. Bekannte Probleme & Lösungen

### Nuitka 4.1: `AssertionError` bei `mode = onefile`

**Symptom:**
```
AssertionError
[Nuitka] Error, please report the bug...
nuitka/build/SconsCompilerSettings.py:...
Error: scons: Build failed, error code 2
```

**Ursache:** Nuitka 4.1 hat einen Bug beim Erzeugen von `__payload.bin` im `onefile`-Modus zusammen mit PySide6 6.11.x.

**Lösung:** `mode = standalone` in allen Spec-Dateien verwenden. Der Build erzeugt dann ein Verzeichnis statt einer einzelnen EXE.

---

### `pyside6-qmlimportscanner: command not found` / `No such file or directory`

**Symptom:** pyside6-deploy bricht ab, weil interne Qt-Tools nicht gefunden werden.

**Ursache:** pyside6-deploy ruft Tools wie `pyside6-qmlimportscanner` über den System-PATH auf. Das venv ist nicht im PATH.

**Lösung:**
```powershell
# Windows
$env:PATH = "$PWD\.venv313\Scripts;$env:PATH"
$env:VIRTUAL_ENV = "$PWD\.venv313"
pyside6-deploy ...
```
```bash
# macOS / Linux
export PATH="$PWD/.venv/bin:$PATH"
export VIRTUAL_ENV="$PWD/.venv"
pyside6-deploy ...
```

---

### `python -m pyside6deploy` schlägt fehl

**Symptom:** `No module named pyside6deploy`

**Ursache:** `pyside6-deploy` ist ein ausführbares Skript (Entry Point), kein Python-Modul. Der `-m`-Aufruf funktioniert nicht.

**Lösung:** `pyside6-deploy` direkt als Kommando aufrufen (siehe oben).

---

### Interaktive Paketinstallations-Anfrage blockiert den Build

**Symptom:** pyside6-deploy fragt `Install packages? [Y/n]` und der Build hängt.

**Ursache:** pyside6-deploy erkennt das venv nicht (VIRTUAL_ENV nicht gesetzt) und versucht, Pakete zu installieren.

**Lösung:** `VIRTUAL_ENV` korrekt setzen (siehe oben).

---

### `modules` in Spec fehlen nach dem Build

**Symptom:** Multimedia-Funktionen fehlen in der fertigen App, obwohl sie in der Spec-Datei stehen.

**Ursache:** pyside6-deploy überschreibt `[qt] modules` bei jedem Run über `qmlimportscanner`. `Multimedia` und `TextToSpeech` werden entfernt, weil sie nicht direkt in QML-Dateien importiert werden.

**Lösung:** Immer `--extra-modules Multimedia,TextToSpeech` als CLI-Flag übergeben.

---

### Build-Output enthält `.venv313`, `.github` etc.

**Symptom:** Das Dist-Verzeichnis enthält das komplette Projektverzeichnis als Unterordner.

**Ursache:** pyside6-deploy kopiert alle `--include-data-dir`-Verzeichnisse und scannt dabei das gesamte Projektverzeichnis.

**Lösung:** Nach dem Build einen Cleanup-Schritt ausführen:
```powershell
$distDir = Get-ChildItem dist -Directory | Select-Object -First 1
@('.venv313', '.venv', '.github', '.git', '__pycache__', 'build') | ForEach-Object {
    $p = Join-Path $distDir.FullName $_
    if (Test-Path $p) { Remove-Item $p -Recurse -Force }
}
```

---

### `Unable to find dumpbin` (Windows)

**Symptom:** Warnung im Build-Log: `Unable to find dumpbin`

**Ursache:** `dumpbin.exe` (Visual Studio DLL-Analyse-Tool) ist nicht im PATH. Nuitka versucht es zu nutzen, fällt aber automatisch auf einen anderen Mechanismus zurück.

**Lösung:** Keine – die Warnung ist harmlos. Der Build läuft korrekt durch.

---

### `ModuleNotFoundError: No module named 'PySide6'`

```bash
# Sicherstellen, dass das richtige venv aktiviert ist
source .venv/bin/activate
python3 -c "import PySide6; print(PySide6.__version__)"
```

---

### `resources.rcc not found` / Icons werden nicht angezeigt

```bash
# resources.rcc fehlt oder ist veraltet – neu erstellen
RCC=$(python3 -c "import PySide6, os; print(os.path.join(os.path.dirname(PySide6.__file__), 'rcc'))")
"$RCC" -binary resources.qrc -o resources.rcc
```

---

### Multimedia-Wiedergabe funktioniert nicht (Linux)

```bash
# GStreamer-Plugins installieren (Fallback falls FFmpeg-Backend fehlt)
sudo apt-get install -y gstreamer1.0-plugins-good gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly gstreamer1.0-libav

# Prüfen ob Multimedia-Modul verfügbar ist
python3 -c "from PySide6.QtMultimedia import QMediaPlayer; print('OK')"
```

---

### macOS: `code signature invalid`

```bash
# Nach dem Bau re-signieren (für lokale Tests):
codesign --force --deep --sign - dist/MPDP.dist/MPDP.app

# Für Verteilung: Apple Developer-Zertifikat erforderlich
```

---

### Windows: Antivirus blockiert die kompilierte EXE

Nuitka-kompilierte Binaries werden manchmal fälschlicherweise als Malware erkannt (False Positive). Lösungen:

1. EXE code-signieren (benötigt Code-Signing-Zertifikat)
2. Antivirus-Ausnahme hinzufügen
3. VirusTotal-Scan durchführen und Ergebnis mit Antivirus-Vendor teilen

---

## 9. Glossar

| Begriff          | Erklärung                                                       |
|------------------|-----------------------------------------------------------------|
| **standalone**   | Build-Modus: Verzeichnis mit EXE/Binary + DLLs/SOs (empfohlen) |
| **onefile**      | Build-Modus: alles in einer EXE (hat Bug mit Nuitka 4.1 + PySide6 6.11.x) |
| **extra-modules** | CLI-Flag für pyside6-deploy: Module die trotz Spec-Überschreibung inkludiert werden |
| **rcc**          | Qt Resource Compiler: wandelt `.qrc`-Dateien in `.rcc`-Binärdaten um |
| **QML Plugin**   | Qt Quick-Erweiterungsmodul (z. B. `QtMultimedia`, `QtCharts`)  |
| **Qt Plugin**    | Zur Laufzeit ladbare Erweiterung für Qt-Core (z. B. `platforms/`, `imageformats/`) |
| **pyside6-deploy** | PySide6-Wrapper um Nuitka; analysiert Qt-Abhängigkeiten via qmlimportscanner |
| **qmlimportscanner** | Qt-Tool das QML-Dateien analysiert und benötigte Module ermittelt; überschreibt `[qt] modules` in der Spec |
| **Nuitka**       | Python-zu-C-Compiler; erzeugt native Binaries ohne Python-Interpreter |
| **QEMU**         | Hardwareemulator: ermöglicht aarch64-Builds auf x86_64-Hosts   |
| **ARM64/aarch64**| 64-Bit ARM-Architektur (Apple M-Chips, Raspberry Pi 4/5, etc.) |
| **x86_64/AMD64** | Standard 64-Bit Intel/AMD-Architektur                          |
| **FFmpeg**       | Multimedia-Backend für Qt Multimedia (avcodec, avformat, avutil DLLs) |