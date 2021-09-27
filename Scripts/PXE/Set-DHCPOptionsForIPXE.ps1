# Sample Script Snippets for configuring DHCP Scope Options for iPXE 2PXE, and iPXE Web Service

$ipxeserveripadr="192.168.1.214"

# Create vendor classes
Add-DhcpServerv4Class -Data PXEClient:Arch:00007 -Name "PXEClient (UEFI x64)" -Type Vendor -Description "PXEClient (UEFI x64)"
Add-DhcpServerv4Class -Data PXEClient:Arch:00006 -Name "PXEClient (UEFI x86)" -Type Vendor -Description "PXEClient (UEFI x86)"
Add-DhcpServerv4Class -Data PXEClient:Arch:00000 -Name "PXEClient (BIOS x86 and x64)" -Type Vendor -Description "PXEClient (BIOS x86 and x64)"

# Create Server wide policies
Add-DhcpServerv4Policy -Name "Right File Name for x64 UEFI" -Description "This sends the right file for non BIOS machines." -VendorClass EQ,"PXEClient (UEFI x64)*" -Condition Or
Add-DhcpServerv4Policy -Name "Right File Name for x86 UEFI" -Description "This sends the right file for non BIOS machines." -VendorClass EQ,"PXEClient (UEFI x86)*" -Condition Or
Add-DhcpServerv4Policy -Name "Right File Name for BIOS" -Description "This sends the right file for BIOS machines." -VendorClass EQ,"PXEClient (BIOS x86 and x64)*" -Condition Or

# Create server side scope options
Set-DhcpServerv4OptionValue -OptionId 66 -Value ($ipxeserveripadr) -PolicyName "Right File Name for x64 UEFI"
Set-DhcpServerv4OptionValue -OptionId 67 -Value "boot\x64\snponly_x64.efi" -PolicyName "Right File Name for x64 UEFI"

Set-DhcpServerv4OptionValue -OptionId 66 -Value ($ipxeserveripadr) -PolicyName "Right File Name for x86 UEFI"
Set-DhcpServerv4OptionValue -OptionId 67 -Value "boot\x86\snponly_x86.efi" -PolicyName "Right File Name for x86 UEFI"

Set-DhcpServerv4OptionValue -OptionId 66 -Value ($ipxeserveripadr) -PolicyName "Right File Name for BIOS"
Set-DhcpServerv4OptionValue -OptionId 67 -Value "boot\x86\undionly.kpxe" -PolicyName "Right File Name for BIOS"



# ==========================================
# Create configurations for individual scopes
# ==========================================

# Define DHCP Scope
$Scope = "192.168.2.0"

# Create and Single Scope Policies
Add-DhcpServerv4Policy -ScopeId $Scope -Name "Right File Name for x64 UEFI" -Description "This sends the right file for non BIOS machines." -VendorClass EQ,"PXEClient (UEFI x64)*" -Condition Or
Add-DhcpServerv4Policy -ScopeId $Scope -Name "Right File Name for x86 UEFI" -Description "This sends the right file for non BIOS machines." -VendorClass EQ,"PXEClient (UEFI x86)*" -Condition Or
Add-DhcpServerv4Policy -ScopeId $Scope -Name "Right File Name for BIOS" -Description "This sends the right file for BIOS machines." -VendorClass EQ,"PXEClient (BIOS x86 and x64)*" -Condition Or

# Set for Single Scope
Set-DhcpServerv4OptionValue -ScopeId $Scope -OptionId 66 -Value ($ipxeserveripadr) -PolicyName "Right File Name for x64 UEFI"
Set-DhcpServerv4OptionValue -ScopeId $Scope -OptionId 67 -Value "boot\x64\snponly_x64.efi" -PolicyName "Right File Name for x64 UEFI"

Set-DhcpServerv4OptionValue -ScopeId $Scope -OptionId 66 -Value ($ipxeserveripadr) -PolicyName "Right File Name for x86 UEFI"
Set-DhcpServerv4OptionValue -ScopeId $Scope -OptionId 67 -Value "boot\x86\snponly_x86.efi" -PolicyName "Right File Name for x86 UEFI"

Set-DhcpServerv4OptionValue -ScopeId $Scope -OptionId 66 -Value ($ipxeserveripadr) -PolicyName "Right File Name for BIOS"
Set-DhcpServerv4OptionValue -ScopeId $Scope -OptionId 67 -Value "boot\x86\undionly.kpxe" -PolicyName "Right File Name for BIOS"


# ==========================================
# CLEANUP
# ==========================================

# Remove server side scope options
Remove-DhcpServerv4OptionValue -OptionId 66 -PolicyName "Right File Name for x64 UEFI" 
Remove-DhcpServerv4OptionValue -OptionId 67 -PolicyName "Right File Name for x64 UEFI"

Remove-DhcpServerv4OptionValue -OptionId 66 -PolicyName "Right File Name for x86 UEFI"
Remove-DhcpServerv4OptionValue -OptionId 67 -PolicyName "Right File Name for x86 UEFI"

Remove-DhcpServerv4OptionValue -OptionId 66 -PolicyName "Right File Name for BIOS"
Remove-DhcpServerv4OptionValue -OptionId 67 -PolicyName "Right File Name for BIOS"

# Remove singe scope options
# Define DHCP Scope
$Scope = "192.168.2.0"

# Remove from Single Scope
Remove-DhcpServerv4OptionValue -ScopeId $Scope -OptionId 66 -PolicyName "Right File Name for x64 UEFI"
Remove-DhcpServerv4OptionValue -ScopeId $Scope -OptionId 67 -PolicyName "Right File Name for x64 UEFI"

Remove-DhcpServerv4OptionValue -ScopeId $Scope -OptionId 66 -PolicyName "Right File Name for x86 UEFI"
Remove-DhcpServerv4OptionValue -ScopeId $Scope -OptionId 67 -PolicyName "Right File Name for x86 UEFI"

Remove-DhcpServerv4OptionValue -ScopeId $Scope -OptionId 66 -PolicyName "Right File Name for BIOS"
Remove-DhcpServerv4OptionValue -ScopeId $Scope -OptionId 67 -PolicyName "Right File Name for BIOS"


