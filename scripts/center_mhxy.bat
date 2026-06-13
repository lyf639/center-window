@echo off
cd /d "%~dp0"

fltmc >nul 2>&1
if %errorlevel% neq 0 (
    powershell -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"\"%~dp0center_mhxy.ps1\"\" %*; Read-Host'"
    exit /b
)

powershell -ExecutionPolicy Bypass -File "%~dp0center_mhxy.ps1" %*
pause
