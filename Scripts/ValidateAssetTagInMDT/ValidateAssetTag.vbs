Function UserExit(sType, sWhen, sDetail, bSkip)
	UserExit = Success
End Function

Function ValidateAssetTag(sAssetTag)

	oLogging.CreateEntry "Check if AssetTag is set in bios", LogTypeInfo

	If sAssetTag = "" Then
		oLogging.CreateEntry "AssetTag not found, setting AssetTag to NO_BIOS_ASSET.", LogTypeInfo
		ValidateAssetTag = "NO_BIOS_ASSET"
	Else
		ValidateAssetTag = AssetTag
		oLogging.CreateEntry "AssetTag found, selecting AssetTag: " & AssetTag, LogTypeInfo
	End If


End Function