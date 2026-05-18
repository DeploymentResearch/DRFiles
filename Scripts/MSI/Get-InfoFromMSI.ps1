function GetMSIVersion{

    param (
        [parameter(Mandatory=$true)] 
        [ValidateNotNullOrEmpty()] 
            [System.IO.FileInfo] $MSIPath
    ) 
    if (!(Test-Path $MSIPath.FullName)) { 
        throw "File '{0}' does not exist" -f $MSIPath.FullName 
    } 
    try { 
        $WindowsInstaller = New-Object -ComObject WindowsInstaller.Installer 
        $Database = $WindowsInstaller.GetType().InvokeMember("OpenDatabase", "InvokeMethod", $Null, $WindowsInstaller, @($MSIPath.FullName, 0)) 
        $Query = "SELECT Value FROM Property WHERE Property = 'ProductVersion'"
        $View = $database.GetType().InvokeMember("OpenView", "InvokeMethod", $Null, $Database, ($Query)) 
        $View.GetType().InvokeMember("Execute", "InvokeMethod", $Null, $View, $Null) | Out-Null
        $Record = $View.GetType().InvokeMember( "Fetch", "InvokeMethod", $Null, $View, $Null ) 
        $Version = $Record.GetType().InvokeMember( "StringData", "GetProperty", $Null, $Record, 1 ) 
        return $Version
    } catch { 
        throw "Failed to get MSI file version: {0}." -f $_
    } 

}

function GetMSIProductCode{

    param (
        [parameter(Mandatory=$true)] 
        [ValidateNotNullOrEmpty()] 
            [System.IO.FileInfo] $MSIPath
    ) 
    if (!(Test-Path $MSIPath.FullName)) { 
        throw "File '{0}' does not exist" -f $MSIPath.FullName 
    } 
    try { 
        $WindowsInstaller = New-Object -ComObject WindowsInstaller.Installer 
        $Database = $WindowsInstaller.GetType().InvokeMember("OpenDatabase", "InvokeMethod", $Null, $WindowsInstaller, @($MSIPath.FullName, 0)) 
        $Query = "SELECT Value FROM Property WHERE Property = 'ProductCode'"
        $View = $database.GetType().InvokeMember("OpenView", "InvokeMethod", $Null, $Database, ($Query)) 
        $View.GetType().InvokeMember("Execute", "InvokeMethod", $Null, $View, $Null) | Out-Null
        $Record = $View.GetType().InvokeMember( "Fetch", "InvokeMethod", $Null, $View, $Null ) 
        $Version = $Record.GetType().InvokeMember( "StringData", "GetProperty", $Null, $Record, 1 ) 
        return $Version
    } catch { 
        throw "Failed to get MSI file product code: {0}." -f $_
    } 

}


GetMSIVersion -MSIPath "C:\Temp\Apps\GlobalProtect64.msi"
GetMSIProductCode -MSIPath "C:\Temp\Apps\sigplusbasic.msi"
