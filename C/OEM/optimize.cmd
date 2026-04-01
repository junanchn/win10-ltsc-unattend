:: 关闭系统还原
powershell -Command "Disable-ComputerRestore -Drive 'C:\'"
vssadmin delete shadows /all /quiet

:: 关闭显示器超时设为"从不"
powercfg /change monitor-timeout-ac 0
powercfg /change monitor-timeout-dc 0

:: 禁用 SysMain (Superfetch)
sc config SysMain start= disabled
sc stop SysMain

:: 启用文件和打印机共享防火墙规则
netsh advfirewall firewall set rule group="文件和打印机共享" new enable=yes

:: 禁用 IPv6 隧道转换
sc config iphlpsvc start= disabled
sc stop iphlpsvc

:: 禁用远程访问连接管理
sc config RasMan start= disabled
sc stop RasMan

:: 禁用 SSTP VPN 协议
sc config SstpSvc start= disabled
sc stop SstpSvc

:: 启用远程管理 (禁用UAC远程限制)
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v LocalAccountTokenFilterPolicy /t REG_DWORD /d 1 /f

:: 关闭打开程序的"安全警告"
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Associations" /v LowRiskFileTypes /t REG_SZ /d ".exe;.bat;.cmd;.com;.msi;.reg;.ps1;.vbs;.js;.chm" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Associations" /v LowRiskFileTypes /t REG_SZ /d ".exe;.bat;.cmd;.com;.msi;.reg;.ps1;.vbs;.js;.chm" /f

:: 关闭SmartScreen应用筛选器
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v SmartScreenEnabled /t REG_SZ /d "Off" /f

:: 关闭遥测服务
sc config DiagTrack start= disabled
sc stop DiagTrack

:: 通过策略禁用遥测数据收集
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "MicrosoftEdgeDataOptIn" /t REG_DWORD /d 0 /f

:: 禁用客户体验改善计划
reg add "HKLM\SOFTWARE\Microsoft\SQMClient\Windows" /v CEIPEnable /t REG_DWORD /d 0 /f

:: 禁用微软实验 (A/B测试)
reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\current\device\System" /v "AllowExperimentation" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\default\System\AllowExperimentation" /v "value" /t REG_DWORD /d 0 /f

:: 关闭反馈频率 (设置→隐私→诊断和反馈→反馈频率)
reg add "HKCU\SOFTWARE\Microsoft\Siuf\Rules" /v NumberOfSIUFInPeriod /t REG_DWORD /d 0 /f

:: 禁用错误报告
sc config WerSvc start= disabled

:: 禁用 Windows Update 相关服务
sc config BITS start= disabled
sc stop BITS
sc config wuauserv start= disabled
sc stop wuauserv
sc config UsoSvc start= disabled
sc stop UsoSvc

:: 禁用 Windows 更新医生服务
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" /v Start /t REG_DWORD /d 4 /f
sc stop WaaSMedicSvc

:: 禁用传递优化服务
reg add "HKU\S-1-5-20\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Settings" /v DownloadMode /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\DoSvc" /v Start /t REG_DWORD /d 4 /f
sc stop DoSvc

:: 禁用自动更新策略
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v AUOptions /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 1 /f

:: 禁用 Windows Insider 服务
sc config wisvc start= disabled

:: 禁用 Edge 首次运行欢迎页面
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v HideFirstRunExperience /t REG_DWORD /d 1 /f

:: 禁用 Edge 开机自动更新
reg add "HKLM\SOFTWARE\Policies\Microsoft\EdgeUpdate" /v AutoUpdateCheckPeriodMinutes /t REG_DWORD /d 0 /f
sc config edgeupdate start= disabled
sc config edgeupdatem start= disabled
schtasks /delete /tn "MicrosoftEdgeUpdateTaskMachineCore" /f
schtasks /delete /tn "MicrosoftEdgeUpdateTaskMachineUA" /f

:: 禁用微软商店相关服务
sc config LicenseManager start= disabled
sc config PushToInstall start= disabled

:: 禁用 Game Bar
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" /v AppCaptureEnabled /t REG_DWORD /d 0 /f
reg add "HKCU\System\GameConfigStore" /v GameDVR_Enabled /t REG_DWORD /d 0 /f

:: 禁用游戏模式
reg add "HKCU\SOFTWARE\Microsoft\GameBar" /v AutoGameModeEnabled /t REG_DWORD /d 0 /f

:: 禁用 Xbox 相关服务
sc config XboxGipSvc start= disabled
sc config XblAuthManager start= disabled
sc config XblGameSave start= disabled
sc config XboxNetApiSvc start= disabled

:: 禁用 Windows Search
sc config WSearch start= disabled
sc stop WSearch

:: 禁用程序兼容性助手
sc config PcaSvc start= disabled
sc stop PcaSvc

:: 禁用 NTFS 链接跟踪服务
sc config TrkWks start= disabled
sc stop TrkWks

:: 禁用自动播放
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers" /v DisableAutoplay /t REG_DWORD /d 1 /f
sc config ShellHWDetection start= disabled
sc stop ShellHWDetection

:: 禁用脱机文件服务
sc config CscService start= disabled
sc stop CscService

:: 禁用离线地图管理服务
sc config MapsBroker start= disabled
sc stop MapsBroker

:: 禁用零售演示服务
sc config RetailDemo start= disabled

:: 禁用 UDK 用户服务
sc config UdkUserSvc start= disabled

:: 禁用分布式事务协调器
sc config MSDTC start= disabled
sc stop MSDTC

:: 禁用按需字体下载
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v EnableFontProviders /t REG_DWORD /d 0 /f

:: 禁用触摸键盘服务
sc config TabletInputService start= disabled
sc stop TabletInputService

:: 诊断服务改为手动启动
sc config DPS start= demand

:: 微软账户数据同步改为手动启动
sc config OneSyncSvc start= demand

:: 加密服务改为手动启动
sc config CryptSvc start= demand

:: 软件保护服务改为手动启动
reg add "HKLM\SYSTEM\CurrentControlSet\Services\sppsvc" /v Start /t REG_DWORD /d 3 /f

:: 关闭视觉效果 (自定义设置)
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 3 /f
reg add "HKCU\Control Panel\Desktop" /v UserPreferencesMask /t REG_BINARY /d 9816078010000000 /f
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d "0" /f

:: 隐藏任务栏搜索框 (0=隐藏 1=图标 2=搜索框)
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v SearchboxTaskbarMode /t REG_DWORD /d 0 /f

:: 隐藏任务视图按钮
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowTaskViewButton /t REG_DWORD /d 0 /f

:: 隐藏任务栏上的人脉
reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v HidePeopleBar /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v HidePeopleBar /t REG_DWORD /d 1 /f

:: 显示所有文件扩展名
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d 0 /f

:: 创建快捷方式时不添加"快捷方式"文字
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v link /t REG_BINARY /d 00000000 /f

:: 隐藏此电脑中的七个文件夹
:: 3D对象
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{31C0DD25-9439-4F12-BF41-7FF4EDA38722}\PropertyBag" /v ThisPCPolicy /t REG_SZ /d Hide /f
reg add "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{31C0DD25-9439-4F12-BF41-7FF4EDA38722}\PropertyBag" /v ThisPCPolicy /t REG_SZ /d Hide /f
:: 音乐
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{a0c69a99-21c8-4671-8703-7934162fcf1d}\PropertyBag" /v ThisPCPolicy /t REG_SZ /d Hide /f
reg add "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{a0c69a99-21c8-4671-8703-7934162fcf1d}\PropertyBag" /v ThisPCPolicy /t REG_SZ /d Hide /f
:: 下载
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{7d83ee9b-2244-4e70-b1f5-5393042af1e4}\PropertyBag" /v ThisPCPolicy /t REG_SZ /d Hide /f
reg add "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{7d83ee9b-2244-4e70-b1f5-5393042af1e4}\PropertyBag" /v ThisPCPolicy /t REG_SZ /d Hide /f
:: 图片
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{0ddd015d-b06c-45d5-8c4c-f59713854639}\PropertyBag" /v ThisPCPolicy /t REG_SZ /d Hide /f
reg add "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{0ddd015d-b06c-45d5-8c4c-f59713854639}\PropertyBag" /v ThisPCPolicy /t REG_SZ /d Hide /f
:: 视频
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{35286a68-3c57-41a1-bbb1-0eae73d76c95}\PropertyBag" /v ThisPCPolicy /t REG_SZ /d Hide /f
reg add "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{35286a68-3c57-41a1-bbb1-0eae73d76c95}\PropertyBag" /v ThisPCPolicy /t REG_SZ /d Hide /f
:: 文档
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{f42ee2d3-909f-4907-8871-4c22fc0bf756}\PropertyBag" /v ThisPCPolicy /t REG_SZ /d Hide /f
reg add "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{f42ee2d3-909f-4907-8871-4c22fc0bf756}\PropertyBag" /v ThisPCPolicy /t REG_SZ /d Hide /f
:: 桌面
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}\PropertyBag" /v ThisPCPolicy /t REG_SZ /d Hide /f
reg add "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}\PropertyBag" /v ThisPCPolicy /t REG_SZ /d Hide /f

:: 禁用"画图 3D"右键菜单
reg delete "HKCR\SystemFileAssociations\.3mf\Shell\3D Edit" /f
reg delete "HKCR\SystemFileAssociations\.bmp\Shell\3D Edit" /f
reg delete "HKCR\SystemFileAssociations\.fbx\Shell\3D Edit" /f
reg delete "HKCR\SystemFileAssociations\.gif\Shell\3D Edit" /f
reg delete "HKCR\SystemFileAssociations\.glb\Shell\3D Edit" /f
reg delete "HKCR\SystemFileAssociations\.jfif\Shell\3D Edit" /f
reg delete "HKCR\SystemFileAssociations\.jpe\Shell\3D Edit" /f
reg delete "HKCR\SystemFileAssociations\.jpeg\Shell\3D Edit" /f
reg delete "HKCR\SystemFileAssociations\.jpg\Shell\3D Edit" /f
reg delete "HKCR\SystemFileAssociations\.obj\Shell\3D Edit" /f
reg delete "HKCR\SystemFileAssociations\.ply\Shell\3D Edit" /f
reg delete "HKCR\SystemFileAssociations\.png\Shell\3D Edit" /f
reg delete "HKCR\SystemFileAssociations\.stl\Shell\3D Edit" /f
reg delete "HKCR\SystemFileAssociations\.tif\Shell\3D Edit" /f
reg delete "HKCR\SystemFileAssociations\.tiff\Shell\3D Edit" /f

:: 禁用右键菜单和属性页的"还原以前版本"
reg delete "HKCR\AllFilesystemObjects\shellex\ContextMenuHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}" /f
reg delete "HKCR\CLSID\{450D8FBA-AD25-11D0-98A8-0800361B1103}\shellex\ContextMenuHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}" /f
reg delete "HKCR\Directory\shellex\ContextMenuHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}" /f
reg delete "HKCR\Drive\shellex\ContextMenuHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}" /f
reg delete "HKCR\AllFilesystemObjects\shellex\PropertySheetHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}" /f
reg delete "HKCR\CLSID\{450D8FBA-AD25-11D0-98A8-0800361B1103}\shellex\PropertySheetHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}" /f
reg delete "HKCR\Directory\shellex\PropertySheetHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}" /f
reg delete "HKCR\Drive\shellex\PropertySheetHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}" /f

:: 禁用文件夹的"包含到库中"右键菜单
reg delete "HKCR\Folder\shellex\ContextMenuHandlers\Library Location" /f

:: 禁用磁盘的"启用BitLocker"右键菜单
reg delete "HKCR\Drive\shell\encrypt-bde" /f
reg delete "HKCR\Drive\shell\encrypt-bde-elev" /f

:: 禁用路径长度限制
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v LongPathsEnabled /t REG_DWORD /d 1 /f

:: 开机自动打开小键盘
reg add "HKU\.DEFAULT\Control Panel\Keyboard" /v InitialKeyboardIndicators /t REG_SZ /d "2" /f
reg add "HKCU\Control Panel\Keyboard" /v InitialKeyboardIndicators /t REG_SZ /d "2" /f

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

:: 高性能电源方案
:: powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

:: 禁用休眠
:: powercfg /h off

:: 关闭防火墙
:: netsh advfirewall set allprofiles state off

:: 允许空密码远程登录
:: reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LimitBlankPasswordUse /t REG_DWORD /d 0 /f

:: 禁用无线电管理服务
:: sc config RmSvc start= disabled
:: sc stop RmSvc

:: 禁用蓝牙支持服务
:: sc config bthserv start= disabled
:: sc stop bthserv

:: 禁用蓝牙音视频控制协议
:: sc config BthAvctpSvc start= disabled
:: sc stop BthAvctpSvc
