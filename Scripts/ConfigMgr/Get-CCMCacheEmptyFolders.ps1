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
