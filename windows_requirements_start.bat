@echo off
setlocal
set "PS1=%~dp0windows_requirements.ps1"
start "" /min powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%PS1%"
exit /b
