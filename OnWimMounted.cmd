@echo off
:: Runs after W10UI mounts WIM. Copies C\ into %1 (mount dir).

set "mountdir=%~1"
if "%mountdir%"=="" exit /b

:: Skip boot.wim (has WinPE language packs)
if exist "%mountdir%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" exit /b

if not exist "%~dp0C\" exit /b

echo.
echo ============================================================
echo Copying custom files into image...
echo ============================================================
echo.

xcopy "%~dp0C\*" "%mountdir%\" /E /Y /I
