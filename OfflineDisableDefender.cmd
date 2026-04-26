@echo off
:: Disables Windows Defender in an offline WIM image.
:: Source: github.com/ionuttbara/windows-defender-remover (ISO_Maker)

set "mountdir=%~1"
if "%mountdir%"=="" (
    echo Usage: %~nx0 ^<mount_directory^>
    exit /b 1
)

echo.
echo ============================================================
echo Disabling Windows Defender in offline image...
echo ============================================================
echo.

:: ---- SYSTEM hive ----
reg load "HKLM\Offline_SYSTEM" "%mountdir%\Windows\System32\config\SYSTEM"

for %%s in (Sense WdBoot WdFilter WdNisDrv WdNisSvc WinDefend) do (
    reg add "HKLM\Offline_SYSTEM\ControlSet001\Services\%%s" /v Start /t REG_DWORD /d 4 /f >nul
)

reg add "HKLM\Offline_SYSTEM\ControlSet001\Control\DeviceGuard" /v EnableVirtualizationBasedSecurity /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SYSTEM\ControlSet001\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SYSTEM\ControlSet001\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v EnabledBootId /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SYSTEM\ControlSet001\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v WasEnabledBy /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SYSTEM\ControlSet001\Control\CI\Policy" /v VerifiedAndReputablePolicyState /t REG_DWORD /d 0 /f >nul

reg unload "HKLM\Offline_SYSTEM"

:: ---- SOFTWARE hive ----
reg load "HKLM\Offline_SOFTWARE" "%mountdir%\Windows\System32\config\SOFTWARE"

reg add "HKLM\Offline_SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v SmartScreenEnabled /t REG_SZ /d "Off" /f >nul
reg add "HKLM\Offline_SOFTWARE\Microsoft\Windows\CurrentVersion\WTDS\Components" /v ServiceEnabled /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Microsoft\Windows\CurrentVersion\WTDS\Components" /v NotifyMalicious /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Microsoft\Windows\CurrentVersion\WTDS\Components" /v NotifyPasswordReuse /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Microsoft\Windows\CurrentVersion\WTDS\Components" /v NotifyUnsafeApp /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Systray" /v HideSystray /t REG_DWORD /d 1 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Notifications" /v DisableNotifications /t REG_DWORD /d 1 /f >nul

reg unload "HKLM\Offline_SOFTWARE"

:: ---- Default user NTUSER.DAT ----
reg load "HKU\Offline_DEFAULT" "%mountdir%\Users\Default\NTUSER.DAT"

reg add "HKU\Offline_DEFAULT\Software\Microsoft\Edge\SmartScreenEnabled" /ve /t REG_DWORD /d 0 /f >nul
reg add "HKU\Offline_DEFAULT\Software\Microsoft\Edge\SmartScreenPuaEnabled" /ve /t REG_DWORD /d 0 /f >nul
reg add "HKU\Offline_DEFAULT\Software\Microsoft\Windows\CurrentVersion\AppHost" /v EnableWebContentEvaluation /t REG_DWORD /d 0 /f >nul
reg add "HKU\Offline_DEFAULT\Software\Microsoft\Windows\CurrentVersion\AppHost" /v PreventOverride /t REG_DWORD /d 0 /f >nul

reg unload "HKU\Offline_DEFAULT"

echo Defender disabled in offline image.
echo.
