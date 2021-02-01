# BCMon.exe example to verify:
# 1: That a file from PSD is available in the local BranchCache cache
# 2: That the PSD server has generated the publication hash for the file
 
# File to work with 
$FilePath = "/Boot"
$FileName = "LiteTouchPE_x64.wim"

$TempDLPath = "C:\BCTempDL"
$TempCIPath = "C:\BCTempCI"
$BCMonPath = "C:\Setup\BCMon 1.3.8.1"
$DeployRoot = "https://mdt01.corp.viamonstra.com/mdtproduction"

$Username = 'MDT01\MDT_BA' 
$Password = 'P@ssw0rd'
$pass = ConvertTo-SecureString -AsPlainText $Password -Force
$Cred = New-Object System.Management.Automation.PSCredential -ArgumentList $Username,$pass

# Create work folders
New-Item -Path $TempDLPath -ItemType Directory -Force
New-Item -Path $TempCIPath -ItemType Directory -Force

# Create the URL
$url = "$DeployRoot$FilePath/$FileName"

# Verify CI from Publication Cache on BranchCache server, show result in command prompt window
Start-Process cmd.exe -ArgumentList "/k `"$BCMonPath\BCmon.exe`" /VerifyCI /URL:$URL /Username:$Username /Password:$Password"

# Download the file into the BranchCache cache (BITS download will put the file in the BranchCache cache)
Start-BitsTransfer -Source $URL -Destination C:\BCTemp -Credential $cred -Authentication Ntlm
Remove-Item "$TempDLPath\*" -Force

# Download CI, and query local BranchCache cache for content
$BCMonResult = cmd /c "`"$BCMonPath\BCmon.exe`" /DownloadCIFromSingleURL /URL:$URL /Folder:$TempCIPath /SaveAll /Username:$Username /Password:$Password /BCVersion:2.0"
$CIFileName = "$TempCIPath\$FileName.ci"
# Show result in command prompt window
Start-Process cmd.exe -ArgumentList "/k `"$BCMonPath\BCmon.exe`" /QueryCI $CIFileName"

