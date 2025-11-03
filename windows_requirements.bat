@echo off
setlocal

set "PS1=%~dp0windows_requirements.ps1"

if not exist "%PS1%" (
  echo "%PS1%" not found.
  exit /b 1
)

rem Erst pwsh (PowerShell 7), sonst Windows PowerShell
where pwsh >nul 2>&1 ^
  && start "" pwsh       -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -STA -File "%PS1%" ^
  || start "" powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -STA -File "%PS1%"

exit /b
