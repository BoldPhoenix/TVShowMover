###########################################################################################################################################
# TV Show Mover App
# Application Name: tvshowmover.exe
# Authors: Carl Roach
# ===========================================================================
# TVShowMover is designed to scan a directory for tv shows in any movie format, then move them
# to their appropriate folder based on show name and season indicated in the ini file.
# 
# Version 0.0.0.1 - 03/26/2019 - Initial Creation
# Version 3.0.0.6 - 03/02/2025 - See Readme file for update details.
###########################################################################################################################################

$DownloadDirectory = $PSScriptRoot
#$DownloadDirectory = "d:\downloads"
$filepath = "$DownloadDirectory\TVShowMover.ini"

#Create Logs folder if doesn't exist
[CmdletBinding()]
[OutputType([string[]])]

# Get curent date and time
$TimeStamp = (get-date -format u).Substring(0, 10)

# Construct transcript file full path
$TranscriptFile = "TVShowMover" + "-" + $TimeStamp + ".log"
$script:Transcript = Join-Path -Path $DownloadDirectory -ChildPath $TranscriptFile

# Create log and transcript files
if (!($transcript))
{
	New-Item -Path $Transcript -ItemType File -ErrorAction SilentlyContinue
	WriteLog "***********************"
}
else
{
	Function WriteLog
	{
		Param ([string]$LogString)
		$Stamp = (Get-Date).toString("yyyy-MM-dd HH:mm:ss")
		$LogMessage = "$Stamp $LogString"
		Add-content $Transcript -value $LogMessage
	}
	WriteLog "***********************"
}

# Function to parse INI file and return a dictionary of show names to paths
function Get-IniContent
{
	param (
		[string]$iniFile
	)
	
	$iniContent = @{ }
	
	# Read all lines of the INI file
	$lines = Get-Content -Path $iniFile
	$currentSection = ""
	
	foreach ($line in $lines)
	{
		$line = $line.Trim()
		
		# Skip empty lines and comments
		if ($line -match "^\s*$" -or $line -match "^#")
		{
			continue
		}
		
		# Detect section headers
		if ($line -match "^\[.*\]$")
		{
			$currentSection = $line.Trim('[', ']')
			continue
		}
		
		# Parse key-value pairs within the [Shows] section
		if ($currentSection -eq "Shows" -and $line -match "^(.*?)\s*=\s*(.*)$")
		{
			$showName = $matches[1].Trim()
			$path = $matches[2].Trim()
			$iniContent[$showName] = $path
		}
	}
	
	return $iniContent
}

# Function to analyze the filename and extract Show Name, Season, and Episode
function Parse-TVShowFileName
{
	param (
		[string]$fileName
	)
	
	# Regular expressions for different naming conventions
	$patterns = @(
		"^(?<showName>.+?)[.|\s|-]+[Ss](?<season>\d{1,2})[Ee](?<episode>\d{1,2})", # Show.Name.S01E01
        "^(?<showName>.+?)[_|\s|-]+[Ss](?<season>\d{1,2})[Ee](?<episode>\d{1,2})", # Show_Name_S01E01
		"^(?<showName>.+?)[.|\s|-]+(?<season>\d{1,2})[xX](?<episode>\d{1,2})", # Show-Name-1x01
		"^(?<showName>.+?)[.|\s|-]+\s?[Ss](?<season>\d{1,2})[Ee](?<episode>\d{1,2})" # Show Name - S01E01
	)
	
	foreach ($pattern in $patterns)
	{
		if ($fileName -match $pattern)
		{
			$showName = $matches['showName'] -replace '[.\s|_]', ' ' -replace '[.\s|-]', ' ' -replace '\s+', ' ' -replace '\s$', ''
			$season = "{0:D2}" -f [int]$matches['season']
			$episode = "{0:D2}" -f [int]$matches['episode']
			$season = $season -replace '^0+', ''
			return @{ ShowName = $showName; Season = $season; Episode = $episode }
		}
	}
	
	return $null
}

$separator = "S[0-9]*E[0-9]*"
$RegEx = '[^-\w\.]'
$folderlist = Get-ChildItem -Path $DownloadDirectory | Where-Object -FilterScript { $_.Name -match $RegEx }
foreach ($Folder in $folderlist)
{
	$ConvertedName = ($Folder.Name -replace '[\[+*?()\]]', '')
	$ConvertedName = ($ConvertedName -replace '\s', '.')
	$NewName = ((Split-Path -Path $Folder.FullName -Parent) + "\" + $ConvertedName)
	$Oldname = $folder.FullName
	rename-Item -literalpath $oldname $NewName -force
}

$filelist = Get-ChildItem -Path $DownloadDirectory -recurse | where { (($_.name -like "*.mp4") -or ($_.name -like "*.mkv") -or ($_.name -like "*.avi") -or ($_.name -like "*.mpg") -or ($_.name -like "*.mov") -or ($_.name -like "*.wmv")) }
foreach ($File in $filelist)
{
	$ConvertedName = ($File.Name -replace '[\[+*?()\]]', '')
	$ConvertedName = ($ConvertedName -replace '\s', '.')
	$NewName = ((Split-Path -Path $File.FullName -Parent) + "\" + $ConvertedName)
	$Oldname = $file.FullName
	rename-Item -literalpath $oldname $NewName -force
}

$showPaths = Get-IniContent $filepath

foreach ($file in $filelist)
{
	$parsed = Parse-TVShowFileName -fileName $file.Name
	$season = $parsed.season
	$showname = $parsed.showname
	$episode = $parsed.episode
	$TorrentFolder = split-path -path $file.FullName -parent
	if ($parsed -ne $null)
	{
		$showName = $parsed.ShowName
		$showPath = $showPaths[$showName]
		$fullseasonname = "Season " + $season
		if ($showPath -ne $null)
		{
			# Create the destination folder structure
			$seasonFolder = join-path $showpath $fullseasonname
			
			# Create directories if they don't exist
			if (-not (Test-Path $seasonFolder))
			{
				WriteLog "Creating New Season Folder: $seasonFolder"
				New-Item -Path $seasonFolder -ItemType Directory | Out-Null
			}
			
			# Set Destination Path
			$destinationPath = join-path $seasonFolder $file.Name
		}
		
		if ((get-childitem $seasonfolder | where { $_.name -like "*$showname*E$episode*" }) -eq $null)
		{
			WriteLog "Moving $file in to folder: $destinationPath"
			Move-Item -Path $file.FullName -Destination $destinationPath -Force
			
			if (!($TorrentFolder -eq $DownloadDirectory))
			{
				WriteLog "Removing download folder: $TorrentFolder"
				#Remove-Item -Path $TorrentFolder -recurse -Force
			}
		}
		else
		{
			WriteLog "$file already exists in $destinationPath no action necessary."
			if (!($TorrentFolder -eq $DownloadDirectory))
			{
				WriteLog "Removing download folder: $TorrentFolder"
				#Remove-Item -Path $TorrentFolder -recurse -Force
			}
			else
			{
				WriteLog "Removing downloaded file: $file"
				#Remove-Item -Path $file.FullName -Force
			}
		}
	}
}

$srtfilelist = Get-ChildItem -Path $DownloadDirectory -recurse | where { $_.name -like "*.srt" }
foreach ($srtfile in $srtfilelist)
{
	$parsed = Parse-TVShowFileName -fileName $srtfile.Name
	$season = $parsed.season
	$showname = $parsed.showname
	$episode = $parsed.episode
	$TorrentFolder = split-path -path $srtfile.FullName -parent
	if ($parsed -ne $null)
	{
		$showName = $parsed.ShowName
		$showPath = $showPaths[$showName]
		$fullseasonname = "Season " + $season
		if ($showPath -ne $null)
		{
			# Create the destination folder structure
			$seasonFolder = join-path $showpath $fullseasonname
			
			# Create directories if they don't exist
			if (-not (Test-Path $seasonFolder))
			{
				WriteLog "Creating New Season Folder: $seasonFolder"
				New-Item -Path $seasonFolder -ItemType Directory | Out-Null
			}
			
			# Set Destination Path
			$destinationPath = join-path $seasonFolder $srtfile.Name
		}
		
		WriteLog "Moving $srtfile in to folder: $destinationPath"
		Move-Item -Path $srtfile.FullName -Destination $destinationPath -Force
		
		if (!($TorrentFolder -eq $DownloadDirectory))
		{
			WriteLog "Removing download folder: $TorrentFolder"
			#Remove-Item -Path $TorrentFolder -recurse -Force
		}
	}
	else
	{
		WriteLog "$srtfile already exists in $destinationPath no action necessary."
		if (!($TorrentFolder -eq $DownloadDirectory))
		{
			WriteLog "Removing download folder: $TorrentFolder"
			#Remove-Item -Path $TorrentFolder -recurse -Force
		}
		else
		{
			WriteLog "Removing downloaded file: $srtfile"
			#Remove-Item -Path $file.FullName -Force
		}
	}
}

WriteLog "***********************"