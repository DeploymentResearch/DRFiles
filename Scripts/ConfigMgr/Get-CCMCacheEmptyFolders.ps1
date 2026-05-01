$CachePath = "C:\Windows\CCMCache"

Get-ChildItem -Path $CachePath -Directory -Force | Where-Object {
    -not (Get-ChildItem -Path $_.FullName -Force -Recurse -File -ErrorAction SilentlyContinue)
} | Select-Object FullName, LastWriteTime