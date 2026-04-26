@echo off
:: Runs after W10UI mounts WIM.

:: Set to 1 for virtual machine images
set "VM_MODE=1"

set "mountdir=%~1"
if "%mountdir%"=="" exit /b

:: Skip boot.wim (has WinPE language packs)
if exist "%mountdir%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" exit /b

echo.
echo ============================================================
echo Copying custom files into image...
echo ============================================================
echo.

xcopy "%~dp0OEM\*" "%mountdir%\OEM\" /E /Y /I
xcopy "%~dp0unattend.xml" "%mountdir%\Windows\Panther\" /Y

:: call "%~dp0OfflineDisableDefender.cmd" "%mountdir%"
call "%~dp0OfflineRemoveDefender.cmd" "%mountdir%"
call "%~dp0OfflineOptimize.cmd" "%mountdir%"

:: ---- 虚拟机专用：注入首次登录阶段命令 ----
if "%VM_MODE%"=="1" (
    (
        echo.
        REM 高性能电源方案
        echo powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
        REM 关闭显示器超时设为“从不”
        echo powercfg /change monitor-timeout-ac 0
        echo powercfg /change monitor-timeout-dc 0
        REM 关闭休眠
        echo powercfg /h off
        REM 启用文件和打印机共享防火墙规则
        netsh advfirewall firewall set rule group="文件和打印机共享" new enable=yes
        REM 关闭防火墙
        echo netsh advfirewall set allprofiles state off
    )>> "%mountdir%\OEM\optimize.cmd"
    (
        echo.
        REM VMware Tools
        echo VMwareTools\setup.exe /S /v "/qn REBOOT=R"
    )>> "%mountdir%\OEM\software.cmd"
)
