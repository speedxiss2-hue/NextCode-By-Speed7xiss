@echo off
setlocal EnableExtensions
title NextCode - doctor

cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0doctor.ps1" %*
if errorlevel 1 (
  echo.
  echo Doctor found errors. Fix them and run this again.
  pause
  exit /b 1
)
echo.
pause
exit /b 0
