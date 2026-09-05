<#
.SYNOPSIS
    Finds drivers in ConfigMgr that are not a member of any driver package.
.DESCRIPTION
    Health check variant that writes the report to an output folder rather than the console.
    Queries the SMS_Driver class and reports drivers with no package membership.
.EXAMPLE
    Get-CMUnusedDrivers.ps1 -SiteCode PS1 -SiteServer CM01
.LINK
    https://github.com/DeploymentResearch/DRFiles
.LINK
    https://www.linkedin.com/in/jarwidmark
.NOTES
    Author:  Johan Arwidmark and Kaido Jarvemets
    Credits: Developed by Johan Arwidmark and Kaido Jarvemets
    License: MIT. Provided as is, without warranty of any kind.
             Use at your own risk. Shared in the spirit of community learning.
    Version: 1.0.0

    Change history:
      1.0.0 - 2022-01-02 - Initial release
#>

$SiteServer = $env:COMPUTERNAME
$SiteCode = "PS1"
$OutputPath = "E:\Setup"

Try{
    $DriverAr = @()
    $Drivers = Get-WmiObject -Namespace "Root\SMS\Site_$($SiteCode)" -Class SMS_Driver -ErrorAction STOP -ComputerName $SiteServer
    foreach($Item in $Drivers){
        Try{
            $Query = Get-WmiObject -Namespace "Root\SMS\Site_$($SiteCode)" -Query "select * from SMS_Driver where CI_ID not in(select CI_ID from SMS_DriverContainer where CI_ID='$($item.CI_ID)') and CI_ID='$($item.CI_ID)'" -ErrorAction STOP -ComputerName $SiteServer
                if(($Query | Measure-Object | Select-Object -ExpandProperty Count) -ne 0){
                    $DObject = New-Object PSOBJECT
                        $DObject | Add-Member -MemberType NoteProperty -Name "CI_ID" -Value $Query.CI_ID
                        $DObject | Add-Member -MemberType NoteProperty -Name "LocalizedDisplayName" -Value $Query.LocalizedDisplayName
                        $DObject | Add-Member -MemberType NoteProperty -Name "ContentSourcePath" -Value $Query.ContentSourcePath
                    $DriverAr += $DObject
                }
        }
        Catch{
            $_.Exception.Message
        }
    
    }
    # Output to console
    # $DriverAr
    
    # Save to file
    $DriverAr | Format-Table -AutoSize | Out-String -Width 4096 | Out-File $OutputPath\Objects-UnusedDrivers.txt

}
Catch{
    $_.Exception.Message
}

