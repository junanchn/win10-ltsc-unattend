:: 禁用传递优化 (NETWORK SERVICE 配置)
reg add "HKU\S-1-5-20\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Settings" /v DownloadMode /t REG_DWORD /d 0 /f

:: 关闭视觉效果 (自定义设置)
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 3 /f
reg add "HKCU\Control Panel\Desktop" /v UserPreferencesMask /t REG_BINARY /d 9816078010000000 /f
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d "0" /f

:: 删除 Edge 自动更新计划任务
schtasks /delete /tn "MicrosoftEdgeUpdateTaskMachineCore" /f
schtasks /delete /tn "MicrosoftEdgeUpdateTaskMachineUA" /f

:: 删除不必要的计划任务
schtasks /Delete /TN "Microsoft\XblGameSave\XblGameSaveTask" /F
schtasks /Change /TN "Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" /Disable
schtasks /Change /TN "Microsoft\Windows\Application Experience\ProgramDataUpdater" /Disable
schtasks /Change /TN "Microsoft\Windows\Autochk\Proxy" /Disable
schtasks /Change /TN "Microsoft\Windows\Customer Experience Improvement Program\Consolidator" /Disable
schtasks /Change /TN "Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" /Disable
schtasks /Change /TN "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" /Disable
schtasks /Change /TN "Microsoft\Windows\Maintenance\WinSAT" /Disable
schtasks /Change /TN "Microsoft\Windows\NetTrace\GatherNetworkInfo" /Disable
schtasks /Change /TN "Microsoft\Windows\PI\Sqm-Tasks" /Disable
schtasks /Change /TN "Microsoft\Windows\Windows Error Reporting\QueueReporting" /Disable
schtasks /Change /TN "Microsoft\Windows\Defrag\ScheduledDefrag" /Disable

:: 虚拟机专用优化
if exist "%~dp0.vm" (
    :: 高性能电源方案
    powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    :: 关闭显示器超时设为“从不”
    powercfg /change monitor-timeout-ac 0
    powercfg /change monitor-timeout-dc 0
    :: 关闭休眠
    powercfg /h off
    :: 启用文件和打印机共享防火墙规则
    netsh advfirewall firewall set rule group="文件和打印机共享" new enable=yes
    :: 关闭防火墙
    netsh advfirewall set allprofiles state off
)
