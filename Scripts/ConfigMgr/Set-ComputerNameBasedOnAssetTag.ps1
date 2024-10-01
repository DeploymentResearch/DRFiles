# Set ComputerName based on AssetTag
$tsenv = New-Object -ComObject Microsoft.SMS.TSEnvironment
$prefix = "ABC"
$AssetTag = $tsenv.Value("AssetTag")

If ($AssetTag){
    $tsenv.Value("OSDComputerName") = ($prefix + $AssetTag).Substring(0,15)
}

