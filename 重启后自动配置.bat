@echo off
chcp 65001 >nul
title QuantDinger - 重启后自动配置

color 0B

echo.
echo ========================================
echo   🔄 重启后自动配置
echo ========================================
echo.
echo 正在检查 WSL 状态...
timeout /t 3 >nul

:: 添加 Podman 到 PATH
set "PATH=%LOCALAPPDATA%\Programs\Podman;%APPDATA%\Python\Python312\Scripts;%PATH%"

:: 检查 WSL 是否可用
wsl --status >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] WSL 仍未安装，请手动运行 wsl --install
    pause
    exit /b 1
)

echo ✓ WSL 已就绪
echo.

:: 设置 WSL2 为默认版本
echo [步骤 1/4] 设置 WSL2 为默认版本...
wsl --set-default-version 2
echo.

:: 下载并安装 WSL2 内核更新（如果需要）
echo [步骤 2/4] 检查 WSL2 内核...
wsl --update
echo.

:: 创建 Podman Machine
echo [步骤 3/4] 创建 Podman Machine...
podman machine list | findstr /C:"Running" >nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ Podman Machine 已在运行
) else (
    echo 正在创建 Podman Machine（首次需要几分钟）...
    podman machine init --cpus 2 --memory 4096 --disk-size 100
    
    if %errorlevel% neq 0 (
        echo [错误] Podman Machine 创建失败
        echo 请查看 WSL安装指南.txt
        pause
        exit /b 1
    )
    
    echo ✓ Podman Machine 创建成功
)
echo.

:: 启动 Podman Machine
echo [步骤 4/4] 启动 Podman Machine...
podman machine start

if %errorlevel% neq 0 (
    echo [警告] 启动可能失败，尝试再次启动...
    timeout /t 5 >nul
    podman machine start
)
echo.

:: 验证状态
echo ========================================
echo   验证状态
echo ========================================
echo.
podman machine list
echo.

podman machine list | findstr /C:"Running" >nul 2>&1
if %errorlevel% equ 0 (
    color 0A
    echo ========================================
    echo   ✅ 所有配置已完成！
    echo ========================================
    echo.
    echo 现在可以启动 QuantDinger 了
    echo.
    choice /C YN /M "是否立即启动 QuantDinger"
    
    if %errorlevel% equ 1 (
        cd /d "D:\javaEE\IdeaProjects\baosight\tools\quandtinger"
        call QuantDinger_Start.bat
    ) else (
        echo.
        echo 稍后可以双击桌面的 QuantDinger_Start.bat 启动
        echo.
        pause
    )
) else (
    color 0C
    echo ========================================
    echo   ❌ Podman Machine 启动失败
    echo ========================================
    echo.
    echo 请查看 WSL安装指南.txt 获取帮助
    echo.
    pause
)
