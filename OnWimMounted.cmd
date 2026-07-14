@echo off
:: Runs after W10UI mounts WIM.

set "mountdir=%~1"
if "%mountdir%"=="" exit /b

:: Skip boot.wim (has WinPE language packs)
if exist "%mountdir%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" exit /b

echo.
echo ============================================================
echo Copying custom files into image...
echo ============================================================
echo.

xcopy "%~dp0OEM\*" "%mountdir%\OEM\" /E /Y /I
xcopy "%~dp0unattend.xml" "%mountdir%\Windows\Panther\" /Y

if "%VM%"=="1" (
    type nul > "%mountdir%\OEM\.vm"
    xcopy "%~dp0VMwareTools" "%mountdir%\OEM\VMwareTools\" /E /Y /I
)

:: call "%~dp0OfflineDisableDefender.cmd" "%mountdir%"
call "%~dp0OfflineRemoveDefender.cmd" "%mountdir%"
call "%~dp0OfflineOptimize.cmd" "%mountdir%"
