@echo off
setlocal EnableDelayedExpansion

echo ============================================
echo   Windows 10 LTSC VM Template Cleanup
echo ============================================
echo.

:: Get initial disk space (pure cmd, no PowerShell)
call :GetFree INIT_FREE
call :GetUsedGB INIT_USED_GB
echo Used space before cleanup: !INIT_USED_GB! GB
echo.

:: ==========================================
echo === Phase 1: Stop Services ===
:: ==========================================
for %%S in (wuauserv bits WSearch DiagTrack dosvc FontCache WerSvc SysMain) do (
    sc query %%S 2>nul | findstr "RUNNING" >nul 2>&1 && (
        net stop %%S /y >nul 2>&1 && echo   %%S               stopped || echo   %%S               FAILED to stop
    ) || echo   %%S               already stopped
)
echo.
echo Killing search processes...
taskkill /f /im SearchIndexer.exe >nul 2>&1
taskkill /f /im SearchProtocolHost.exe >nul 2>&1
taskkill /f /im SearchFilterHost.exe >nul 2>&1
timeout /t 2 /nobreak >nul
echo.

:: ==========================================
echo === Phase 2: Tool-Based Cleanup ===
:: ==========================================
call :MeasureBefore

echo --- WinSxS Component Cleanup ---
dism /Online /Cleanup-Image /StartComponentCleanup /ResetBase
echo.

echo --- Automated Disk Cleanup (cleanmgr) ---
for %%K in (
    "Active Setup Temp Folders"
    "Content Indexer Cleaner"
    "D3D Shader Cache"
    "Delivery Optimization Files"
    "Device Driver Packages"
    "Diagnostic Data Viewer database files"
    "Downloaded Program Files"
    "Internet Cache Files"
    "Old ChkDsk Files"
    "Previous Installations"
    "Recycle Bin"
    "RetailDemo Offline Content"
    "Setup Log Files"
    "System error memory dump files"
    "System error minidump files"
    "Temporary Files"
    "Temporary Setup Files"
    "Thumbnail Cache"
    "Update Cleanup"
    "Upgrade Discarded Files"
    "Windows Defender"
    "Windows Error Reporting Files"
    "Windows ESD installation files"
    "Windows Upgrade Log Files"
) do (
    reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\%%~K" /v "StateFlags0099" /t REG_DWORD /d "2" /f >nul 2>&1
)
echo   Configured 24 cleanup categories
echo   Starting cleanmgr, waiting for it to finish...
start /wait cleanmgr /sagerun:99
echo   cleanmgr finished
echo.

echo --- VSS Shadow Copies ---
vssadmin delete shadows /for=c: /all /quiet
echo.

call :MeasureAfter "Phase 2: Tool-Based Cleanup"
echo.

:: ==========================================
echo === Phase 3: Large Directories ===
:: ==========================================
call :MeasureBefore

echo --- Windows Update Cache ---
call :RmDir "C:\Windows\SoftwareDistribution\Download"
mkdir "C:\Windows\SoftwareDistribution\Download" >nul 2>&1
call :RmDir "C:\Windows\SoftwareDistribution\DataStore"
call :RmDir "C:\Windows\SoftwareDistribution\PostRebootEventCache.V2"
call :DelFiles "%ALLUSERSPROFILE%\Microsoft\Network\Downloader\qmgr*.dat"
echo.

echo --- Old System / Upgrade Remnants ---
call :RmDir "C:\Windows.old"
call :RmDir "C:\$Windows.~BT"
call :RmDir "C:\$Windows.~WS"
echo.

echo --- Setup Leftovers + Driver Temps ---
call :RmDir "C:\AMD"
call :RmDir "C:\Intel"
call :RmDir "C:\NVIDIA"
echo.

echo --- Installer Patch Cache ---
call :RmDir "C:\Windows\Installer\$PatchCache$"
call :RmDir "C:\MSOCache"
echo.

echo --- Windows Defender Leftovers ---
sc query WinDefend >nul 2>&1
if !errorlevel! NEQ 0 (
    if exist "C:\ProgramData\Microsoft\Windows Defender" (
        echo   Taking ownership of Defender folder...
        takeown /f "C:\ProgramData\Microsoft\Windows Defender" /r /d y >nul 2>&1
        icacls "C:\ProgramData\Microsoft\Windows Defender" /grant Administrators:F /t >nul 2>&1
        rd /s /q "C:\ProgramData\Microsoft\Windows Defender" 2>nul
        if not exist "C:\ProgramData\Microsoft\Windows Defender" (echo   Removed: C:\ProgramData\Microsoft\Windows Defender) else echo   FAILED: C:\ProgramData\Microsoft\Windows Defender ^(some files locked^)
    ) else echo   Skip: C:\ProgramData\Microsoft\Windows Defender not found
) else (
    echo   Skip: Defender still active
)
echo.

echo --- Error Reporting + Crash Dumps ---
call :RmDir "C:\ProgramData\Microsoft\Windows\WER"
mkdir "C:\ProgramData\Microsoft\Windows\WER" >nul 2>&1
call :DelFile "C:\Windows\MEMORY.DMP"
call :RmDir "C:\Windows\Minidump"
call :DelFiles "C:\Windows\LiveKernelReports\*.dmp"
call :RmDir "%LOCALAPPDATA%\CrashDumps"
echo.

echo --- Search Index ---
call :RmDir "C:\ProgramData\Microsoft\Search\Data"
echo.

echo --- Delivery Optimization ---
call :RmDir "C:\Windows\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization"
echo.

echo --- Browser Cache ---
call :RmDir "%LOCALAPPDATA%\Microsoft\Windows\INetCache"
call :RmDir "%LOCALAPPDATA%\Microsoft\Windows\INetCookies"
call :RmDir "%LOCALAPPDATA%\Microsoft\Windows\WebCache"
call :RmDir "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Cache"
call :RmDir "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Code Cache"
echo.

call :MeasureAfter "Phase 3: Large Directories"
echo.

:: ==========================================
echo === Phase 4: Temp Files + Caches ===
:: ==========================================
call :MeasureBefore

echo --- Temp Files ---
call :CleanDir "C:\Windows\Temp"
call :CleanDir "%TEMP%"
for /D %%x in ("C:\Users\*") do (
    if exist "%%x\AppData\Local\Temp" call :CleanDir "%%x\AppData\Local\Temp"
)
call :CleanDir "C:\Windows\ServiceProfiles\LocalService\AppData\Local\Temp"
call :CleanDir "C:\Windows\ServiceProfiles\NetworkService\AppData\Local\Temp"
call :CleanDir "C:\Windows\System32\config\systemprofile\AppData\Local\Temp"
echo.

echo --- Prefetch ---
call :CleanDir "C:\Windows\Prefetch"
echo.

echo --- Font Cache ---
call :CleanDir "C:\Windows\ServiceProfiles\LocalService\AppData\Local\FontCache"
call :DelFile "C:\Windows\System32\FNTCACHE.DAT"
echo.

echo --- Thumbnail + Icon Cache ---
call :DelFiles "%LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache_*"
call :DelFiles "%LOCALAPPDATA%\Microsoft\Windows\Explorer\iconcache_*"
call :DelFile "%LOCALAPPDATA%\IconCache.db"
echo.

echo --- DirectX Shader Cache ---
call :RmDir "%LOCALAPPDATA%\Microsoft\DirectX Shader Cache"
echo.

echo --- Windows Caches ---
call :DelFiles "%LOCALAPPDATA%\Microsoft\Windows\Caches\*"
echo.

echo --- Telemetry ETL Logs ---
call :DelFiles "%ProgramData%\Microsoft\Diagnosis\ETLLogs\AutoLogger\*.etl"
call :DelFiles "%ProgramData%\Microsoft\Diagnosis\ETLLogs\ShutdownLogger\*.etl"
echo.

call :MeasureAfter "Phase 4: Temp Files + Caches"
echo.

:: ==========================================
echo === Phase 5: System Logs ===
:: ==========================================
call :MeasureBefore

call :RmDir "C:\Windows\Logs\DISM"
mkdir "C:\Windows\Logs\DISM" >nul 2>&1
call :DelFiles "C:\Windows\Logs\CBS\*.log"
call :DelFiles "C:\Windows\Logs\CBS\*.cab"
call :CleanDir "C:\Windows\Logs\WindowsUpdate"
call :DelFiles "C:\Windows\inf\setupapi*.log"
call :DelFiles "C:\Windows\debug\*.log"
call :RmDir "C:\ProgramData\USOShared\Logs"
call :DelFiles "C:\Windows\*.log"
call :DelFiles "C:\Windows\*.tmp"
call :CleanDir "C:\Windows\Logs\SIH"
call :CleanDir "C:\Windows\Logs\NetSetup"
call :CleanDir "C:\Windows\Logs\MoSetup"
call :CleanDir "C:\Windows\System32\LogFiles\setupcln"
echo.

echo --- Event Logs ---
set "ECNT=0"
for /f "tokens=*" %%L in ('wevtutil el') do (
    wevtutil cl "%%L" >nul 2>&1
    set /a ECNT+=1
)
echo   Cleared !ECNT! event log channels
echo.

call :MeasureAfter "Phase 5: System Logs"
echo.

:: ==========================================
echo === Phase 6: Privacy (Files) ===
:: ==========================================
call :MeasureBefore

echo --- Recent Files + Jump Lists ---
call :DelFiles "%APPDATA%\Microsoft\Windows\Recent\*"
call :DelFiles "%APPDATA%\Microsoft\Windows\Recent\AutomaticDestinations\*"
call :DelFiles "%APPDATA%\Microsoft\Windows\Recent\CustomDestinations\*"
echo.

echo --- PowerShell History ---
call :DelFile "%APPDATA%\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"
echo.

echo --- Recycle Bin ---
rd /s /q "C:\$Recycle.Bin" 2>nul
echo   Recycle bin emptied
echo.

call :MeasureAfter "Phase 6: Privacy (Files)"
echo.

:: ==========================================
echo === Phase 7: Privacy (Registry) ===
:: ==========================================

call :RegDel "RunMRU" "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\RunMRU"
call :RegDel "TypedPaths" "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths"
call :RegDel "RecentDocs" "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs"
call :RegDelVa "ComDlg32 OpenSave" "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\OpenSavePidlMRU"
call :RegDelVa "ComDlg32 LastVisited" "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\LastVisitedPidlMRU"
call :RegDelVa "Regedit HKCU" "HKCU\Software\Microsoft\Windows\CurrentVersion\Applets\Regedit"
call :RegDelVa "Regedit HKLM" "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Applets\Regedit"
call :RegDelVa "IE TypedURLs" "HKCU\SOFTWARE\Microsoft\Internet Explorer\TypedURLs"
call :RegDelVa "IE TypedURLsTime" "HKCU\SOFTWARE\Microsoft\Internet Explorer\TypedURLsTime"
call :RegDelVa "MuiCache" "HKCR\Local Settings\Software\Microsoft\Windows\Shell\MuiCache"
call :RegDelVa "Paint MRU" "HKCU\Software\Microsoft\Windows\CurrentVersion\Applets\Paint\Recent File List"
call :RegDelVa "Wordpad MRU" "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Applets\Wordpad\Recent File List"
call :RegDelVa "AppCompatFlags" "HKCU\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Compatibility Assistant\Store"
call :RegDelVa "Direct3D HKCU" "HKCU\Software\Microsoft\Direct3D\MostRecentApplication"
call :RegDelVa "Direct3D HKLM" "HKLM\SOFTWARE\Microsoft\Direct3D\MostRecentApplication"
call :RegDelVa "FeatureUsage BadgeUpdated" "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FeatureUsage\AppBadgeUpdated"
call :RegDelVa "FeatureUsage AppLaunch" "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FeatureUsage\AppLaunch"
call :RegDelVa "FeatureUsage AppSwitched" "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FeatureUsage\AppSwitched"
call :RegDelVa "FeatureUsage ShowJumpView" "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FeatureUsage\ShowJumpView"
call :RegDelVa "JumplistData" "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search\JumplistData"
call :RegDel "UserAssist" "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\UserAssist"
for /f "tokens=2" %%i in ('whoami /user /fo table /nh') do (
    call :RegDelVa "BAM CurrentControl" "HKLM\SYSTEM\CurrentControlSet\Services\bam\UserSettings\%%i"
    call :RegDelVa "BAM ControlSet001" "HKLM\SYSTEM\ControlSet001\Services\bam\State\UserSettings\%%i"
)
call :RegDel "WordWheelQuery" "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\WordWheelQuery"
call :RegDelVa "MediaPlayer Files" "HKCU\Software\Microsoft\MediaPlayer\Player\RecentFileList"
call :RegDelVa "MediaPlayer URLs HKCU" "HKCU\Software\Microsoft\MediaPlayer\Player\RecentURLList"
call :RegDelVa "MediaPlayer URLs HKLM" "HKLM\SOFTWARE\Microsoft\MediaPlayer\Player\RecentURLList"
echo.

:: ==========================================
echo === Phase 8: Final ===
:: ==========================================

ipconfig /flushdns >nul 2>&1
echo   DNS cache flushed
net start FontCache >nul 2>&1
echo   FontCache restarted
echo.

:: Post-cleanup: clean CBS/DISM logs generated by dism earlier
del /q /f "C:\Windows\Logs\CBS\*.log" >nul 2>&1
del /q /f "C:\Windows\Logs\CBS\*.cab" >nul 2>&1
del /q /f "C:\Windows\Logs\DISM\*.log" >nul 2>&1

:: ==========================================
::  Disk Space Summary
:: ==========================================
call :GetUsedGB FINAL_USED_GB
call :GetFree FINAL_FREE
set /a "FREED_MB=FINAL_FREE - INIT_FREE"

echo ============================================
echo   Before : !INIT_USED_GB! GB
echo   After  : !FINAL_USED_GB! GB
echo   Freed  : !FREED_MB! MB
echo ============================================
pause
goto :eof

:: ==========================================
:: Helper functions
:: ==========================================

:MeasureBefore
:: Save current free space (bytes, truncated to ~MB precision)
call :GetFree _BEFORE
goto :eof

:MeasureAfter
:: Compare current free space with _BEFORE, print released MB
call :GetFree _AFTER
:: Released = After_Free - Before_Free (in ~MB units, last 6 digits stripped)
set /a "_REL=!_AFTER! - !_BEFORE!"
echo   ^>^> %~1 released: !_REL! MB
goto :eof

:GetFree
:: Get free space in MiB into variable named %1
:: Method: strip last 4 digits (div by 10000), then div by 105 (~= 1048576/10000)
wmic logicaldisk where "DeviceID='C:'" get FreeSpace /format:value > "%TEMP%\_df.txt" 2>nul
for /f "tokens=2 delims==" %%a in ('type "%TEMP%\_df.txt" ^| findstr "Free"') do set "_GF_RAW=%%a"
del /q "%TEMP%\_df.txt" 2>nul
set "_GF_T=!_GF_RAW:~0,-4!"
set /a "%~1=_GF_T / 105"
goto :eof

:GetUsedGB
:: Get used space in GiB (2 decimal places) into variable named %1
wmic logicaldisk where "DeviceID='C:'" get FreeSpace /format:value > "%TEMP%\_df.txt" 2>nul
for /f "tokens=2 delims==" %%a in ('type "%TEMP%\_df.txt" ^| findstr "Free"') do set "_GU_FREE=%%a"
wmic logicaldisk where "DeviceID='C:'" get Size /format:value > "%TEMP%\_df.txt" 2>nul
for /f "tokens=2 delims==" %%a in ('type "%TEMP%\_df.txt" ^| findstr "Size"') do set "_GU_SIZE=%%a"
del /q "%TEMP%\_df.txt" 2>nul
:: Strip last 4 digits, divide by 105 to get MiB
set "_GU_FREE_T=!_GU_FREE:~0,-4!"
set "_GU_SIZE_T=!_GU_SIZE:~0,-4!"
set /a "_GU_FREE_M=_GU_FREE_T / 105"
set /a "_GU_SIZE_M=_GU_SIZE_T / 105"
set /a "_GU_USED_M=_GU_SIZE_M - _GU_FREE_M"
set /a "_GU_GB=_GU_USED_M / 1024"
set /a "_GU_FRAC=(_GU_USED_M %% 1024) * 100 / 1024"
:: Pad fraction with leading zero if needed
if !_GU_FRAC! LSS 10 set "_GU_FRAC=0!_GU_FRAC!"
set "%~1=!_GU_GB!.!_GU_FRAC!"
goto :eof

:RmDir
:: Remove a directory entirely. Show result per item.
if exist %1 (
    rd /s /q %1 2>nul
    if not exist %1 (echo   Removed: %~1) else echo   FAILED: %~1 ^(files in use^)
) else echo   Skip: %~1 not found
goto :eof

:DelFile
:: Delete a single file. Show result.
if exist %1 (
    del /q /f %1 >nul 2>nul
    if not exist %1 (echo   Deleted: %~1) else echo   FAILED: %~1 ^(in use^)
) else echo   Skip: %~1 not found
goto :eof

:DelFiles
:: Delete files matching a wildcard. Show each file.
set "_DF_ANY=0"
for %%f in (%1) do (
    set "_DF_ANY=1"
    del /q /f "%%f" >nul 2>nul
    if not exist "%%f" (echo   Deleted: %%f) else echo   FAILED: %%f ^(in use^)
)
if !_DF_ANY! EQU 0 echo   Skip: %~1 not found
goto :eof

:CleanDir
:: Clean all contents inside a directory (keep the dir). Show each file/subdir.
if not exist %1 (
    echo   Skip: %~1 not found
    goto :eof
)
set "_CD_ANY=0"
for %%f in ("%~1\*") do (
    set "_CD_ANY=1"
    del /q /f "%%f" >nul 2>nul
    if not exist "%%f" (echo   Deleted: %%f) else echo   FAILED: %%f ^(in use^)
)
for /d %%D in ("%~1\*") do (
    set "_CD_ANY=1"
    rd /s /q "%%D" 2>nul
    if not exist "%%D" (echo   Removed: %%D) else echo   FAILED: %%D ^(in use^)
)
if !_CD_ANY! EQU 0 echo   Skip: %~1 is empty
goto :eof

:RegDel
:: Delete an entire registry key. Show result.
reg query %2 >nul 2>&1
if !errorlevel! EQU 0 (
    reg delete %2 /f >nul 2>&1
    echo   Cleaned: %~1
) else echo   Skip: %~1 not found
goto :eof

:RegDelVa
:: Delete all values in a registry key. Show result.
reg query %2 >nul 2>&1
if !errorlevel! EQU 0 (
    reg delete %2 /va /f >nul 2>&1
    echo   Cleaned: %~1
) else echo   Skip: %~1 not found
goto :eof
