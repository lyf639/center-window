@echo off
chcp 65001 >nul
:: ============================================================
::  梦幻西游窗口居中 - 双击即可
::  自动提权 + 调用 center_mhxy.ps1
:: ============================================================
title 游戏窗口居中
cd /d "%~dp0"

:: 自动请求管理员权限
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo 正在请求管理员权限...
    powershell -Command "Start-Process '%~f0' -Verb RunAs -WorkingDirectory '%~dp0'" 2>nul
    exit /b
)

:: 执行 PowerShell 脚本
powershell -ExecutionPolicy Bypass -File "%~dp0center_mhxy.ps1" %*
exit /b
