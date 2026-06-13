@echo off
cd /d "%~dp0"

:: Auto-elevate to admin if needed
fltmc >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting admin rights...
    powershell -Command "Start-Process cmd.exe -ArgumentList '/c cd /d \"%~dp0\" ^&^& \"%~f0\"' -Verb RunAs -WorkingDirectory '%~dp0'" 2>nul
    exit /b
)

powershell -ExecutionPolicy Bypass -File "%~dp0center_mhxy.ps1" %*
pause
