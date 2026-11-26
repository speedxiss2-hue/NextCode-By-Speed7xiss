@echo off
setlocal EnableExtensions
title NextCode Setup

cd /d "%~dp0"
if errorlevel 1 (
  echo Could not enter "%~dp0".
  pause
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1" %*
if errorlevel 1 (
  echo.
  echo Setup failed. Fix the error above and run setup.bat again.
  pause
  exit /b 1
)

echo.
echo Setup finished.
pause
exit /b 0
