[app]

# Anwendungstitel
title = MPDP

# Projektstammverzeichnis
project_dir = .

# Einstiegspunkt
input_file = main.py

# Ausgabeverzeichnis der fertigen Binary
exec_directory = ./dist

# Projektdatei
project_file = pyproject.toml

# Icon (leer lassen oder Pfad zu einer .ico/.icns/.png Datei angeben)
icon =

[python]

# Pfad zur Python-Executable (relativ oder absolut)
python_path = .venv313\Scripts\python.exe

# Nuitka-Version (muss mit installierter Version übereinstimmen)
packages = Nuitka==2.7.11

# Android (nicht verwendet)
android_packages = buildozer==1.5.0,cython==0.29.33

[qt]

# Alle QML-Dateien des Projekts (werden in die Binary eingebettet)
qml_files = main.qml,StartPage/main.qml,FileBrowser/main.qml,MultiMediaPlayer/main.qml,Settings/main.qml

# QML-Plugins die NICHT benötigt werden (reduziert Binary-Größe)
excluded_qml_plugins = QtCharts,QtSensors,QtWebEngine,QtWebView,Qt3D,QtLocation,QtQuick3D,QtDataVisualization

# Qt-Module: alle tatsächlich genutzten Module explizit angeben
# Core, Gui, Qml, Quick, QuickControls2 - Basis-UI
# Multimedia - MediaPlayer, VideoOutput, AudioOutput
# TextToSpeech - Barrierefreiheit / Sprachausgabe
# Concurrent, Network - interne Qt-Abhängigkeiten
modules = Core,Gui,Qml,Quick,QuickControls2,Multimedia,TextToSpeech,Concurrent,Network

# Qt-Plugins: alle für Laufzeit benötigten Plugin-Verzeichnisse
# accessiblebridge  - Screenreader / Barrierefreiheit
# generic           - Generische Eingabe-Plugins
# iconengines       - SVG-Icons (qsvgicon)
# imageformats      - PNG, JPG, SVG Bildformate
# multimedia        - Medien-Backend (FFmpeg / WMF / AVFoundation)
# platforminputcontexts - Eingabemethoden / IME
# platforms         - Fenster-System (windows / xcb / cocoa / wayland)
# platformthemes    - Native Plattform-Themes (GTK, KDE)
# qmllint           - QML-Validierung
# qmltooling        - QML-Debugging
# scenegraph        - Qt Quick Scene-Graph (OpenGL / Vulkan)
# tls               - TLS/SSL für interne Qt-Verbindungen
plugins = accessiblebridge,generic,iconengines,imageformats,multimedia,platforminputcontexts,platforms,platformthemes,qmllint,qmltooling,scenegraph,tls

[android]

# Android wird in diesem Projekt nicht unterstützt
wheel_pyside =
wheel_shiboken =
plugins =

[nuitka]

# macOS App-Berechtigungen (leer = keine besonderen Rechte benötigt)
macos.permissions =

# Modus: onefile = einzelne ausführbare Datei
# standalone = Verzeichnis mit allen Abhängigkeiten
mode = onefile

# Nuitka-Argumente (Windows x64)
# --quiet                            Weniger Build-Output
# --noinclude-qt-translations        Qt-Übersetzungsdateien weglassen (reduziert Größe)
# --include-data-files               Externe Dateien einbetten
# --include-data-dir                 Externe Verzeichnisse einbetten
# --force-dll-dependency-cache-update  Windows: DLL-Cache aktualisieren
extra_args = --quiet --noinclude-qt-translations --include-data-files=resources.rcc=resources.rcc --include-data-dir=database=database/ --include-data-dir=icons=icons/ --include-data-dir=StartPage=StartPage/ --include-data-dir=FileBrowser=FileBrowser/ --include-data-dir=MultiMediaPlayer=MultiMediaPlayer/ --include-data-dir=Settings=Settings/ --force-dll-dependency-cache-update

[buildozer]

mode = debug
recipe_dir =
jars_dir =
ndk_path =
sdk_path =
local_libs =
arch =
