cd /d "%~dp0"

:: Activate Windows
cmd /c C:\OEM\MAS_AIO.cmd /Z-Windows

:: Install 7-Zip
7z2600-x64.exe /S

:: Install Python
python-3.12.10-amd64.exe /quiet InstallAllUsers=1 PrependPath=1 Include_test=0

:: Install voidImageViewer
voidImageViewer-1.0.0.15.x64.en-US-Setup.exe /S

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
