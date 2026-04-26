@echo off
:: Applies system optimizations to an offline WIM image.

set "mountdir=%~1"
if "%mountdir%"=="" (
    echo Usage: %~nx0 ^<mount_directory^>
    exit /b 1
)

echo.
echo ============================================================
echo Applying system optimizations to offline image...
echo ============================================================
echo.

:: ================================================================
::  SYSTEM hive
:: ================================================================
reg load "HKLM\Offline_SYSTEM" "%mountdir%\Windows\System32\config\SYSTEM"

:: ---- 禁用 SysMain (Superfetch) ----
reg add "HKLM\Offline_SYSTEM\ControlSet001\Services\SysMain" /v Start /t REG_DWORD /d 4 /f >nul

:: ---- 禁用 IPv6 隧道转换 ----
reg add "HKLM\Offline_SYSTEM\ControlSet001\Services\iphlpsvc" /v Start /t REG_DWORD /d 4 /f >nul

:: ---- 禁用远程访问连接管理 ----
reg add "HKLM\Offline_SYSTEM\ControlSet001\Services\RasMan" /v Start /t REG_DWORD /d 4 /f >nul

:: ---- 禁用 SSTP VPN 协议 ----
reg add "HKLM\Offline_SYSTEM\ControlSet001\Services\SstpSvc" /v Start /t REG_DWORD /d 4 /f >nul

:: ---- 关闭遥测服务 ----
reg add "HKLM\Offline_SYSTEM\ControlSet001\Services\DiagTrack" /v Start /t REG_DWORD /d 4 /f >nul

:: ---- 禁用错误报告 ----
reg add "HKLM\Offline_SYSTEM\ControlSet001\Services\WerSvc" /v Start /t REG_DWORD /d 4 /f >nul

:: ---- 禁用 Windows Update 相关服务 ----
reg add "HKLM\Offline_SYSTEM\ControlSet001\Services\BITS" /v Start /t REG_DWORD /d 4 /f >nul
reg add "HKLM\Offline_SYSTEM\ControlSet001\Services\wuauserv" /v Start /t REG_DWORD /d 4 /f >nul

:: ---- 禁用 Windows 更新编排服务 (改为手动) ----
reg add "HKLM\Offline_SYSTEM\ControlSet001\Services\UsoSvc" /v Start /t REG_DWORD /d 3 /f >nul

:: ---- 禁用 Windows 更新医生服务 ----
reg add "HKLM\Offline_SYSTEM\ControlSet001\Services\WaaSMedicSvc" /v Start /t REG_DWORD /d 4 /f >nul

:: ---- 禁用传递优化服务 ----
reg add "HKLM\Offline_SYSTEM\ControlSet001\Services\DoSvc" /v Start /t REG_DWORD /d 4 /f >nul

:: ---- 禁用 Windows Insider 服务 ----
reg add "HKLM\Offline_SYSTEM\ControlSet001\Services\wisvc" /v Start /t REG_DWORD /d 4 /f >nul

:: ---- 禁用 Edge 开机自动更新 ----
reg add "HKLM\Offline_SYSTEM\ControlSet001\Services\edgeupdate" /v Start /t REG_DWORD /d 4 /f >nul
reg add "HKLM\Offline_SYSTEM\ControlSet001\Services\edgeupdatem" /v Start /t REG_DWORD /d 4 /f >nul

:: ---- 禁用微软商店相关服务 ----
reg add "HKLM\Offline_SYSTEM\ControlSet001\Services\LicenseManager" /v Start /t REG_DWORD /d 4 /f >nul
reg add "HKLM\Offline_SYSTEM\ControlSet001\Services\PushToInstall" /v Start /t REG_DWORD /d 4 /f >nul

:: ---- 禁用 Xbox 相关服务 ----
reg add "HKLM\Offline_SYSTEM\ControlSet001\Services\XboxGipSvc" /v Start /t REG_DWORD /d 4 /f >nul
reg add "HKLM\Offline_SYSTEM\ControlSet001\Services\XblAuthManager" /v Start /t REG_DWORD /d 4 /f >nul
reg add "HKLM\Offline_SYSTEM\ControlSet001\Services\XblGameSave" /v Start /t REG_DWORD /d 4 /f >nul
reg add "HKLM\Offline_SYSTEM\ControlSet001\Services\XboxNetApiSvc" /v Start /t REG_DWORD /d 4 /f >nul

:: ---- 禁用 Windows Search ----
reg add "HKLM\Offline_SYSTEM\ControlSet001\Services\WSearch" /v Start /t REG_DWORD /d 4 /f >nul

:: ---- 禁用程序兼容性助手 ----
reg add "HKLM\Offline_SYSTEM\ControlSet001\Services\PcaSvc" /v Start /t REG_DWORD /d 4 /f >nul

:: ---- 禁用 NTFS 链接跟踪服务 ----
powershell -ExecutionPolicy Bypass -File "%~dp0ForceRegWrite.ps1" -Key "Offline_SYSTEM\ControlSet001\Services\TrkWks" -Name Start -Type DWORD -Value 4

:: ---- 禁用自动播放 ----
reg add "HKLM\Offline_SYSTEM\ControlSet001\Services\ShellHWDetection" /v Start /t REG_DWORD /d 4 /f >nul

:: ---- 禁用脱机文件服务 ----
reg add "HKLM\Offline_SYSTEM\ControlSet001\Services\CscService" /v Start /t REG_DWORD /d 4 /f >nul

:: ---- 禁用离线地图管理服务 ----
reg add "HKLM\Offline_SYSTEM\ControlSet001\Services\MapsBroker" /v Start /t REG_DWORD /d 4 /f >nul

:: ---- 禁用零售演示服务 ----
reg add "HKLM\Offline_SYSTEM\ControlSet001\Services\RetailDemo" /v Start /t REG_DWORD /d 4 /f >nul

:: ---- 禁用 UDK 用户服务 ----
reg add "HKLM\Offline_SYSTEM\ControlSet001\Services\UdkUserSvc" /v Start /t REG_DWORD /d 4 /f >nul

:: ---- 禁用分布式事务协调器 ----
reg add "HKLM\Offline_SYSTEM\ControlSet001\Services\MSDTC" /v Start /t REG_DWORD /d 4 /f >nul

:: ---- 禁用触摸键盘服务 ----
reg add "HKLM\Offline_SYSTEM\ControlSet001\Services\TabletInputService" /v Start /t REG_DWORD /d 4 /f >nul

:: ---- 诊断服务改为手动启动 ----
powershell -ExecutionPolicy Bypass -File "%~dp0ForceRegWrite.ps1" -Key "Offline_SYSTEM\ControlSet001\Services\DPS" -Name Start -Type DWORD -Value 3

:: ---- 微软账户数据同步改为手动启动 ----
reg add "HKLM\Offline_SYSTEM\ControlSet001\Services\OneSyncSvc" /v Start /t REG_DWORD /d 3 /f >nul

:: ---- 加密服务改为手动启动 ----
reg add "HKLM\Offline_SYSTEM\ControlSet001\Services\CryptSvc" /v Start /t REG_DWORD /d 3 /f >nul

:: ---- 软件保护服务改为手动启动 ----
reg add "HKLM\Offline_SYSTEM\ControlSet001\Services\sppsvc" /v Start /t REG_DWORD /d 3 /f >nul

:: ---- 禁用路径长度限制 ----
reg add "HKLM\Offline_SYSTEM\ControlSet001\Control\FileSystem" /v LongPathsEnabled /t REG_DWORD /d 1 /f >nul

:: ---- 允许空密码远程登录 (虚拟机用) ----
if "%VM_MODE%"=="1" reg add "HKLM\Offline_SYSTEM\ControlSet001\Control\Lsa" /v LimitBlankPasswordUse /t REG_DWORD /d 0 /f >nul

:: ---- 禁用无线电管理服务 (虚拟机用) ----
if "%VM_MODE%"=="1" reg add "HKLM\Offline_SYSTEM\ControlSet001\Services\RmSvc" /v Start /t REG_DWORD /d 4 /f >nul

:: ---- 禁用蓝牙支持服务 (虚拟机用) ----
if "%VM_MODE%"=="1" reg add "HKLM\Offline_SYSTEM\ControlSet001\Services\bthserv" /v Start /t REG_DWORD /d 4 /f >nul

:: ---- 禁用蓝牙音视频控制协议 (虚拟机用) ----
if "%VM_MODE%"=="1" reg add "HKLM\Offline_SYSTEM\ControlSet001\Services\BthAvctpSvc" /v Start /t REG_DWORD /d 4 /f >nul

reg unload "HKLM\Offline_SYSTEM"
echo   SYSTEM hive: done.

:: ================================================================
::  SOFTWARE hive
:: ================================================================
reg load "HKLM\Offline_SOFTWARE" "%mountdir%\Windows\System32\config\SOFTWARE"

:: ---- 关闭系统还原 ----
reg add "HKLM\Offline_SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v RPSessionInterval /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v DisableSR /t REG_DWORD /d 1 /f >nul

:: ---- 启用远程管理 (禁用UAC远程限制) ----
reg add "HKLM\Offline_SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v LocalAccountTokenFilterPolicy /t REG_DWORD /d 1 /f >nul

:: ---- 关闭打开程序的“安全警告” ----
reg add "HKLM\Offline_SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Associations" /v LowRiskFileTypes /t REG_SZ /d ".exe;.bat;.cmd;.com;.msi;.reg;.ps1;.vbs;.js;.chm" /f >nul

:: ---- 设置 PowerShell 执行策略为 Bypass ----
reg add "HKLM\Offline_SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell" /v ExecutionPolicy /t REG_SZ /d "Bypass" /f >nul

:: ---- 关闭SmartScreen应用筛选器 ----
reg add "HKLM\Offline_SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v SmartScreenEnabled /t REG_SZ /d "Off" /f >nul

:: ---- 通过策略禁用遥测数据收集 ----
reg add "HKLM\Offline_SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v MicrosoftEdgeDataOptIn /t REG_DWORD /d 0 /f >nul

:: ---- 禁用客户体验改善计划 ----
reg add "HKLM\Offline_SOFTWARE\Microsoft\SQMClient\Windows" /v CEIPEnable /t REG_DWORD /d 0 /f >nul

:: ---- 禁用微软实验 (A/B测试) ----
reg add "HKLM\Offline_SOFTWARE\Microsoft\PolicyManager\current\device\System" /v AllowExperimentation /t REG_DWORD /d 0 /f >nul
reg add "HKLM\Offline_SOFTWARE\Microsoft\PolicyManager\default\System\AllowExperimentation" /v value /t REG_DWORD /d 0 /f >nul

:: ---- 禁用自动更新策略 ----
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v AUOptions /t REG_DWORD /d 1 /f >nul
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 1 /f >nul

:: ---- Edge ----
:: 隐藏首次运行欢迎页面
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Edge" /v HideFirstRunExperience /t REG_DWORD /d 1 /f >nul
:: 禁用启动增强
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Edge" /v StartupBoostEnabled /t REG_DWORD /d 0 /f >nul
:: 关闭后台运行
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Edge" /v BackgroundModeEnabled /t REG_DWORD /d 0 /f >nul
:: 关闭诊断数据收集
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Edge" /v DiagnosticData /t REG_DWORD /d 0 /f >nul
:: 禁用购物助手
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Edge" /v EdgeShoppingAssistantEnabled /t REG_DWORD /d 0 /f >nul
:: 禁用集锦
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Edge" /v EdgeCollectionsEnabled /t REG_DWORD /d 0 /f >nul
:: 禁用新标签页新闻内容
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Edge" /v NewTabPageContentEnabled /t REG_DWORD /d 0 /f >nul
:: 隐藏新标签页默认推广站点
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Edge" /v NewTabPageHideDefaultTopSites /t REG_DWORD /d 1 /f >nul
:: 禁用个性化数据上报
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Edge" /v PersonalizationReportingEnabled /t REG_DWORD /d 0 /f >nul
:: 禁用 Microsoft Rewards
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Edge" /v ShowMicrosoftRewards /t REG_DWORD /d 0 /f >nul
:: 导航错误不通过Web服务解析
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Edge" /v ResolveNavigationErrorsUseWebService /t REG_DWORD /d 0 /f >nul
:: 禁用功能推荐通知
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Edge" /v ShowRecommendationsEnabled /t REG_DWORD /d 0 /f >nul
:: 禁用侧边栏
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Edge" /v HubsSidebarEnabled /t REG_DWORD /d 0 /f >nul
:: 禁用新标签页预渲染
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Edge" /v NewTabPagePrerenderEnabled /t REG_DWORD /d 0 /f >nul
:: 禁用新标签页快速链接
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Edge" /v NewTabPageQuickLinksEnabled /t REG_DWORD /d 0 /f >nul
:: 禁用用户反馈
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Edge" /v UserFeedbackAllowed /t REG_DWORD /d 0 /f >nul
:: 禁用微软服务推广
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Edge" /v SpotlightExperiencesAndRecommendationsEnabled /t REG_DWORD /d 0 /f >nul
:: 禁用家庭安全
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Edge" /v FamilySafetySettingsEnabled /t REG_DWORD /d 0 /f >nul
:: 禁用自动更新检查
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\EdgeUpdate" /v AutoUpdateCheckPeriodMinutes /t REG_DWORD /d 0 /f >nul

:: ---- 禁用按需字体下载 ----
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows\System" /v EnableFontProviders /t REG_DWORD /d 0 /f >nul

:: ---- 隐藏任务栏上的人脉 ----
reg add "HKLM\Offline_SOFTWARE\Policies\Microsoft\Windows\Explorer" /v HidePeopleBar /t REG_DWORD /d 1 /f >nul

:: ---- 隐藏此电脑中的七个文件夹 ----
:: 3D对象 / 音乐 / 下载 / 图片 / 视频 / 文档 / 桌面
for %%g in (
    "{31C0DD25-9439-4F12-BF41-7FF4EDA38722}"
    "{a0c69a99-21c8-4671-8703-7934162fcf1d}"
    "{7d83ee9b-2244-4e70-b1f5-5393042af1e4}"
    "{0ddd015d-b06c-45d5-8c4c-f59713854639}"
    "{35286a68-3c57-41a1-bbb1-0eae73d76c95}"
    "{f42ee2d3-909f-4907-8871-4c22fc0bf756}"
    "{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}"
) do (
    reg add "HKLM\Offline_SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\%%~g\PropertyBag" /v ThisPCPolicy /t REG_SZ /d Hide /f >nul
    reg add "HKLM\Offline_SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\%%~g\PropertyBag" /v ThisPCPolicy /t REG_SZ /d Hide /f >nul
)

:: ---- 禁用“画图 3D”右键菜单 ----
for %%e in (.3mf .bmp .fbx .gif .glb .jfif .jpe .jpeg .jpg .obj .ply .png .stl .tif .tiff) do (
    reg delete "HKLM\Offline_SOFTWARE\Classes\SystemFileAssociations\%%e\Shell\3D Edit" /f >nul 2>nul
)

:: ---- 禁用右键菜单和属性页的“还原以前的版本” ----
for %%r in (AllFilesystemObjects "CLSID\{450D8FBA-AD25-11D0-98A8-0800361B1103}" Directory Drive) do (
    reg delete "HKLM\Offline_SOFTWARE\Classes\%%~r\shellex\ContextMenuHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}" /f >nul 2>nul
    reg delete "HKLM\Offline_SOFTWARE\Classes\%%~r\shellex\PropertySheetHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}" /f >nul 2>nul
)

:: ---- 禁用文件夹的“包含到库中”右键菜单 ----
reg delete "HKLM\Offline_SOFTWARE\Classes\Folder\shellex\ContextMenuHandlers\Library Location" /f >nul 2>nul

:: ---- 禁用磁盘的“启用BitLocker”右键菜单 ----
reg delete "HKLM\Offline_SOFTWARE\Classes\Drive\shell\encrypt-bde" /f >nul 2>nul
reg delete "HKLM\Offline_SOFTWARE\Classes\Drive\shell\encrypt-bde-elev" /f >nul 2>nul

reg unload "HKLM\Offline_SOFTWARE"
echo   SOFTWARE hive: done.

:: ================================================================
::  Default user NTUSER.DAT (applies to all new user profiles)
:: ================================================================
reg load "HKU\Offline_DEFAULT" "%mountdir%\Users\Default\NTUSER.DAT"

:: ---- 关闭打开程序的“安全警告” ----
reg add "HKU\Offline_DEFAULT\Software\Microsoft\Windows\CurrentVersion\Policies\Associations" /v LowRiskFileTypes /t REG_SZ /d ".exe;.bat;.cmd;.com;.msi;.reg;.ps1;.vbs;.js;.chm" /f >nul

:: ---- 关闭反馈频率 (设置→隐私→诊断和反馈→反馈频率) ----
reg add "HKU\Offline_DEFAULT\Software\Microsoft\Siuf\Rules" /v NumberOfSIUFInPeriod /t REG_DWORD /d 0 /f >nul

:: ---- 禁用 Game Bar ----
reg add "HKU\Offline_DEFAULT\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v AppCaptureEnabled /t REG_DWORD /d 0 /f >nul
reg add "HKU\Offline_DEFAULT\System\GameConfigStore" /v GameDVR_Enabled /t REG_DWORD /d 0 /f >nul

:: ---- 禁用游戏模式 ----
reg add "HKU\Offline_DEFAULT\Software\Microsoft\GameBar" /v AutoGameModeEnabled /t REG_DWORD /d 0 /f >nul

:: ---- 禁用自动播放 ----
reg add "HKU\Offline_DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers" /v DisableAutoplay /t REG_DWORD /d 1 /f >nul

:: ---- 隐藏任务栏搜索框 (0=隐藏 1=图标 2=搜索框) ----
reg add "HKU\Offline_DEFAULT\Software\Microsoft\Windows\CurrentVersion\Search" /v SearchboxTaskbarMode /t REG_DWORD /d 0 /f >nul

:: ---- 隐藏任务视图按钮 ----
reg add "HKU\Offline_DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowTaskViewButton /t REG_DWORD /d 0 /f >nul

:: ---- 隐藏任务栏上的人脉 ----
reg add "HKU\Offline_DEFAULT\Software\Policies\Microsoft\Windows\Explorer" /v HidePeopleBar /t REG_DWORD /d 1 /f >nul

:: ---- 显示所有文件扩展名 ----
reg add "HKU\Offline_DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d 0 /f >nul

:: ---- 创建快捷方式时不添加“快捷方式”文字 ----
reg add "HKU\Offline_DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer" /v link /t REG_BINARY /d 00000000 /f >nul

:: ---- 开机自动打开小键盘 ----
reg add "HKU\Offline_DEFAULT\Control Panel\Keyboard" /v InitialKeyboardIndicators /t REG_SZ /d "2" /f >nul

reg unload "HKU\Offline_DEFAULT"
echo   Default user hive: done.

:: ================================================================
::  .DEFAULT profile (登录界面小键盘)
:: ================================================================
reg load "HKU\Offline_SYSDEFAULT" "%mountdir%\Windows\System32\config\DEFAULT"

:: ---- 开机自动打开小键盘 ----
reg add "HKU\Offline_SYSDEFAULT\Control Panel\Keyboard" /v InitialKeyboardIndicators /t REG_SZ /d "2" /f >nul

reg unload "HKU\Offline_SYSDEFAULT"
echo   .DEFAULT profile: done.

echo.
echo ============================================================
echo System optimizations applied to offline image.
echo ============================================================
echo.
