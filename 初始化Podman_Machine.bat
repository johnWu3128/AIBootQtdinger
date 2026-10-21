@echo off
chcp 65001 >nul
title 初始化 Podman Machine

echo ========================================
echo   初始化 Podman Machine
echo ========================================
echo.
echo 此脚本将：
echo   1. 创建 Podman Machine（首次运行）
echo   2. 启动 Podman Machine
echo   3. 验证状态
echo.
echo 按任意键继续...
pause >nul

:: 添加 Podman 到 PATH
set "PATH=%LOCALAPPDATA%\Programs\Podman;%PATH%"

echo.
echo [步骤 1/3] 检查 Podman Machine 状态...
echo.

podman machine list

echo.
echo [步骤 2/3] 创建并启动 Podman Machine...
echo.
echo 注意：首次创建可能需要几分钟，请耐心等待
echo.

:: 尝试启动（如果已存在）
podman machine start

if %errorlevel% neq 0 (
    echo.
    echo [提示] Machine 不存在，正在创建...
    echo.
    
    :: 创建新的 Machine
    podman machine init --cpus 2 --memory 4096 --disk-size 100
    
    if %errorlevel% neq 0 (
        echo.
        echo [错误] Podman Machine 创建失败！
        echo.
        echo 可能的原因：
        echo   1. WSL2 未安装
        echo   2. 虚拟化未启用（BIOS 设置）
        echo   3. Windows 版本过低（需要 Win10 2004+ 或 Win11）
        echo.
        echo 解决方案：
        echo   1. 查看 WSL安装指南.txt
        echo   2. 以管理员身份运行 PowerShell，执行：wsl --install
        echo   3. 重启电脑后再试
        echo.
        pause
        exit /b 1
    )
    
    echo.
    echo [成功] Podman Machine 创建完成！
    echo.
    echo [提示] 正在启动...
    echo.
    
    :: 启动 Machine
    podman machine start
)

echo.
echo [步骤 3/3] 验证 Podman Machine 状态...
echo.

podman machine list

echo.
echo ========================================

:: 检查是否有 Running 状态
podman machine list | findstr /C:"Running" >nul 2>&1
if %errorlevel% equ 0 (
    echo   Podman Machine 已成功启动！
    echo ========================================
    echo.
    echo 现在可以运行 QuantDinger_Start.bat 了
    echo.
) else (
    echo   启动失败！请检查错误信息
    echo ========================================
    echo.
    echo 常见解决方案：
    echo   1. 确保 WSL2 已安装：wsl --list --verbose
    echo   2. 查看 WSL安装指南.txt 获取详细步骤
    echo   3. 重启电脑后再试
    echo.
)

pause
