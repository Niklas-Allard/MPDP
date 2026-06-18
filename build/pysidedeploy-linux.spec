[app]

title = MPDP
project_dir = .
input_file = main.py
exec_directory = ./dist
project_file = pyproject.toml

# Linux: PNG-Icon (für Desktopintegration)
# icon = icons/MPDP.png
icon =

[python]

python_path = .venv/bin/python3
packages = Nuitka==2.7.11
android_packages = buildozer==1.5.0,cython==0.29.33

[qt]

qml_files = main.qml,StartPage/main.qml,FileBrowser/main.qml,MultiMediaPlayer/main.qml,Settings/main.qml
excluded_qml_plugins = QtCharts,QtSensors,QtWebEngine,QtWebView,Qt3D,QtLocation,QtQuick3D,QtDataVisualization
modules = Core,Gui,Qml,Quick,QuickControls2,Multimedia,TextToSpeech,Concurrent,Network

# Linux-spezifische Plugins
# xcb     - X11 Backend (Standard auf Desktop-Linux)
# wayland - Wayland Backend (Hyprland, Sway, GNOME Wayland, etc.)
# eglfs   - Embedded Linux / DRM ohne Display-Server
plugins = accessiblebridge,generic,iconengines,imageformats,multimedia,platforminputcontexts,platforms,platformthemes,qmllint,qmltooling,scenegraph,tls,wayland

[android]

wheel_pyside =
wheel_shiboken =
plugins =

[nuitka]

macos.permissions =
mode = onefile

# Nuitka-Argumente (Linux x86_64 / aarch64)
# --linux-icon              App-Icon (PNG)
# --enable-plugin=no-qt     Nicht verwenden (Qt wird durch pyside6-deploy verwaltet)
# Die Zielarchitektur wird durch die Python/PySide6-Installation bestimmt.
# Für aarch64: Python und PySide6 müssen als aarch64-Builds vorliegen.
extra_args = --quiet --noinclude-qt-translations --include-data-files=resources.rcc=resources.rcc --include-data-dir=database=database/ --include-data-dir=icons=icons/ --include-data-dir=StartPage=StartPage/ --include-data-dir=FileBrowser=FileBrowser/ --include-data-dir=MultiMediaPlayer=MultiMediaPlayer/ --include-data-dir=Settings=Settings/

[buildozer]

mode = debug
recipe_dir =
jars_dir =
ndk_path =
sdk_path =
local_libs =
arch =
