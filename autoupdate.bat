@echo off
setlocal EnableExtensions
title NextCode Updater

cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0autoupdate.ps1" %*
if errorlevel 1 (
  echo.
  echo Update failed. The previous engine was restored. Check backup\autoupdate.log
  pause
  exit /b 1
)
echo.
pause
exit /b 0
