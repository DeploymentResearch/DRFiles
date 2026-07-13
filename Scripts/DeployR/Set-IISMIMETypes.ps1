# Set the MIME types for the iPXE boot files, fonts etc.

# wimboot.bin file 
# Note: BIN files are already added by default
#add-webconfigurationproperty //staticContent -name collection -value @{fileExtension='.bin';mimeType='application/octet-stream'} 

# EFI loader files 
add-webconfigurationproperty //staticContent -name collection -value @{fileExtension='.efi';mimeType='application/octet-stream'} 

# BIOS boot loaders 
add-webconfigurationproperty //staticContent -name collection -value @{fileExtension='.com';mimeType='application/octet-stream'} 

# BIOS loaders without F12 key press 
add-webconfigurationproperty //staticContent -name collection -value @{fileExtension='.n12';mimeType='application/octet-stream'} 

# For the boot.sdi file 
add-webconfigurationproperty //staticContent -name collection -value @{fileExtension='.sdi';mimeType='application/octet-stream'} 

# For the boot.bcd boot configuration files 
add-webconfigurationproperty //staticContent -name collection -value @{fileExtension='.bcd';mimeType='application/octet-stream'} 

# For boot files with no extension
add-webconfigurationproperty //staticContent -name collection -value @{fileExtension='.';mimeType='application/octet-stream'} 

# For the winpe images itself 
# Note: WIM files are already added by default (on updated servers)
#add-webconfigurationproperty //staticContent -name collection -value @{fileExtension='.wim';mimeType='application/octet-stream'} 

# For the iPXE BIOS loader files 
add-webconfigurationproperty //staticContent -name collection -value @{fileExtension='.pxe';mimeType='application/octet-stream'} 

# For the UNDIonly version of iPXE 
add-webconfigurationproperty //staticContent -name collection -value @{fileExtension='.kpxe';mimeType='application/octet-stream'} 

# For the boot fonts 
# Note: TTF files are already added by default
#add-webconfigurationproperty //staticContent -name collection -value @{fileExtension='.ttf';mimeType='application/octet-stream'}