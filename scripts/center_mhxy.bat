@echo off
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File "%~dp0center_mhxy.ps1" %*
pause
