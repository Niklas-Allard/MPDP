@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

if not exist .venv313\Scripts\python.exe (
    echo [ERROR] .venv313 nicht gefunden.
    echo Einrichten mit:
    echo   python -m venv .venv313
    echo   .venv313\Scripts\python.exe -m pip install --upgrade pip
    echo   .venv313\Scripts\python.exe -m pip install PySide6 "Nuitka==4.1"
    exit /b 1
)

set "PATH=%~dp0.venv313\Scripts;%PATH%"
set "VIRTUAL_ENV=%~dp0.venv313"

echo.
choice /C JN /M "Soll die EXE ein Konsolenfenster haben (fuer Debug-Ausgaben)? J=Ja, N=Nein"
if errorlevel 2 (
    set "CONSOLE_MODE=disable"
) else (
    set "CONSOLE_MODE=force"
)
echo Konsolen-Modus: !CONSOLE_MODE!

echo === resources.rcc kompilieren ===
"%~dp0.venv313\Lib\site-packages\PySide6\rcc.exe" -binary resources.qrc -o resources.rcc
if errorlevel 1 (
    echo [ERROR] rcc fehlgeschlagen.
    exit /b 1
)

echo === Temporaere Spec-Datei mit Konsolen-Einstellung erzeugen ===
rem Muss im Projektroot liegen, da "project_dir = ." im Spec relativ zum
rem Speicherort der Spec-Datei aufgeloest wird (nicht zum aktuellen Verzeichnis).
set "TMP_SPEC=%~dp0pysidedeploy_console_tmp.spec"
if exist "!TMP_SPEC!" del "!TMP_SPEC!"
for /f "usebackq delims=" %%L in ("pysidedeploy.spec") do (
    set "LINE=%%L"
    echo !LINE! | findstr /b "extra_args" >nul
    if !errorlevel! == 0 (
        echo !LINE! --windows-console-mode=!CONSOLE_MODE!>>"!TMP_SPEC!"
    ) else (
        echo !LINE!>>"!TMP_SPEC!"
    )
)

echo === dist\MPDP.dist entfernen, damit Erfolg eindeutig erkennbar ist ===
if exist "dist\MPDP.dist" rd /s /q "dist\MPDP.dist"

echo === pyside6-deploy: Windows x64 Build ===
pyside6-deploy -c "!TMP_SPEC!" main.py --extra-modules Multimedia,TextToSpeech --mode standalone --force

del "!TMP_SPEC!" >nul 2>&1

rem pyside6-deploy liefert teils Exitcode 0 trotz internem Fehler (Nuitka-Aufruf
rem schlaegt fehl) - daher Erfolg anhand der tatsaechlichen Ausgabedatei prüfen.
if not exist "dist\MPDP.dist\main.exe" (
    echo.
    echo [ERROR] Build fehlgeschlagen - dist\MPDP.dist\main.exe wurde nicht erzeugt.
    exit /b 1
)

echo.
echo === Build erfolgreich: dist\MPDP.dist\main.exe (Konsole: !CONSOLE_MODE!) ===
endlocal
