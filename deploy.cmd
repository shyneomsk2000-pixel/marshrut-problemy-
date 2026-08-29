@echo off
chcp 65001 >nul
cd /d "%~dp0"
set /p MSG=Commit message (Enter = default): 
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0deploy.ps1" -Message "%MSG%"
echo.
pause
