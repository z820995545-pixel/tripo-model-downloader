@echo off
setlocal
cd /d "%~dp0"
if "%~1"=="" (
    start "" "%SystemRoot%\System32\wscript.exe" //B //NoLogo "%~dp0Launch-TripoModelDownloader.vbs"
    exit /b 0
) else (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0TripoGLBToFBX.ps1" %*
    echo.
    pause
)
