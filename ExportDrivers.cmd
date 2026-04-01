mkdir "%~dp0Drivers\OS" 2>nul
dism /Online /Export-Driver /Destination:"%~dp0Drivers\OS"
pause
