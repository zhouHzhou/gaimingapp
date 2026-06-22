@echo off
chcp 65001 >nul
echo ========================================
echo   批量重命名 - Windows 安装包构建脚本
echo ========================================
echo.

where python >nul 2>nul
if %errorlevel% neq 0 (
    echo [错误] 未找到 Python，请先安装 Python 3.8+
    echo 下载地址: https://www.python.org/downloads/
    pause
    exit /b 1
)

python --version

echo.
echo [1/3] 安装 PyInstaller...
pip install pyinstaller --quiet

echo.
echo [2/3] 打包为 exe...
pyinstaller --noconfirm --onefile --windowed ^
    --name "批量重命名" ^
    --title "批量重命名" ^
    batch_renamer.py

if %errorlevel% neq 0 (
    echo [错误] 打包失败
    pause
    exit /b 1
)

echo.
echo [3/3] 构建完成!
echo.
echo 生成的文件位于: dist\批量重命名.exe
echo.
echo 如需创建安装包，请安装 Inno Setup 后运行 build_installer.bat
echo.

pause
