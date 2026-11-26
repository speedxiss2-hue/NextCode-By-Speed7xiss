@echo off
setlocal EnableExtensions
title NextCode Installer

cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*
if errorlevel 1 (
  echo.
  echo Install failed. Read the message above, fix it, then run install.bat again.
  pause
  exit /b 1
)
echo.
pause
exit /b 0
