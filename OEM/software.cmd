cd /d "%~dp0"

:: VMware Tools
if exist "%~dp0VMwareTools\setup.exe" (
    start /wait VMwareTools\setup.exe /S /v "/qn REBOOT=R"
)

:: Activate Windows
cmd /c C:\OEM\MAS_AIO.cmd /Z-Windows

:: Install 7-Zip
7z2602-x64.exe /S

:: Associate archive formats with 7-Zip for all users
call :Assoc 7z   7-Zip.7z   "7z Archive"   0
call :Assoc zip  7-Zip.zip  "zip Archive"  1
call :Assoc rar  7-Zip.rar  "rar Archive"  3
call :Assoc xz   7-Zip.xz   "xz Archive"   23
call :Assoc txz  7-Zip.txz  "txz Archive"  23
call :Assoc tar  7-Zip.tar  "tar Archive"  13
call :Assoc bz2  7-Zip.bz2  "bz2 Archive"  2
call :Assoc tbz2 7-Zip.tbz2 "tbz2 Archive" 2
call :Assoc tbz  7-Zip.tbz  "tbz Archive"  2
call :Assoc gz   7-Zip.gz   "gz Archive"   14
call :Assoc tgz  7-Zip.tgz  "tgz Archive"  14
call :Assoc zst  7-Zip.zst  "zst Archive"  26
call :Assoc tzst 7-Zip.tzst "tzst Archive" 26
goto :After7ZipAssoc

:Assoc
reg delete "HKLM\SOFTWARE\Classes\.%~1" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Classes\%~2" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Classes\.%~1" /ve /d "%~2" /f >nul
reg add "HKLM\SOFTWARE\Classes\%~2" /ve /d "%~3" /f >nul
reg add "HKLM\SOFTWARE\Classes\%~2\DefaultIcon" /ve /d "%ProgramFiles%\7-Zip\7z.dll,%~4" /f >nul
reg add "HKLM\SOFTWARE\Classes\%~2\shell" /ve /t REG_SZ /f >nul
reg add "HKLM\SOFTWARE\Classes\%~2\shell\open" /ve /t REG_SZ /f >nul
reg add "HKLM\SOFTWARE\Classes\%~2\shell\open\command" /ve /d "\"%ProgramFiles%\7-Zip\7zFM.exe\" \"%%1\"" /f >nul
exit /b

:After7ZipAssoc

:: Install Python
python-3.12.10-amd64.exe /quiet InstallAllUsers=1 PrependPath=1 Include_test=0

:: Install voidImageViewer
voidImageViewer-1.0.0.15.x64.en-US-Setup.exe /S /install-options "/noappdata /nostartmenu"
copy /y "%~dp0voidImageViewer.ini" "%ProgramFiles%\voidImageViewer\voidImageViewer.ini"

:: Install Edge
start /wait msiexec /i "MicrosoftEdgeEnterpriseX64.msi" /qn /norestart DONOTCREATEDESKTOPSHORTCUT=true DONOTCREATETASKBARSHORTCUT=true

:: Install WebView2
start /wait MicrosoftEdgeWebView2RuntimeInstallerX64.exe /silent /install

:: Remove Edge Update triggers
powershell -NoProfile -Command "Get-ScheduledTask -TaskName 'MicrosoftEdgeUpdate*' -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:$false"
powershell -NoProfile -Command "Remove-ItemProperty 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run' -Name 'MicrosoftEdgeAutoLaunch*' -Force -EA 0"

:: Stop Edge Update services and kill process
sc stop edgeupdate >nul 2>&1
sc stop edgeupdatem >nul 2>&1
sc stop MicrosoftEdgeElevationService >nul 2>&1
taskkill /f /im MicrosoftEdgeUpdate.exe >nul 2>&1

:: Delete Edge Update services
sc delete edgeupdate >nul 2>&1
sc delete edgeupdatem >nul 2>&1
sc delete MicrosoftEdgeElevationService >nul 2>&1

:: Remove Edge Update directory
rd /s /q "%ProgramFiles(x86)%\Microsoft\EdgeUpdate" >nul 2>&1
