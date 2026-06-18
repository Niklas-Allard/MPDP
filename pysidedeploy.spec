[app]
title = MPDP
project_dir = .
input_file = main.py
exec_directory = ./dist
project_file = pyproject.toml
icon = C:\dev\MPDP\.venv313\Lib\site-packages\PySide6\scripts\deploy_lib\pyside_icon.ico

[python]
python_path = C:\dev\MPDP\.venv313\Scripts\python.exe
packages = Nuitka==4.1
android_packages = buildozer==1.5.0,cython==0.29.33

[qt]
qml_files = main.qml,StartPage/main.qml,FileBrowser/main.qml,MultiMediaPlayer/main.qml,Settings/main.qml
excluded_qml_plugins = QtCharts,QtSensors,QtWebEngine,QtWebView,Qt3D,QtLocation,QtQuick3D,QtDataVisualization
modules = Core,Gui,Qml,Quick,QuickControls2
plugins = accessiblebridge,generic,iconengines,imageformats,multimedia,platforminputcontexts,platforms,platformthemes,qmllint,qmltooling,scenegraph,tls

[android]
wheel_pyside = 
wheel_shiboken = 
plugins = 

[nuitka]
macos.permissions = 
mode = standalone
extra_args = --quiet --noinclude-qt-translations --include-data-files=resources.rcc=resources.rcc --include-data-dir=database=database --include-data-dir=icons=icons --include-data-dir=StartPage=StartPage --include-data-dir=FileBrowser=FileBrowser --include-data-dir=MultiMediaPlayer=MultiMediaPlayer --include-data-dir=Settings=Settings

[buildozer]
mode = debug
recipe_dir = 
jars_dir = 
ndk_path = 
sdk_path = 
local_libs = 
arch = 

