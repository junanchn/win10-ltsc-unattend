@echo off
setlocal

:: Generate W10UI.ini with absolute paths
> "%~dp0W10UI.ini" (
  echo [W10UI-Configuration]
  echo Target        =%~dp0ISO
  echo Repo          =%~dp0Updates
  echo Net35         =0
  echo Cleanup       =1
  echo ResetBase     =1
  echo AutoStart     =1
  echo AddDrivers    =1
)

:: Extract ISO
"C:\Program Files\7-Zip\7z.exe" x "%~dp0Windows 10 Enterprise LTSC 2021.iso" -o"%~dp0ISO" -y
@if %ERRORLEVEL% neq 0 (echo Extract failed & pause & exit /b 1)

:: Place autounattend.xml in ISO root
copy /y "%~dp0C\Windows\Panther\unattend.xml" "%~dp0ISO\autounattend.xml"

:: Run W10UI
cd /d "%~dp0"
W10UI.cmd

pause
