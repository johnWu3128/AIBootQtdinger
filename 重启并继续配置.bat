@echo off
chcp 65001 >nul
title WSL 已启用 - 需要重启

color 0A

echo.
echo ========================================
echo   ✅ WSL 功能已成功启用！
echo ========================================
echo.
echo 已完成的操作：
echo   ✓ 启用 Windows Subsystem for Linux
echo   ✓ 启用虚拟机平台 (VirtualMachinePlatform)
echo.
echo ⚠️  重要：必须重启电脑才能使更改生效！
echo.
echo 重启后，系统将自动运行：
echo   1. 下载并安装 WSL2 内核更新
echo   2. 创建 Podman Machine
echo   3. 启动 QuantDinger
echo.
echo ========================================
echo.

choice /C YN /M "是否立即重启电脑"

if %errorlevel% equ 1 (
    echo.
    echo [提示] 正在保存工作...
    echo [提示] 电脑将在 10 秒后重启
    echo.
    timeout /t 10
    shutdown /r /t 0
) else (
    echo.
    echo [提示] 请稍后手动重启电脑
    echo [提示] 重启后运行: 初始化Podman_Machine.bat
    echo.
    pause
)
