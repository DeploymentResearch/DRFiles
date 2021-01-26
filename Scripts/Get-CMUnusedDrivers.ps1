<#
.Synopsis
   This script queries Configuration Manager 2012 Drivers that are not related with any Driver Packages
.DESCRIPTION
.EXAMPLE
    Get-CMUnusedDrivers.ps1 -SiteCode PS1 -SiteServer CM01
.NOTES
    Developed By Johan Arwidmark and Kaido Järvemets
    Version 1.0
#>
[CMDLETBINDING()]
Param(
    [Parameter(Mandatory=$True,HelpMessage="Please Enter CM Site Server")]
        $SiteServer,
    [Parameter(Mandatory=$True,HelpMessage="Please Enter CM Site Code")]
        $SiteCode
    )

Try{
    $DriverAr = @()
    $Drivers = Get-WmiObject -Namespace "RootSMSSite_$($SiteCode)" -Class SMS_Driver -ErrorAction STOP -ComputerName $SiteServer
    foreach($Item in $Drivers){
        Try{
            $Query = Get-WmiObject -Namespace "RootSMSSite_$($SiteCode)" -Query "select * from SMS_Driver where CI_ID not in(select CI_ID from SMS_DriverContainer where CI_ID='$($item.CI_ID)') and CI_ID='$($item.CI_ID)'" -ErrorAction STOP -ComputerName $SiteServer
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
    $DriverAr
}
Catch{
    $_.Exception.Message
}