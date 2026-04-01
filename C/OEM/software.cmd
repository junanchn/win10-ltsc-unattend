cd /d "%~dp0"

:: Activate Windows
cmd /c C:\OEM\MAS_AIO.cmd /Z-Windows

:: Install VMware Tools
:: VMwareTools\setup.exe /S /v "/qn REBOOT=R"

:: Install 7-Zip
:: 7z2600-x64.exe /S

:: Install Python
:: python-3.12.10-amd64.exe /quiet InstallAllUsers=1 PrependPath=1 Include_test=0
