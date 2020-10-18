$ExportPath = ".\slackHistory"
$ExportContents = Get-ChildItem -path $ExportPath -Recurse
Function Get-TimeStamp {
    return "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)
}

class File {
    [string] $Name
    [string] $Title
    [string] $Channel
    [string] $DownloadURL
    [string] $MimeType
    [double] $Size
    [string] $ParentPath
    [string] $Time
	[string] $DownloadedFilePath
}

$channelList = Get-Content -Raw -Path .\slackHistory\channels.json | ConvertFrom-Json
$Files = New-Object -TypeName System.Collections.ObjectModel.Collection["File"]

Write-Host -ForegroundColor Green "$(Get-TimeStamp) Starting Step 1 (processing channel export for files) of 2. Total Channel Count: $($channelList.Count)"
#Iterate through each Channel listed in the Archive
foreach ($channel in $channelList) {
    #Iterate through Channel folders from the Export
    foreach ($folder in $ExportContents)
    {
        #If Channel Name matches..
        if ($channel.name -eq $folder){
            $channelJsons = Get-ChildItem -Path $folder.FullName -File
            Write-Host -ForegroundColor White "$(Get-TimeStamp) Info: Starting to process $($channelJsons.Count) days of content for #$($channel.name)."
            #Start processing the daily JSON for files
            foreach ($json in $channelJsons){
				$currentRawFileContent = Get-Content -Raw -Path $json.FullName
                $currentJson = ConvertFrom-Json $currentRawFileContent
                Write-Host -ForegroundColor Yellow "$(Get-TimeStamp) Info: Processing $($json.Name) in #$($channel.name).."
                #Iterate through every action
                foreach ($entry in $currentJson){
                    #If the action contained file(s)..
                    if($null -ne $entry.files){
                        #Iterate through each file and add it to the List of Files to download
                        foreach ($item in $entry.Files) {
							#Download File (if possible, e.g. we preserve direct link to Google Drive files)
                            if ($null -ne $item.url_private_download){
								$file = New-Object -TypeName File
								
                                $file.Name = $item.name
                                $file.Title = $item.Title
                                $file.Channel = $channel.name
                                $file.DownloadURL = $item.url_private_download
                                $file.MimeType = $item.mimetype
                                $file.Size = $item.size
                                $file.ParentPath = $folder.FullName
                                $file.Time = $item.created
								
								#Force all file names to use Time suffix so all names are determinable and unique
								try
								{
									$extensionPosition = $file.Name.LastIndexOf('.')
									$splitFileName = $file.Name.Substring(0,$extensionPosition)
									$splitFileExtention = $file.Name.Substring($extensionPosition)
									$file.DownloadedFilePath = $splitFileName + "_" + $file.Time + $splitFileExtention
									
									$files.Add($file)
									
									#Update URL in JSON for later use with slack2html
									$currentRawFileContent = $currentRawFileContent.Replace($item.url_private.Replace("/", "\/"), "Files/" + $file.DownloadedFilePath)
									$currentRawFileContent = $currentRawFileContent.Replace($item.url_private_download.Replace("/", "\/"), "Files/" + $file.DownloadedFilePath)
								}
								catch [System.Exception]{
									Write-Host -ForegroundColor Blue "$(Get-TimeStamp) Warning: we will ignore file $($file.Name) of type $($file.MimeType)"
								}
                            }
							#Download Thumbnail 360 (if any)
							if ($null -ne $item.thumb_360){
								$file_thumb360 = New-Object -TypeName File
								
								$file_thumb360.Name = $item.name
								$file_thumb360.Title = $item.Title
								$file_thumb360.Channel = $channel.name
								$file_thumb360.DownloadURL = $item.thumb_360
								$file_thumb360.MimeType = $item.mimetype
								$file_thumb360.Size = $item.size
								$file_thumb360.ParentPath = $folder.FullName
								$file_thumb360.Time = $item.created
								
								#Force all file names to use Time suffix so all names are determinable and unique
								if ($null -ne $item.url_private_download){
									$extensionPosition = $file_thumb360.Name.LastIndexOf('.')
									$splitFileName = $file_thumb360.Name.Substring(0,$extensionPosition)
									$splitFileExtention = $file_thumb360.Name.Substring($extensionPosition)
									$file_thumb360.DownloadedFilePath = $splitFileName + "_" + $file_thumb360.Time + "_thumb360" + $splitFileExtention
								} else {
									$file_thumb360.DownloadedFilePath = $file_thumb360.Name + "_" + $file_thumb360.Time + "_thumb360" + ".png"
								}
								
								$files.Add($file_thumb360)
								
								#Update URL in JSON for later use with slack2html
								$currentRawFileContent = $currentRawFileContent.Replace($item.thumb_360.Replace("/", "\/").Replace('"', '_'), "Files/" + $file_thumb360.DownloadedFilePath)
							}
                        }
                    }
                }
				#Save updated JSON file with new local URLs for soon-to-be-downloaded files
				$updatedJsonFileName = $json.FullName #For Debugging purposes: + ".txt"
				Set-Content -Path $updatedJsonFileName $currentRawFileContent
            }
        }
    }
}
Write-Host -ForegroundColor Green "$(Get-TimeStamp) Step 1 of 2 complete. `n"



Write-Host -ForegroundColor Green "$(Get-TimeStamp) Starting step 2 (creating folders and downloading files) of 2."
#Determine which Files folders need to be created
$FoldersToMake = New-Object System.Collections.ObjectModel.Collection["string"]
foreach ($file in $files){
    if ($FoldersToMake -notcontains $file.Channel){
        $FoldersToMake.Add($file.Channel)
    }
}

#Create Folders
foreach ($folder in $FoldersToMake){
    #$fullFolderPath = $file.ParentPath + "\Files"
    $fullFolderPath = $ExportPath +"\$($folder)"
    $fullFilesPath = $ExportPath +"\$($folder)\Files"
    if (-not (Test-Path $fullFilesPath)){
        New-Item -Path $fullFolderPath  -Name "Files" -ItemType "directory"
    }
}

#Downloading Files
foreach ($file in $files)
{
    Write-Host -ForegroundColor Yellow "$(Get-TimeStamp) Downloading $($file.Name)."
    $fullFilePath = $file.ParentPath + "\Files\" + $file.DownloadedFilePath
	# Do not download existing file (speed up script re-runs)
	if (-not (Test-Path $fullFilePath)){
		try{
			$request = (New-Object System.Net.WebClient).DownloadFile($file.DownloadURL, $fullFilePath)
		}
		catch [System.Net.WebException]{
			Write-Host -ForegroundColor Red "$(Get-TimeStamp) Error: Unable to download $($file.Name) to $($fullFilePath)"
		}   
	}
}
Write-Host -ForegroundColor Green "$(Get-TimeStamp) Step 2 of 2 complete. `n"
Write-Host -ForegroundColor Green "$(Get-TimeStamp) Exiting.."
