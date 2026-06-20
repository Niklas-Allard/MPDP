[app]

title = MPDP
project_dir = .
input_file = main.py
exec_directory = ./dist
project_file = pyproject.toml

# macOS: .icns Datei für das App-Bundle
# Eigene Icon-Datei anlegen und Pfad hier eintragen:
# icon = icons/MPDP.icns
icon =

[python]

# Auf dem CI/CD-Runner wird python3 aus dem venv verwendet
python_path = .venv/bin/python3
packages = Nuitka==2.7.11
android_packages = buildozer==1.5.0,cython==0.29.33

[qt]

qml_files = main.qml,StartPage/main.qml,FileBrowser/main.qml,MultiMediaPlayer/main.qml,Settings/main.qml
excluded_qml_plugins = QtCharts,QtSensors,QtWebEngine,QtWebView,Qt3D,QtLocation,QtQuick3D,QtDataVisualization
modules = Core,Gui,Qml,Quick,QuickControls2,Multimedia,TextToSpeech,Concurrent,Network

# macOS-spezifische Plugins
# xcb/wayland werden nicht benötigt (macOS verwendet cocoa)
plugins = accessiblebridge,generic,iconengines,imageformats,multimedia,platforminputcontexts,platforms,platformthemes,qmllint,qmltooling,scenegraph,tls,texttospeech

[android]

wheel_pyside =
wheel_shiboken =
plugins =

[nuitka]

# macOS-Berechtigungen (Info.plist)
# Nur eintragen wenn die App z. B. Mikrofon/Kamera benötigt
macos.permissions =

mode = standalone

# Nuitka-Argumente (macOS - Universal Binary: x86_64 + arm64)
# --macos-target-arch=universal     Universal Binary für Intel + Apple Silicon
# --macos-create-app-bundle         Erstellt ein .app Bundle statt einer rohen Binary
# --macos-app-name                  Bundle-Name
# --macos-app-version               Bundle-Version
# --macos-signed-app-name           Code-Signing Identität (leer = kein Signing)
extra_args = --quiet --noinclude-qt-translations --macos-create-app-bundle --macos-app-name=MPDP --macos-app-version=1.0 --include-data-files=resources.rcc=resources.rcc --include-data-dir=database=database --include-data-dir=icons=icons --include-data-dir=StartPage=StartPage --include-data-dir=FileBrowser=FileBrowser --include-data-dir=MultiMediaPlayer=MultiMediaPlayer --include-data-dir=Settings=Settings

[buildozer]

mode = debug
recipe_dir =
jars_dir =
ndk_path =
sdk_path =
local_libs =
arch =
