$Version = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full').Release
If ($Version -in 528040, 528049, 528372, 528449){
    Write-Host "Microsoft .NET Framework 4.8 is installed" 
}