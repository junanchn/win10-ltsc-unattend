param(
    [Parameter(Mandatory)][string]$Key,
    [Parameter(Mandatory)][string]$Name,
    [Parameter(Mandatory)][ValidateSet('DWORD','QWORD','String')][string]$Type,
    [Parameter(Mandatory)]$Value
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
$origSddl = $null

try {
    # Save original security descriptor (owner + DACL)
    $rk = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey(
        $Key, 'ReadSubTree', 'ReadPermissions')
    if (-not $rk) { exit 1 }
    $origSddl = $rk.GetAccessControl().GetSecurityDescriptorSddlForm('Owner,Access')
    $rk.Close()

    # Take ownership
    $rk = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey(
        $Key, 'ReadWriteSubTree', 'TakeOwnership')
    $acl = New-Object System.Security.AccessControl.RegistrySecurity
    $acl.SetOwner($admin)
    $rk.SetAccessControl($acl)
    $rk.Close()

    # Grant full control (needed for value write + later ACL restore)
    $rk = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey(
        $Key, 'ReadWriteSubTree', 'ChangePermissions')
    $acl = $rk.GetAccessControl()
    $acl.SetAccessRule((New-Object System.Security.AccessControl.RegistryAccessRule(
        $admin, 'FullControl', 'ContainerInherit,ObjectInherit', 'None', 'Allow')))
    $rk.SetAccessControl($acl)
    $rk.Close()

    # Write the value
    $rk = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($Key, $true)
    $kind = switch ($Type) {
        'DWORD'  { [Microsoft.Win32.RegistryValueKind]::DWord }
        'QWORD'  { [Microsoft.Win32.RegistryValueKind]::QWord }
        'String' { [Microsoft.Win32.RegistryValueKind]::String }
    }
    $val = switch ($Type) {
        'DWORD'  { [int]$Value }
        'QWORD'  { [long]$Value }
        'String' { [string]$Value }
    }
    $rk.SetValue($Name, $val, $kind)
    $rk.Close()

} finally {
    # Restore original security descriptor (owner + DACL) if saved
    if ($origSddl) {
        try {
            $rk = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey(
                $Key, 'ReadWriteSubTree',
                [System.Security.AccessControl.RegistryRights]'TakeOwnership,ChangePermissions')
            $restAcl = New-Object System.Security.AccessControl.RegistrySecurity
            $restAcl.SetSecurityDescriptorSddlForm($origSddl, 'Owner,Access')
            $rk.SetAccessControl($restAcl)
            $rk.Close()
        } catch {}
    }
}
