@echo off
chcp 65001 >nul
echo ========================================
echo   批量重命名 - 生成安装包
echo ========================================
echo.

if not exist "dist\批量重命名.exe" (
    echo [错误] 未找到 dist\批量重命名.exe
    echo 请先运行 build.bat 打包程序
    pause
    exit /b 1
)

where iscc >nul 2>nul
if %errorlevel% neq 0 (
    echo [错误] 未找到 Inno Setup
    echo 请先安装 Inno Setup: https://jrsoftware.org/isdl.php
    pause
    exit /b 1
)

echo 正在生成安装包...
iscc installer.iss

if %errorlevel% neq 0 (
    echo [错误] 安装包生成失败
    pause
    exit /b 1
)

echo.
echo 安装包已生成到: installer_output\批量重命名_安装包.exe
echo.
pause
