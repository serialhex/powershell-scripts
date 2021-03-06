# solution to permissions problem proposed on:
# http://social.technet.microsoft.com/Forums/scriptcenter/en-US/87679d43-04d5-4894-b35b-f37a6f5558cb/solved-how-to-take-ownership-and-change-permissions-for-blocked-files-and-folders-in-powershell

#P/Invoke'd C# code to enable required privileges to take ownership and make changes when NTFS permissions are lacking
$AdjustTokenPrivileges = @"
using System;
using System.Runtime.InteropServices;

 public class TokenManipulator
 {
  [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
  internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall,
  ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr relen);
  [DllImport("kernel32.dll", ExactSpelling = true)]
  internal static extern IntPtr GetCurrentProcess();
  [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
  internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr
  phtok);
  [DllImport("advapi32.dll", SetLastError = true)]
  internal static extern bool LookupPrivilegeValue(string host, string name,
  ref long pluid);
  [StructLayout(LayoutKind.Sequential, Pack = 1)]
  internal struct TokPriv1Luid
  {
   public int Count;
   public long Luid;
   public int Attr;
  }
  internal const int SE_PRIVILEGE_DISABLED = 0x00000000;
  internal const int SE_PRIVILEGE_ENABLED = 0x00000002;
  internal const int TOKEN_QUERY = 0x00000008;
  internal const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;
  public static bool AddPrivilege(string privilege)
  {
   try
   {
    bool retVal;
    TokPriv1Luid tp;
    IntPtr hproc = GetCurrentProcess();
    IntPtr htok = IntPtr.Zero;
    retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);
    tp.Count = 1;
    tp.Luid = 0;
    tp.Attr = SE_PRIVILEGE_ENABLED;
    retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);
    retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
    return retVal;
   }
   catch (Exception ex)
   {
    throw ex;
   }
  }
  public static bool RemovePrivilege(string privilege)
  {
   try
   {
    bool retVal;
    TokPriv1Luid tp;
    IntPtr hproc = GetCurrentProcess();
    IntPtr htok = IntPtr.Zero;
    retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);
    tp.Count = 1;
    tp.Luid = 0;
    tp.Attr = SE_PRIVILEGE_DISABLED;
    retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);
    retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
    return retVal;
   }
   catch (Exception ex)
   {
    throw ex;
   }
  }
 }
"@
add-type $AdjustTokenPrivileges
#Activate necessary admin privileges to make changes without NTFS perms
[void][TokenManipulator]::AddPrivilege("SeRestorePrivilege") #Necessary to set Owner Permissions
[void][TokenManipulator]::AddPrivilege("SeBackupPrivilege") #Necessary to bypass Traverse Checking
[void][TokenManipulator]::AddPrivilege("SeTakeOwnershipPrivilege") #Necessary to override FilePermissions

#############################################
# Load up system assemblies
[void] [Reflection.Assembly]::LoadWithPartialName( "System.Windows.Forms" )
[void] [Reflection.Assembly]::LoadWithPartialName( "System.Drawing")

#############################################
# Get the root directory that we want
# permissions to change in
Write-Output "Select a Folder"
$d = New-Object Windows.Forms.FolderBrowserDialog
$d.ShowDialog( )
Write-Output "You have selected: " $d.SelectedPath
$directory = $d.SelectedPath | Get-Item

#############################################
# Get the form up and running
$Form = New-Object System.Windows.Forms.Form
$Form.ClientSize = New-Object System.Drawing.Size(300,275)

#############################################
# Get an array of users on our system
$userArray = @()
Get-WmiObject -Class Win32_UserAccount |
    ForEach-Object {
        $userArray = $userArray + $_
}

#############################################
# splop the users into our form...
$Label = New-Object System.Windows.Forms.Label
$Label.Location = New-Object System.Drawing.Point(15,10)
$Label.Text = "Choose your user..."
$Label.AutoSize = $True
$Form.Controls.Add($Label)
$x = 35
$userArray | ForEach-Object {
   $rb = New-Object System.Windows.Forms.RadioButton
   $rb.Location = New-Object System.Drawing.Point(15,$x)
   $rb.Text = $_.Caption
   $rb.Name = $_.Caption
   $rb.Size = New-Object System.Drawing.Size(200,24)
   $Form.Controls.Add($rb)
   $x = $x + 35
}
#$x = $x + 35

#############################################
# Get our OK button in place...
$usr = $false
$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Location = New-Object System.Drawing.Size(15,$x)
$OKButton.Size = New-Object System.Drawing.Size(75,23)
$OKButton.Text = "OK"
$OKButton.Add_Click({
    $Form.Controls |
      ForEach-Object {
        if ($_.Checked -eq $true) { $usr = $_.Name }
    }
    if ($usr) {
        $Form.Close()
    } else {
        [System.Windows.Forms.MessageBox]::Show("You must make a selection.")
    }
})
$Form.Controls.Add($OKButton)

$Form.ShowDialog()

Write-Output $usr

#############################################
# Just in case we don't select a user...
if ($usr) {
    Write-Host –NoNewLine  "Working.."
    #############################################
    # The overall Process...
    #
    # Create a new ACL object for the sole
    # purpose of defining a new owner, and apply
    # that update to the existing folder's ACL
    $NewOwnerACL = New-Object System.Security.AccessControl.DirectorySecurity
    # Establish the folder as owned by
    # BUILTIN\Administrators, guaranteeing the
    # following ACL changes can be applied
    $Admin = New-Object System.Security.Principal.NTAccount($usr)
    $NewOwnerACL.SetOwner($Admin)
    # Merge the proposed changes (new owner) into the folder's actual ACL
    $directory.SetAccessControl($NewOwnerACL)

    $i = 0
    Get-ChildItem $directory -recurse |
        ForEach-Object {
            # Working counter...
            $i = $i + 1
            if ($($i%500) -eq 0) {Write-Host –NoNewLine  "."}
            if ($_.PSIsContainer) {
                $NewOwnerACL = New-Object System.Security.AccessControl.DirectorySecurity
            } else {
                $NewOwnerACL = New-Object System.Security.AccessControl.FileSecurity
            }
            $Admin = New-Object System.Security.Principal.NTAccount($usr)
            $NewOwnerACL.SetOwner($Admin)
            $_.SetAccessControl($NewOwnerACL)
    }
}

Write-Host "  Done!"
[System.Windows.Forms.MessageBox]::Show("Done!!")
# yay