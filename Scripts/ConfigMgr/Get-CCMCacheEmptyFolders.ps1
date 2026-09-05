<#
.SYNOPSIS
    Finds empty folders left behind in the ConfigMgr client cache.
.DESCRIPTION
    Enumerates the cache folder and reports subfolders that contain no files, which usually
    indicates interrupted downloads.
.LINK
    https://github.com/DeploymentResearch/DRFiles
.LINK
    https://www.linkedin.com/in/jarwidmark
.NOTES
    Author:  Johan Arwidmark / deploymentresearch.com
    License: MIT. Provided as is, without warranty of any kind.
             Use at your own risk. Shared in the spirit of community learning.
    Version: 1.0.0

    Change history:
      1.0.0 - 2026-05-01 - Initial release
#>

$CachePath = "C:\Windows\CCMCache"

$EmptyFolders = Get-ChildItem -Path $CachePath -Directory -Force | Where-Object {
    -not (Get-ChildItem -Path $_.FullName -Force -Recurse -File -ErrorAction SilentlyContinue)
} | Select-Object FullName, LastWriteTime

If ($EmptyFolders) {
    Write-Host "Empty folder count is: $(($EmptyFolders | Measure-Object).Count)"
}
Else {
    Write-Host "Empty folder count is: $(($EmptyFolders | Measure-Object).Count)"
}
