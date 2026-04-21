@echo off
setlocal

cd /d "%~dp0"

if exist ".build\rhcsa-tui.exe" (
  ".build\rhcsa-tui.exe" --project-root "%~dp0"
  goto done
)

if exist "rhcsa-tui.exe" (
  "rhcsa-tui.exe" --project-root "%~dp0"
  goto done
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0RHCSA.ps1" tui

:done
if errorlevel 1 (
  echo.
  echo RHCSA TUI exited with an error.
)
echo.
pause
