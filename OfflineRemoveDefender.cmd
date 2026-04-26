@echo off
:: Fully removes Windows Defender from an offline WIM image.
:: Source: github.com/ionuttbara/windows-defender-remover

set "mountdir=%~1"
if "%mountdir%"=="" (
    echo Usage: %~nx0 ^<mount_directory^>
    exit /b 1
)

echo.
echo ============================================================
echo Removing Windows Defender from offline image...
echo ============================================================
echo.

:: ================================================================
::  SYSTEM hive
:: ================================================================
reg load "HKLM\Offline_SYSTEM" "%mountdir%\Windows\System32\config\SYSTEM"

:: ---- Deletions ----

:: Services: ordered by component, service-before-driver within each
for %%s in (
    WinDefend WdNisSvc WdNisDrv WdFilter WdBoot
    Sense
    MsSecCore MsSecFlt MsSecWfp
    wscsvc SecurityHealthService
    SgrmBroker SgrmAgent
    webthreatdefsvc webthreatdefusersvc
    whesvc
    PlutonHsp2 PlutonHeci Hsp
) do (
    reg delete "HKLM\Offline_SYSTEM\ControlSet001\Services\%%s" /f >nul 2>nul
)

:: WMI loggers
reg delete "HKLM\Offline_SYSTEM\ControlSet001\Control\WMI\Autologger\DefenderAuditLogger" /f >nul 2>nul
reg delete "HKLM\Offline_SYSTEM\ControlSet001\Control\WMI\Autologger\DefenderApiLogger" /f >nul 2>nul

:: UBPM maintenance
reg delete "HKLM\Offline_SYSTEM\ControlSet001\Control\Ubpm" /v CriticalMaintenance_DefenderCleanup /f >nul 2>nul
reg delete "HKLM\Offline_SYSTEM\ControlSet001\Control\Ubpm" /v CriticalMaintenance_DefenderVerification /f >nul 2>nul

:: Firewall rules: Defender first, then WebThreat
for %%v in (WindowsDefender-1 WindowsDefender-2 WindowsDefender-3 WebThreatDefSvc_Allow_In WebThreatDefSvc_Allow_Out WebThreatDefSvc_Block_In WebThreatDefSvc_Block_Out) do (
    reg delete "HKLM\Offline_SYSTEM\ControlSet001\Services\SharedAccess\Parameters\FirewallPolicy\RestrictedServices\Static\System" /v %%v /f >nul 2>nul
)
for %%v in ("{2A5FE97D-01A4-4A9C-8241-BB3755B65EE0}" "72e33e44-dc4c-40c5-a688-a77b6e988c69" "b23879b5-1ef3-45b7-8933-554a4303d2f3") do (
    reg delete "HKLM\Offline_SYSTEM\ControlSet001\Services\SharedAccess\Parameters\FirewallPolicy\RestrictedServices\Configurable\System" /v %%v /f >nul 2>nul
)

:: LSA stale value
reg delete "HKLM\Offline_SYSTEM\ControlSet001\Control\Lsa" /v LmCompatibilityLevel /f >nul 2>nul

:: ---- Additions: ordered from lowest-level to highest-level ----

:: Kernel mitigations
reg add "HKLM\Offline_SYSTEM\ControlSet001\Control\Session Manager\kernel" /v MitigationOptions /t REG_BINARY /d 002222202220222220000000002000200000000000000000 /f >nul
reg add "HKLM\Offline_SYSTEM\ControlSet001\Control\Session Manager\kernel" /v MitigationAuditOptions /t REG_BINARY /d 000000000000202200000000000000200000000000000000 /f >nul
reg add "HKLM\Offline_SYSTEM\ControlSet001\Control\Session Manager\kernel" /v KernelSEHOPEnabled /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SYSTEM\ControlSet001\Control\SCMConfig" /v EnableSvchostMitigationPolicy /t REG_QWORD /d 0 /f >nul

:: LSA protection
reg add "HKLM\Offline_SYSTEM\ControlSet001\Control\Lsa" /v RunAsPPL /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SYSTEM\ControlSet001\Control\Lsa" /v RunAsPPLBoot /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SYSTEM\ControlSet001\Control\Lsa" /v LsaConfigFlags /t REG_DWORD /d 0 /f >nul

:: Code Integrity / Smart App Control
reg add "HKLM\Offline_SYSTEM\ControlSet001\Control\CI\Config" /v VulnerableDriverBlocklistEnable /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SYSTEM\ControlSet001\Control\CI\Policy" /v VerifiedAndReputablePolicyState /t REG_DWORD /d 0 /f >nul

:: DeviceGuard / VBS: master switch, then scenario details
reg add "HKLM\Offline_SYSTEM\ControlSet001\Control\DeviceGuard" /v EnableVirtualizationBasedSecurity /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SYSTEM\ControlSet001\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SYSTEM\ControlSet001\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v EnabledBootId /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SYSTEM\ControlSet001\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v WasEnabledBy /t REG_DWORD /d 0 /f >nul

reg unload "HKLM\Offline_SYSTEM"
echo   SYSTEM hive: done.

:: ================================================================
::  SOFTWARE hive
:: ================================================================
reg load "HKLM\Offline_SOFTWARE" "%mountdir%\Windows\System32\config\SOFTWARE"

:: ---- Deletions: core data ----

powershell -ExecutionPolicy Bypass -File "%~dp0ForceDefenderCleanup.ps1" -HiveName "Offline_SOFTWARE"
reg delete "HKLM\Offline_SOFTWARE\Microsoft\Windows Security Health" /f >nul 2>nul
reg delete "HKLM\Offline_SOFTWARE\Microsoft\Security Center" /f >nul 2>nul

:: ---- Deletions: COM registrations (Defender, WebThreat, SecurityComp) ----

for %%g in (
    "{2781761E-28E0-4109-99FE-B9D127C57AFE}"
    "{2781761E-28E2-4109-99FE-B9D127C57AFE}"
    "{195B4D07-3DE2-4744-BBF2-D90121AE785B}"
    "{361290c0-cb1b-49ae-9f3e-ba1cbe5dab35}"
    "{45F2C32F-ED16-4C94-8493-D72EF93A051B}"
    "{6CED0DAA-4CDE-49C9-BA3A-AE163DC3D7AF}"
    "{8a696d12-576b-422e-9712-01b9dd84b446}"
    "{8C9C0DB7-2CBA-40F1-AFE0-C55740DD91A0}"
    "{A2D75874-6750-4931-94C1-C99D3BC9D0C7}"
    "{A7C452EF-8E9F-42EB-9F2B-245613CA0DC9}"
    "{DACA056E-216A-4FD1-84A6-C306A017ECEC}"
    "{E3C9166D-1D39-4D4E-A45D-BC7BE9B00578}"
    "{F6976CF5-68A8-436C-975A-40BE53616D59}"
) do (
    reg delete "HKLM\Offline_SOFTWARE\Classes\CLSID\%%~g" /f >nul 2>nul
    reg delete "HKLM\Offline_SOFTWARE\Classes\WOW6432Node\CLSID\%%~g" /f >nul 2>nul
    reg delete "HKLM\Offline_SOFTWARE\WOW6432Node\Classes\CLSID\%%~g" /f >nul 2>nul
)
reg delete "HKLM\Offline_SOFTWARE\Classes\CLSID\{E48B2549-D510-4A76-8A5F-FC126A6215F0}" /f >nul 2>nul
reg delete "HKLM\Offline_SOFTWARE\Classes\WOW6432Node\CLSID\{E48B2549-D510-4A76-8A5F-FC126A6215F0}" /f >nul 2>nul
for %%g in ("{BB64F8A7-BEE7-4E1A-AB8D-7D8273F7FDB6}") do (
    reg delete "HKLM\Offline_SOFTWARE\Classes\CLSID\%%~g" /f >nul 2>nul
    reg delete "HKLM\Offline_SOFTWARE\Classes\WOW6432Node\CLSID\%%~g" /f >nul 2>nul
    reg delete "HKLM\Offline_SOFTWARE\WOW6432Node\Classes\CLSID\%%~g" /f >nul 2>nul
    reg delete "HKLM\Offline_SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel\NameSpace\%%~g" /f >nul 2>nul
    reg delete "HKLM\Offline_SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel\NameSpace\%%~g" /f >nul 2>nul
)

:: ---- Deletions: WinRT registrations ----

for %%c in (
    Microsoft.OneCore.WebThreatDefense.Service.UserSessionServiceManager
    Microsoft.OneCore.WebThreatDefense.ThreatExperienceManager.ThreatExperienceManager
    Microsoft.OneCore.WebThreatDefense.ThreatResponseEngine.ThreatDecisionEngine
    Microsoft.OneCore.WebThreatDefense.Configuration.WTDUserSettings
) do (
    reg delete "HKLM\Offline_SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\%%c" /f >nul 2>nul
)
reg delete "HKLM\Offline_SOFTWARE\Microsoft\WindowsRuntime\Server\WebThreatDefSvc" /f >nul 2>nul

:: ---- Deletions: service host infrastructure ----

reg delete "HKLM\Offline_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Svchost\WebThreatDefense" /f >nul 2>nul
reg delete "HKLM\Offline_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Svchost" /v WebThreatDefense /f >nul 2>nul

:: ---- Deletions: scheduled tasks ----

for %%t in (
    "{0ACC9108-2000-46C0-8407-5FD9F89521E8}"
    "{1D77BCC8-1D07-42D0-8C89-3A98674DFB6F}"
    "{4A9233DB-A7D3-45D6-B476-8C7D8DF73EB5}"
    "{B05F34EE-83F2-413D-BC1D-7D5BD6E98300}"
) do (
    reg delete "HKLM\Offline_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\%%~t" /f >nul 2>nul
)

:: ---- Deletions: startup entries (by component) ----

reg delete "HKLM\Offline_SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v WindowsDefender /f >nul 2>nul
reg delete "HKLM\Offline_SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" /v "Windows Defender" /f >nul 2>nul
reg delete "HKLM\Offline_SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v SecurityHealth /f >nul 2>nul
reg delete "HKLM\Offline_SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" /v SecurityHealth /f >nul 2>nul

:: ---- Deletions: user interface (shell integration → app model → classes → cache) ----

reg delete "HKLM\Offline_SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ShellServiceObjects\{900c0763-5cad-4a34-bc1f-40cd513679d5}" /f >nul 2>nul
reg delete "HKLM\Offline_SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\ShellServiceObjects\{900c0763-5cad-4a34-bc1f-40cd513679d5}" /f >nul 2>nul
reg delete "HKLM\Offline_SOFTWARE\Classes\DesktopBackground\Shell\WindowsSecurity" /f >nul 2>nul
reg delete "HKLM\Offline_SOFTWARE\Classes\Folder\shell\WindowsDefender" /f >nul 2>nul
reg delete "HKLM\Offline_SOFTWARE\Classes\AppUserModelId\Windows.Defender" /f >nul 2>nul
reg delete "HKLM\Offline_SOFTWARE\Classes\AppUserModelId\Microsoft.Windows.Defender" /f >nul 2>nul
reg delete "HKLM\Offline_SOFTWARE\Classes\WindowsDefender" /f >nul 2>nul
reg delete "HKLM\Offline_SOFTWARE\Classes\AppX9kvz3rdv8t7twanaezbwfcdgrbg3bck0" /f >nul 2>nul
reg delete "HKLM\Offline_SOFTWARE\Classes\Local Settings\MrtCache\C:%%5CWindows%%5CSystemApps%%5CMicrosoft.Windows.AppRep.ChxApp_cw5n1h2txyewy%%5Cresources.pri" /f >nul 2>nul

:: ---- Deletions: policy cleanup ----

reg delete "HKLM\Offline_SOFTWARE\Microsoft\PolicyManager\default\WebThreatDefense" /f >nul 2>nul
reg delete "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows\WTDS" /f >nul 2>nul
reg delete "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows\System" /v ShellSmartScreenLevel /f >nul 2>nul

:: ---- Additions: core Defender policies (master switches first) ----

reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiSpyware /t REG_DWORD /d 1 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableRoutinelyTakingAction /t REG_DWORD /d 1 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableLocalAdminMerge /t REG_DWORD /d 1 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender" /v ServiceKeepAlive /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender" /v AllowFastServiceStartup /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender" /v PUAProtection /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender" /v RandomizeScheduleTaskTimes /t REG_DWORD /d 0 /f >nul

:: ---- Additions: engine ----

reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\Exclusions" /v DisableAutoExclusions /t REG_DWORD /d 1 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\MpEngine" /v MpEnablePus /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\MpEngine" /v MpCloudBlockLevel /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\MpEngine" /v MpBafsExtendedTimeout /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\MpEngine" /v EnableFileHashComputation /t REG_DWORD /d 0 /f >nul

:: ---- Additions: Real-Time Protection (disable features → lock overrides → config) ----

reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableRealtimeMonitoring /t REG_DWORD /d 1 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableBehaviorMonitoring /t REG_DWORD /d 1 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableOnAccessProtection /t REG_DWORD /d 1 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableScanOnRealtimeEnable /t REG_DWORD /d 1 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableIOAVProtection /t REG_DWORD /d 1 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableIntrusionPreventionSystem /t REG_DWORD /d 1 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableRawWriteNotification /t REG_DWORD /d 1 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableInformationProtectionControl /t REG_DWORD /d 1 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v LocalSettingOverrideDisableRealtimeMonitoring /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v LocalSettingOverrideDisableBehaviorMonitoring /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v LocalSettingOverrideDisableOnAccessProtection /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v LocalSettingOverrideDisableIOAVProtection /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v LocalSettingOverrideDisableIntrusionPreventionSystem /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v LocalSettingOverrideRealtimeScanDirection /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v RealtimeScanDirection /t REG_DWORD /d 2 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v IOAVMaxSize /t REG_DWORD /d 1298 /f >nul

:: ---- Additions: scanning (active disables first, then passive defaults) ----

reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\Scan" /v DisableHeuristics /t REG_DWORD /d 1 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\Scan" /v DisableReparsePointScanning /t REG_DWORD /d 1 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\Scan" /v DisableRestorePoint /t REG_DWORD /d 1 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\Scan" /v DisableCatchupQuickScan /t REG_DWORD /d 1 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\Scan" /v LowCpuPriority /t REG_DWORD /d 1 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\Scan" /v DisableArchiveScanning /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\Scan" /v DisableScanningNetworkFiles /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\Scan" /v DisableCatchupFullScan /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\Scan" /v DisableEmailScanning /t REG_DWORD /d 0 /f >nul

:: ---- Additions: signature updates ----

reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\Signature Updates" /v DisableUpdateOnStartupWithoutEngine /t REG_DWORD /d 1 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\Signature Updates" /v DisableScanOnUpdate /t REG_DWORD /d 1 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\Signature Updates" /v DisableScheduledSignatureUpdateOnBattery /t REG_DWORD /d 1 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\Signature Updates" /v SignatureDisableNotification /t REG_DWORD /d 1 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\Signature Updates" /v RealtimeSignatureDelivery /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\Signature Updates" /v ForceUpdateFromMU /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\Signature Updates" /v UpdateOnStartUp /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\Signature Updates" /v SignatureUpdateCatchupInterval /t REG_DWORD /d 2 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\Signature Updates" /v ScheduleTime /t REG_DWORD /d 5184 /f >nul

:: ---- Additions: cloud and reporting ----

reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" /v DisableBlockAtFirstSeen /t REG_DWORD /d 1 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" /v SpynetReporting /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" /v LocalSettingOverrideSpynetReporting /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" /v SubmitSamplesConsent /t REG_DWORD /d 2 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\Reporting" /v DisableEnhancedNotifications /t REG_DWORD /d 1 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\Reporting" /v DisableGenericRePorts /t REG_DWORD /d 1 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\Reporting" /v WppTracingLevel /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\Reporting" /v WppTracingComponents /t REG_DWORD /d 0 /f >nul

:: ---- Additions: network protection ----

reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\NIS\Consumers\IPS" /v DisableSignatureRetirement /t REG_DWORD /d 1 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\NIS\Consumers\IPS" /v DisableProtocolRecognition /t REG_DWORD /d 1 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\NIS\Consumers\IPS" /v ThrottleDetectionEventsRate /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\Policy Manager" /v DisableScanningNetworkFiles /t REG_DWORD /d 1 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\Network Protection" /v EnableNetworkProtection /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\Controlled Folder Access" /v EnableControlledFolderAccess /t REG_DWORD /d 0 /f >nul

:: ---- Additions: UX ----

reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\UX Configuration" /v SuppressRebootNotification /t REG_DWORD /d 1 /f >nul

:: ---- Additions: SmartScreen ----

reg add "HKLM\Offline_SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v SmartScreenEnabled /t REG_SZ /d "Off" /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows\System" /v EnableSmartScreen /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\SmartScreen" /v ConfigureAppInstallControlEnabled /t REG_DWORD /d 1 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender\SmartScreen" /v ConfigureAppInstallControl /t REG_SZ /d "Anywhere" /f >nul

:: ---- Additions: WTDS ----

reg add "HKLM\Offline_SOFTWARE\Microsoft\Windows\CurrentVersion\WTDS\Components" /v ServiceEnabled /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Microsoft\Windows\CurrentVersion\WTDS\Components" /v NotifyMalicious /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Microsoft\Windows\CurrentVersion\WTDS\Components" /v NotifyPasswordReuse /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Microsoft\Windows\CurrentVersion\WTDS\Components" /v NotifyUnsafeApp /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows\WTDS\Components" /v NotifyMalicious /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows\WTDS\Components" /v NotifyPasswordReuse /t REG_DWORD /d 0 /f >nul

:: ---- Additions: mitigation ----

reg add "HKLM\Offline_SOFTWARE\Microsoft\WindowsMitigation" /v UserPreference /t REG_DWORD /d 2 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows\System" /v RunAsPPL /t REG_DWORD /d 0 /f >nul

:: ---- Additions: legacy (Microsoft Antimalware, disable → service control → telemetry) ----

reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Microsoft Antimalware" /v DisableAntiSpyware /t REG_DWORD /d 1 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Microsoft Antimalware" /v DisableAntiVirus /t REG_DWORD /d 1 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Microsoft Antimalware" /v DisableRoutinelyTakingAction /t REG_DWORD /d 1 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Microsoft Antimalware" /v ServiceKeepAlive /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Microsoft Antimalware" /v AllowFastServiceStartup /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Microsoft Antimalware\SpyNet" /v SpyNetReporting /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Microsoft Antimalware\SpyNet" /v LocalSettingOverrideSpyNetReporting /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\WOW6432Node\Policies\Microsoft\Windows Defender" /v DisableRoutinelyTakingAction /t REG_DWORD /d 1 /f >nul
reg add "HKLM\Offline_SOFTWARE\Microsoft\RemovalTools\MpGears" /v HeartbeatTrackingIndex /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Microsoft\RemovalTools\MpGears" /v SpyNetReportingLocation /t REG_SZ /d "0" /f >nul

:: ---- Additions: notifications, security center, UI ----

reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Systray" /v HideSystray /t REG_DWORD /d 1 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Notifications" /v DisableNotifications /t REG_DWORD /d 1 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Notifications" /v DisableEnhancedNotifications /t REG_DWORD /d 1 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows Defender Security Center\App and Browser protection" /v DisallowExploitProtectionOverride /t REG_DWORD /d 1 /f >nul
reg add "HKLM\Offline_SOFTWARE\Microsoft\Security Center" /v FirstRunDisabled /t REG_DWORD /d 1 /f >nul
reg add "HKLM\Offline_SOFTWARE\Microsoft\Security Center" /v AntiVirusOverride /t REG_DWORD /d 1 /f >nul
reg add "HKLM\Offline_SOFTWARE\Microsoft\Security Center" /v FirewallOverride /t REG_DWORD /d 1 /f >nul
reg add "HKLM\Offline_SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v SettingsPageVisibility /t REG_SZ /d "hide:windowsdefender;" /f >nul

:: ---- Additions: Security Health ----

reg add "HKLM\Offline_SOFTWARE\Microsoft\Windows Security Health\Platform" /v Registered /t REG_DWORD /d 0 /f >nul

:: ---- Additions: MDM PolicyManager (Defender → SmartScreen → WebThreat → WDSC) ----

reg add "HKLM\Offline_SOFTWARE\Microsoft\PolicyManager\default\Defender\AllowIOAVProtection" /v value /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Microsoft\PolicyManager\default\Defender\AllowArchiveScanning" /v value /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Microsoft\PolicyManager\default\Defender\AllowBehaviorMonitoring" /v value /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Microsoft\PolicyManager\default\Defender\AllowCloudProtection" /v value /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Microsoft\PolicyManager\default\Defender\AllowEmailScanning" /v value /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Microsoft\PolicyManager\default\Defender\AllowFullScanOnMappedNetworkDrives" /v value /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Microsoft\PolicyManager\default\Defender\AllowFullScanRemovableDriveScanning" /v value /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Microsoft\PolicyManager\default\Defender\AllowIntrusionPreventionSystem" /v value /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Microsoft\PolicyManager\default\Defender\AllowOnAccessProtection" /v value /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Microsoft\PolicyManager\default\Defender\AllowRealtimeMonitoring" /v value /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Microsoft\PolicyManager\default\Defender\AllowScanningNetworkFiles" /v value /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Microsoft\PolicyManager\default\Defender\AllowScriptScanning" /v value /t REG_DWORD /d 1 /f >nul
reg add "HKLM\Offline_SOFTWARE\Microsoft\PolicyManager\default\Defender\AllowUserUIAccess" /v value /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Microsoft\PolicyManager\default\Defender\AvgCPULoadFactor" /v value /t REG_DWORD /d 50 /f >nul
reg add "HKLM\Offline_SOFTWARE\Microsoft\PolicyManager\default\Defender\CheckForSignaturesBeforeRunningScan" /v value /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Microsoft\PolicyManager\default\Defender\CloudBlockLevel" /v value /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Microsoft\PolicyManager\default\Defender\CloudExtendedTimeout" /v value /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Microsoft\PolicyManager\default\Defender\DaysToRetainCleanedMalware" /v value /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Microsoft\PolicyManager\default\Defender\DisableCatchupFullScan" /v value /t REG_DWORD /d 1 /f >nul
reg add "HKLM\Offline_SOFTWARE\Microsoft\PolicyManager\default\Defender\DisableCatchupQuickScan" /v value /t REG_DWORD /d 1 /f >nul
reg add "HKLM\Offline_SOFTWARE\Microsoft\PolicyManager\default\Defender\EnableControlledFolderAccess" /v value /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Microsoft\PolicyManager\default\Defender\EnableLowCPUPriority" /v value /t REG_DWORD /d 1 /f >nul
reg add "HKLM\Offline_SOFTWARE\Microsoft\PolicyManager\default\Defender\EnableNetworkProtection" /v value /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Microsoft\PolicyManager\default\Defender\PUAProtection" /v value /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Microsoft\PolicyManager\default\Defender\RealTimeScanDirection" /v value /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Microsoft\PolicyManager\default\Defender\ScanParameter" /v value /t REG_DWORD /d 2 /f >nul
reg add "HKLM\Offline_SOFTWARE\Microsoft\PolicyManager\default\Defender\ScheduleScanDay" /v value /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Microsoft\PolicyManager\default\Defender\ScheduleScanTime" /v value /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Microsoft\PolicyManager\default\Defender\SignatureUpdateInterval" /v value /t REG_DWORD /d 24 /f >nul
reg add "HKLM\Offline_SOFTWARE\Microsoft\PolicyManager\default\Defender\SubmitSamplesConsent" /v value /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Microsoft\PolicyManager\default\Browser\AllowSmartScreen" /v value /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Microsoft\PolicyManager\default\SmartScreen\EnableSmartScreenInShell" /v value /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Microsoft\PolicyManager\default\SmartScreen\EnableAppInstallControl" /v value /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Microsoft\PolicyManager\default\SmartScreen\PreventOverrideForFilesInShell" /v value /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Microsoft\PolicyManager\default\WebThreatDefense\AuditMode" /v value /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Microsoft\PolicyManager\default\WebThreatDefense\NotifyUnsafeOrReusedPassword" /v value /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Microsoft\PolicyManager\default\WebThreatDefense\ServiceEnabled" /v value /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Microsoft\PolicyManager\default\WindowsDefenderSecurityCenter\DisableNotifications" /v value /t REG_DWORD /d 1 /f >nul
reg add "HKLM\Offline_SOFTWARE\Microsoft\PolicyManager\default\WindowsDefenderSecurityCenter\DisableEnhancedNotifications" /v value /t REG_DWORD /d 1 /f >nul
reg add "HKLM\Offline_SOFTWARE\Microsoft\PolicyManager\default\WindowsDefenderSecurityCenter\HideWindowsSecurityNotificationAreaControl" /v value /t REG_DWORD /d 1 /f >nul

reg unload "HKLM\Offline_SOFTWARE"
echo   SOFTWARE hive: done.

:: ================================================================
::  Default user NTUSER.DAT
:: ================================================================
reg load "HKU\Offline_DEFAULT" "%mountdir%\Users\Default\NTUSER.DAT"

:: ---- Deletions (by component: Security Health → startup → shell) ----

reg delete "HKU\Offline_DEFAULT\Software\Microsoft\Windows Security Health" /f >nul 2>nul
reg delete "HKU\Offline_DEFAULT\Software\Microsoft\Windows\CurrentVersion\Run" /v "Windows Defender" /f >nul 2>nul
reg delete "HKU\Offline_DEFAULT\Software\Microsoft\Windows\CurrentVersion\Run" /v SecurityHealth /f >nul 2>nul
reg delete "HKU\Offline_DEFAULT\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\windowsdefender" /f >nul 2>nul
reg delete "HKU\Offline_DEFAULT\Software\Classes\ms-cxh" /f >nul 2>nul
reg delete "HKU\Offline_DEFAULT\Software\Classes\AppX9kvz3rdv8t7twanaezbwfcdgrbg3bck0" /f >nul 2>nul

:: ---- Additions (by component: SmartScreen → Security Health → notifications) ----

reg add "HKU\Offline_DEFAULT\Software\Microsoft\Edge" /v SmartScreenEnabled /t REG_DWORD /d 0 /f >nul
reg add "HKU\Offline_DEFAULT\Software\Microsoft\Edge\SmartScreenEnabled" /ve /t REG_DWORD /d 0 /f >nul
reg add "HKU\Offline_DEFAULT\Software\Microsoft\Edge\SmartScreenPuaEnabled" /ve /t REG_DWORD /d 0 /f >nul
reg add "HKU\Offline_DEFAULT\Software\Microsoft\Windows\CurrentVersion\AppHost" /v EnableWebContentEvaluation /t REG_DWORD /d 0 /f >nul
reg add "HKU\Offline_DEFAULT\Software\Microsoft\Windows\CurrentVersion\AppHost" /v PreventOverride /t REG_DWORD /d 0 /f >nul
reg add "HKU\Offline_DEFAULT\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppContainer\Storage\microsoft.microsoftedge_8wekyb3d8bbwe\MicrosoftEdge\PhishingFilter" /v EnabledV9 /t REG_DWORD /d 0 /f >nul
reg add "HKU\Offline_DEFAULT\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppContainer\Storage\microsoft.microsoftedge_8wekyb3d8bbwe\MicrosoftEdge\PhishingFilter" /v PreventOverride /t REG_DWORD /d 0 /f >nul
reg add "HKU\Offline_DEFAULT\Software\Microsoft\Windows Security Health\State" /v Disabled /t REG_DWORD /d 1 /f >nul
reg add "HKU\Offline_DEFAULT\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.SecurityAndMaintenance" /v Enabled /t REG_DWORD /d 0 /f >nul

reg unload "HKU\Offline_DEFAULT"
echo   Default user hive: done.

:: ================================================================
::  Delete Defender files from mounted image
:: ================================================================
echo   Deleting Defender files...
if exist "%mountdir%\Program Files\Windows Defender" (
    rd /s /q "%mountdir%\Program Files\Windows Defender" 2>nul
)
if exist "%mountdir%\Program Files (x86)\Windows Defender" (
    rd /s /q "%mountdir%\Program Files (x86)\Windows Defender" 2>nul
)
if exist "%mountdir%\Program Files\Windows Defender Advanced Threat Protection" (
    rd /s /q "%mountdir%\Program Files\Windows Defender Advanced Threat Protection" 2>nul
)
if exist "%mountdir%\ProgramData\Microsoft\Windows Defender" (
    rd /s /q "%mountdir%\ProgramData\Microsoft\Windows Defender" 2>nul
)
echo   Files: done.

:: ================================================================
::  Remove SecHealthUI UWP app (offline DISM)
:: ================================================================
echo   Removing SecHealthUI app...
for /f "tokens=2 delims=: " %%p in ('dism /image:"%mountdir%" /get-provisionedappxpackages 2^>nul ^| findstr /i "SecHealthUI"') do (
    dism /image:"%mountdir%" /remove-provisionedappxpackage /packagename:%%p >nul 2>nul
)
echo   UWP removal: done.

echo.
echo ============================================================
echo Windows Defender removed from offline image.
echo ============================================================
echo.
