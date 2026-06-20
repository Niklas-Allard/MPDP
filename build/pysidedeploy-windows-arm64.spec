[app]

title = MPDP
project_dir = .
input_file = main.py
exec_directory = ./dist
project_file = pyproject.toml

# Windows ARM64: .ico Datei
# icon = icons/MPDP.ico
icon =

[python]

# ARM64-Python muss explizit installiert sein
# Download: https://www.python.org/downloads/windows/ → "ARM64 installer"
python_path = .venv\Scripts\python.exe
packages = Nuitka==2.7.11
android_packages = buildozer==1.5.0,cython==0.29.33

[qt]

qml_files = main.qml,StartPage/main.qml,FileBrowser/main.qml,MultiMediaPlayer/main.qml,Settings/main.qml
excluded_qml_plugins = QtCharts,QtSensors,QtWebEngine,QtWebView,Qt3D,QtLocation,QtQuick3D,QtDataVisualization
modules = Core,Gui,Qml,Quick,QuickControls2,Multimedia,TextToSpeech,Concurrent,Network
plugins = accessiblebridge,generic,iconengines,imageformats,multimedia,platforminputcontexts,platforms,platformthemes,qmllint,qmltooling,scenegraph,tls,texttospeech

[android]

wheel_pyside =
wheel_shiboken =
plugins =

[nuitka]

macos.permissions =
mode = standalone

# Windows ARM64: Nuitka erkennt die Zielarchitektur aus der Python-Installation.
# Wird mit ARM64-Python ausgefuehrt -> erzeugt ARM64-Binary.
# --force-dll-dependency-cache-update  Windows-spezifisch
extra_args = --quiet --noinclude-qt-translations --include-data-files=resources.rcc=resources.rcc --include-data-dir=database=database --include-data-dir=icons=icons --include-data-dir=StartPage=StartPage --include-data-dir=FileBrowser=FileBrowser --include-data-dir=MultiMediaPlayer=MultiMediaPlayer --include-data-dir=Settings=Settings --force-dll-dependency-cache-update

[buildozer]

mode = debug
recipe_dir =
jars_dir =
ndk_path =
sdk_path =
local_libs =
arch =
