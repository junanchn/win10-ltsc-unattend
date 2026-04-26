# Windows 10 Enterprise LTSC 2021 无人值守部署工具

自动化构建精简、优化的 Windows 10 LTSC 2021 安装镜像。通过离线修改 WIM 镜像 + 首次登录脚本，实现从安装到可用的全程无人值守。

## 工作流程

```
Start.cmd
  ├── 解压 ISO 到 ISO\ 目录
  ├── 复制 unattend.xml → ISO\autounattend.xml
  └── 调用 W10UI.cmd（集成更新补丁）
        └── 挂载 WIM 后回调 OnWimMounted.cmd
              ├── 复制 OEM\ 目录和 unattend.xml 到镜像
              ├── OfflineRemoveDefender.cmd（移除 Defender）
              └── OfflineOptimize.cmd（离线注册表优化）

首次安装启动后（由 unattend.xml 触发）：
  ├── C:\OEM\optimize.cmd    ── 系统优化
  ├── C:\OEM\software.cmd    ── 安装软件
  └── C:\OEM\cleanup.cmd     ── 清理磁盘/日志/隐私痕迹
```

## 目录结构

```
win10-ltsc-unattend/
├── Start.cmd                    # 入口脚本：解压 ISO → 生成配置 → 启动集成
├── W10UI.cmd                    # W10UI v10.59 离线更新集成工具
├── OnWimMounted.cmd             # WIM 挂载回调：注入自定义文件和离线修改
│
├── OfflineOptimize.cmd          # 离线注册表优化（服务/策略/UI/隐私）
├── OfflineRemoveDefender.cmd    # 离线彻底移除 Windows Defender
├── OfflineDisableDefender.cmd   # 离线禁用 Defender（轻量替代方案）
│
├── ForceRegWrite.ps1            # 辅助：强制写入受 TrustedInstaller 保护的注册表键
├── ForceDefenderCleanup.ps1     # 辅助：清理 Defender 注册表并写入 Features 键
├── ExportDrivers.cmd            # 工具：导出当前系统驱动到 Drivers\OS\
│
├── unattend.xml                 # 无人值守应答文件（复制到镜像和 ISO 根目录）
├── OEM\                         # 将被复制到目标镜像 C:\OEM\ 的文件
│   ├── optimize.cmd             # 首次登录：电源/防火墙/视觉效果/计划任务
│   ├── software.cmd             # 首次登录：安装 7-Zip/Python/Edge 等
│   ├── cleanup.cmd              # 首次登录：磁盘清理/日志/隐私/注册表痕迹
│   └── MAS_AIO.cmd              # Microsoft Activation Scripts v3.10
│
└── Updates\                     # Windows 更新补丁（.url 下载链接）
    ├── 累积更新 KB5075912
    ├── .NET Framework 4.8.1
    └── .NET Framework 3.5/4.8 累积更新
```

## 各阶段详细说明

### 阶段一：离线镜像修改（构建时）

#### OfflineOptimize.cmd

挂载离线注册表 hive 进行修改，涉及四个 hive：

**SYSTEM hive** — 服务启动类型调整：
- 禁用：SysMain、IPv6 隧道、远程访问、遥测、错误报告、Windows Update、BITS、Windows Search、Edge 更新、Xbox 系列、微软商店、程序兼容性助手等
- 改为手动：UsoSvc、DPS、OneSyncSvc、CryptSvc、sppsvc
- 虚拟机专用：允许空密码远程登录、禁用无线电/蓝牙服务

**SOFTWARE hive** — 策略与配置：
- 关闭系统还原、安全警告、SmartScreen
- 设置 PowerShell 执行策略为 Bypass
- 禁用遥测、CEIP、A/B 实验
- 禁用自动更新策略
- Edge 浏览器全面优化（30+ 策略项）
- 隐藏此电脑中的七个文件夹
- 清理右键菜单（画图 3D、还原版本、包含到库中、BitLocker）

**Default user NTUSER.DAT** — 新用户默认配置：
- 关闭安全警告、反馈、Game Bar、游戏模式、自动播放
- 隐藏搜索框和任务视图按钮
- 显示文件扩展名、去除快捷方式后缀
- 开机自动打开小键盘

#### OfflineRemoveDefender.cmd

彻底移除 Defender 的所有组件：
- 删除服务注册（WinDefend、WdFilter、Sense 等 20+ 个）
- 删除 COM/WinRT 注册、计划任务、启动项
- 通过策略全面禁用实时保护、云保护、签名更新、网络保护
- 删除 Defender 程序文件和 SecHealthUI UWP 应用
- 禁用 SmartScreen、WTDS、VBS 等关联功能

### 阶段二：首次登录优化（安装后）

由 `unattend.xml` 中的 `FirstLogonCommands` 按顺序触发：

1. **optimize.cmd** — 关闭显示器超时、启用文件共享防火墙规则、关闭视觉效果、禁用/删除计划任务
2. **software.cmd** — 静默安装 7-Zip、Python 3.12、voidImageViewer、Edge；删除 Edge 自动更新
3. **cleanup.cmd** — 八阶段清理：停服务 → DISM/cleanmgr → 大目录 → 临时文件 → 日志 → 隐私文件 → 隐私注册表 → DNS/字体缓存

## 配置选项

### 虚拟机模式

`OnWimMounted.cmd` 中设置 `VM_MODE=1` 时额外执行：
- 离线：允许空密码远程登录、禁用无线电/蓝牙服务
- 首次登录：切换到高性能电源方案、关闭休眠、关闭防火墙、静默安装 VMware Tools

### unattend.xml 配置

- 分区方案：GPT（200MB EFI + 128MB MSR + 剩余空间系统分区）
- 语言/区域：zh-cn
- 计算机名：WIN10
- 账户：Administrator 空密码 + 自动登录
- OOBE：跳过所有向导页面
- 时区：China Standard Time

## 使用方法

1. 将 Windows 10 Enterprise LTSC 2021 ISO 放在脚本同目录，命名为 `Windows 10 Enterprise LTSC 2021.iso`
2. 将需要的更新补丁下载到 `Updates\` 目录
3. 将需要静默安装的软件安装包放入 `OEM\` 目录，并在 `software.cmd` 中添加安装命令
4. 按需修改 `OnWimMounted.cmd` 中的 `VM_MODE` 变量
5. 以管理员身份运行 `Start.cmd`
6. 等待完成后，在 `ISO\` 目录中得到修改后的安装文件

## 依赖

- Windows 10+ 主机（需要 DISM、reg.exe 等系统工具）
- 7-Zip（用于解压 ISO）
- 管理员权限
