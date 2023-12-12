$SiteServer = "cm01.corp.viamonstra.com"
$SiteCode = "PS1"
$DatabaseServer= "cm01.corp.viamonstra.com"
$Database = "CM_PS1"
$NewTaskSequenceName = "Pre-Cache Windows 11 22H2 XL1"
$SourceTaskSequenceName = "Windows 11 Enterprise x64 22H2 MDM BranchCache XL1"

# Connect to ConfigMgr
$Namespace = "root\SMS\Site_" + $SiteCode
Import-Module (Join-Path $(Split-Path $ENV:SMS_ADMIN_UI_PATH) ConfigurationManager.psd1) -Verbose:$false
Set-Location "$SiteCode`:"

If (Get-CMTaskSequence -Name $NewTaskSequenceName -Fast){
    Write-Warning "The `"$NewTaskSequenceName`" task sequence already exists, aborting..."
    Break
    #Get-CMTaskSequence -Name $NewTaskSequenceName -Fast | Remove-CMTaskSequence -Force
}

# Create a list of unique packages to add from existing task sequence
$CMPSSuppressFastNotUsedCheck = $true
$SourceTaskSequence = Get-CMTaskSequence -Name $SourceTaskSequenceName 
$TSPackages = $SourceTaskSequence.References | select Package -Unique
$TSPackageCount = $TSPackages.Count

Write-Host "The `"$SourceTaskSequenceName`" task sequence is referencing $TSPackageCount unique packages"

# SQL Query to select all available packages
$Query = @("
    Select DISTINCT vP.PackageID, vP.Name, vP.PackageType, vPSum.SourceSize from v_Package as vP
    LEFT JOIN v_PackageStatusRootSummarizer as vPSum
    ON vp.PackageID = vPSum.PackageID
")

# Run SQL Query to get all packages
$Datatable = New-Object System.Data.DataTable
$Connection = New-Object System.Data.SQLClient.SQLConnection
$Connection.ConnectionString = "server='$DatabaseServer';database='$Database';trusted_connection=true;"
$Connection.Open()
$Command = New-Object System.Data.SQLClient.SQLCommand
$Command.Connection = $Connection
$Command.CommandText = $Query
$Reader = $Command.ExecuteReader()
$Datatable.Load($Reader)
$Connection.Close()

# Generate packages list with additional info from SQL
$TSPackagesToAdd = @()
foreach ($TSPackage in $TSPackages){
    $TSPackageID = $TSPackage.Package

    # Lookup package details from dataset
    $TSPackageDetails = $Datatable | Where-Object { $_.PackageID -eq $TSPackageID }

    # Set variables
    $TSPackageName = $TSPackageDetails.Name
    $TSPackageSizeInKB = $TSPackageDetails.SourceSize
    $TSPackageType = $TSPackageDetails.PackageType
    
    # Add package details to array
    Write-Host "Adding Package $TSPackageID with Package name `"$TSPackageName`". Package size is $TSPackageSizeInKB kb, and Package type is $TSPackageType."
    $TSPackagesToAdd += [pscustomobject]@{ PackageID = $TSPackageID ; PackageName = $TSPackageName ; PackageSize = $TSPackageSizeInKB; PackageType = $TSPackageType } 
}

# Create a new Task Sequence
$TS = New-CMTaskSequence -CustomTaskSequence -Name $NewTaskSequenceName

# Create Root Group with a condition to never run
$GroupCondition = New-CMTaskSequenceStepConditionVariable -OperatorType Equals -ConditionVariableName "NeverTrue" -ConditionVariableValue "True"
$Group = New-CMTaskSequenceGroup -Name "Pre-Cache Package Content" -Condition $GroupCondition
Add-CMTaskSequenceStep -InsertStepStartIndex 0 -TaskSequenceName $TS.Name -Step $Group 

# Create a Download Package Content action per package
# Note: Packages smaller than 64 kb are skipped
foreach ($TSPackagesToAdd in $TSPackagesToAdd){
  
    $PackageID = $TSPackagesToAdd.PackageID
    $PackageName = $TSPackagesToAdd.PackageName
    $PackageSize = $TSPackagesToAdd.PackageSize
    $PackageType = $TSPackagesToAdd.PackageType

    If ($PackageSize -lt 64){
        Write-host "Package $TSPackageID with Package name `"$TSPackageName`" is smaller than 64 kb. Package size is $PackageSize kb, skipping..."
    }
    Else {
        # Make sure the Download Package Content action name is no longer than 50 characters
        $DCPActionName = $PackageName
        If ($DCPActionName.Length -gt 50){ 
            $DCPActionName = ($PackageName).Substring(0,50)
        }

        # Create CM Object based on PackageID (New-CMTSStepDownloadPackageContent expects a CM object)
        # Note: Purposely selecting only package types used in sequences in the Switch section, but here is the full list
        #
        # 0: Regular Software Distribution Package (Legacy Package)
	    # 3: Driver Package
	    # 4: Task Sequence Package
	    # 5: Software Update Package
	    # 6: Device Settings Package
	    # 7: Virtual Application Package
	    # 8: Application Package
	    # 257: OS Image Package
	    # 258: Boot Image Package
	    # 259: OS Upgrade Package

        Switch ($PackageType){

            "0" { 
                # Legacy Package
                $CMPackage = Get-CMPackage -Id $PackageID -Fast
                Write-Host "Adding Legacy Package $PackageID with Package name `"$PackageName`". Package Size is: $PackageSize"
            }

            "3" { 
                # Driver Package
                $CMPackage = Get-CMDriverPackage -Id $PackageID -Fast
                Write-Host "Adding Driver Package $PackageID with Package name `"$PackageName`". Package Size is: $PackageSize"
            }

            "5" { 
                # Software Update Package
                $CMPackage = Get-CMSoftwareUpdateDeploymentPackage -Id $PackageID -Fast
                Write-Host "Adding Software Update Package $PackageID with Package name `"$PackageName`". Package Size is: $PackageSize"
            }

            "8" { 
                # Application  Package
                $CMPackage = Get-CMApplication -Name $PackageName -Fast
                Write-Host "Adding Application  Package $PackageID with Package name `"$PackageName`". Package Size is: $PackageSize"
            }

            "257" { 
                # OS Image Package
                $CMPackage = Get-CMOperatingSystemImage -Id $PackageID
                Write-Host "Adding OS Image Package $PackageID with Package name `"$PackageName`". Package Size is: $PackageSize"
            }

            "258" { 
                # Boot Image Package
                $CMPackage = Get-CMBootImage -Id $PackageID
                Write-Host "Adding Boot Image Package $PackageID with Package name `"$PackageName`". Package Size is: $PackageSize"
            }

            "259" { 
                # OS Upgrade Package
                $CMPackage = Get-CMOperatingSystemUpgradePackage -Id $PackageID
                Write-Host "Adding OS  Package $PackageID with Package name `"$PackageName`". Package Size is: $PackageSize"
            }

            default { 
                # Unsupported package Type, or not defined, skipping
                Write-Warning "Unsupported package Type, or not defined, for package $PackageID with Package name `"$PackageName`"."
                Continue
            }
        }

        # Create each DownloadPackageContent action
        $PackageContent = New-CMTSStepDownloadPackageContent -Name $DCPActionName -AddPackage $CMPackage
        Set-CMTaskSequenceGroup -TaskSequenceName $TS.Name -AddStep $PackageContent -InsertStepStartIndex 0
    }
}



