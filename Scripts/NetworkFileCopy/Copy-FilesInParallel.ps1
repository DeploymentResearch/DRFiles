# Generate list of 10 lab machine names 
$LowNumber  = 1
$HighNumber = 10
$LabMachinePrefix = "ROGUE-" 

$Servers = $LowNumber..$HighNumber | ForEach-Object {
    "$LabMachinePrefix{0:D3}" -f $_
}

# Function for copy files and folders via jobs (fully leveraging the 10 GBE NIC on file server)
function Copy-ContentToServers {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string[]]$Servers,
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$DestinationRoot  # e.g. 'C$\ISO'
    )

    $isFolder = (Test-Path $Source -PathType Container)

    $jobs = foreach ($server in $Servers) {
        $dest = "\\$server\" + $DestinationRoot.TrimStart('\')

        Start-Job -Name $server -ScriptBlock {
            param($src, $dst, $srv, $isDir)
            try {
                if (-not (Test-Path -LiteralPath $dst)) {
                    New-Item -ItemType Directory -Path $dst -Force | Out-Null
                }

                if ($isDir) {
                    Copy-Item -LiteralPath $src -Destination $dst -Recurse -Force
                }
                else {
                    Copy-Item -LiteralPath $src -Destination $dst -Force
                }

                [pscustomobject]@{
                    Server = $srv
                    Status = 'Success'
                    Message = "Copied $src → $dst"
                }
            }
            catch {
                [pscustomobject]@{
                    Server = $srv
                    Status = 'Failed'
                    Message = $_.Exception.Message
                }
            }
        } -ArgumentList $Source, $dest, $server, $isFolder
    }

    $null = Wait-Job -Job $jobs
    $results = Receive-Job -Job $jobs
    Remove-Job -Job $jobs -Force
    $results
}

# Copy an ISO file to C:\ISO on all lab machines
Copy-ContentToServers -Servers $servers -Source 'E:\ISO\Labfiles.iso' -DestinationRoot 'C$\ISO'

# Copy a folder to C:\ on all lab machines
Copy-ContentToServers -Servers $servers -Source 'E:\ClassroomSetupW11' -DestinationRoot 'C$'