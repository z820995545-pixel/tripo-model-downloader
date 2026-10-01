@echo off
setlocal
cd /d "%~dp0"
start "" "%SystemRoot%\System32\wscript.exe" //B //NoLogo "%~dp0Launch-TripoModelDownloader.vbs"
exit /b 0
