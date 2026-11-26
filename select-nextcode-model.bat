@echo off
setlocal EnableExtensions
title NextCode - select exclusive model

cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0select-nextcode-model.ps1" %*
if errorlevel 1 (
  echo.
  echo Model selection failed. Fix the error above and run this again.
  pause
  exit /b 1
)
echo.
pause
exit /b 0
