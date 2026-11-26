@echo off
setlocal EnableExtensions
title NextCode Uninstall

cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1" %*
if errorlevel 1 (
  echo.
  echo Uninstall failed. Fix the error above and run uninstall.bat again.
  pause
  exit /b 1
)

echo.
echo Uninstall finished.
pause
exit /b 0
