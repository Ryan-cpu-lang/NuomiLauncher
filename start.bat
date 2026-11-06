@echo off
chcp 65001 >nul
setlocal
rem ============================================================
rem  Nuomi Launcher - double click to run
rem
rem  Usage:
rem    start.bat            run with default config in launcher.nuomi
rem    start.bat dry        plan only, print the java command
rem    start.bat download   download everything (client, libs, natives, assets)
rem    start.bat launch     download everything and start Minecraft
rem    start.bat gui        open the graphical launcher window
rem ============================================================
cd /d "%~dp0"

set "MODE=%1"
if "%MODE%"=="" set "MODE=gui"

if /I "%MODE%"=="gui" (
  rem Use nuomiw.exe (GUI subsystem) so no console window is attached.
  rem For a truly black-box-free double-click, use NuomiMC-GUI.vbs instead.
  if exist "%~dp0nuomiw.exe" (
    "%~dp0nuomiw.exe" "%~dp0gui.nuomi"
  ) else (
    echo [NuomiLauncher] nuomiw.exe not found, falling back to nuomi.exe
    "%~dp0nuomi.exe" "%~dp0gui.nuomi"
  )
  set "RC=%ERRORLEVEL%"
  endlocal
  exit /b %RC%
)

set "NUOMI_MODE=%MODE%"
if /I "%MODE%"=="default" set "NUOMI_MODE="

echo [NuomiLauncher] mode=%MODE%
echo [NuomiLauncher] running...
echo.
"%~dp0nuomi.exe" "%~dp0launcher.nuomi"
set "RC=%ERRORLEVEL%"
echo.
echo [NuomiLauncher] finished with exit code %RC%
endlocal
