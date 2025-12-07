@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0src"

REM Kompiliere App.java wenn noch nicht kompiliert
echo Java (runtime) version:
java -version
echo.
echo Javac version (compiler) if available:
javac -version 2>nul || echo javac not found
echo.

REM Kompiliere App.java (force neu kompilieren mit Zielkompatibilität auf Java 17)
echo Kompiliere App.java (target Java 17)...
javac --release 17 -encoding UTF-8 App.java 2>compile_err.txt
if errorlevel 1 (
    echo Fehler beim Kompilieren. Ausgabe:
    type compile_err.txt
    pause
)
del compile_err.txt >nul 2>nul

REM Starte die App und zeige Fehler
echo Starte App...
java App
if errorlevel 1 (
    echo.
    echo FEHLER beim Starten der App!
    pause
)
