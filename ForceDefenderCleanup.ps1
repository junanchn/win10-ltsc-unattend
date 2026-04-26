param(
    [Parameter(Mandatory)][string]$HiveName
)

Add-Type -TypeDefinition @'
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

public class TokenPriv {
    [DllImport("advapi32.dll", SetLastError=true)]
    static extern bool AdjustTokenPrivileges(IntPtr h, bool d,
        ref TP n, int l, IntPtr p, IntPtr r);
    [DllImport("advapi32.dll", SetLastError=true)]
    static extern bool OpenProcessToken(IntPtr h, int a, ref IntPtr t);
    [DllImport("advapi32.dll", SetLastError=true)]
    static extern bool LookupPrivilegeValue(string s, string n, ref long l);

    [StructLayout(LayoutKind.Sequential, Pack=1)]
    struct TP { public int Count; public long Luid; public int Attr; }

    public static void Enable(string priv) {
        IntPtr tok = IntPtr.Zero;
        OpenProcessToken(Process.GetCurrentProcess().Handle, 0x28, ref tok);
        TP tp = new TP(); tp.Count = 1; tp.Attr = 2;
        LookupPrivilegeValue(null, priv, ref tp.Luid);
        AdjustTokenPrivileges(tok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
    }
}
'@

[TokenPriv]::Enable("SeTakeOwnershipPrivilege")
[TokenPriv]::Enable("SeRestorePrivilege")

$admin = [System.Security.Principal.NTAccount]"BUILTIN\Administrators"
$basePath = "$HiveName\Microsoft\Windows Defender"

function Unlock-Key([string]$Path) {
    try {
        $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey(
            $Path, 'ReadWriteSubTree', 'TakeOwnership')
        if (-not $key) { return }
        $acl = New-Object System.Security.AccessControl.RegistrySecurity
        $acl.SetOwner($admin)
        $key.SetAccessControl($acl)
        $key.Close()

        $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey(
            $Path, 'ReadWriteSubTree', 'ChangePermissions')
        $acl = $key.GetAccessControl()
        $acl.SetAccessRule((New-Object System.Security.AccessControl.RegistryAccessRule(
            $admin, 'FullControl', 'ContainerInherit,ObjectInherit', 'None', 'Allow')))
        $key.SetAccessControl($acl)
        $key.Close()

        $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey(
            $Path, 'ReadWriteSubTree', 'FullControl')
        foreach ($sub in $key.GetSubKeyNames()) {
            Unlock-Key "$Path\$sub"
        }
        $key.Close()
    } catch {
        Write-Warning "Unlock failed on ${Path}: $_"
    }
}

Unlock-Key $basePath

try {
    $parent = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey(
        "$HiveName\Microsoft", $true)
    if ($parent) {
        $parent.DeleteSubKeyTree('Windows Defender', $false)
        $parent.Close()
    }
} catch {
    Write-Warning "DeleteSubKeyTree failed: $_"
}

$features = [Microsoft.Win32.Registry]::LocalMachine.CreateSubKey(
    "$basePath\Features")
$features.SetValue('TamperProtection', 0, 'DWord')
$features.SetValue('TamperProtectionSource', 0, 'DWord')
$features.SetValue('MpPlatformKillbitsFromEngine', [byte[]]@(0,0,0,0,0,0,0,0), 'Binary')
$features.SetValue('MpCapability', [byte[]]@(0,0,0,0,0,0,0,0), 'Binary')
$features.Close()
