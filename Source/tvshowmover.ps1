###########################################################################################################################################
# TV Show Mover App
# Application Name: tvshowmover.exe
# Authors: Carl Roach
# ===========================================================================
# TVShowMover is designed to scan a directory for tv shows in any movie format, then move them
# to their appropriate folder based on show name and season indicated in the ini file.
# 
# Version 0.0.0.1 - 03/26/2019 - Initial Creation
# Version 3.0.0.2 - 09/27/2024 - See Readme file for update details.
###########################################################################################################################################

# Define the path of the folder to scan
$sourceFolder = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath('.\')

# Define the path to the provided INI file
$iniFile = "$sourcefolder\TVShowMover.ini"

# Define characters that are illegal in Windows file names
$arrInvalidChars = '[]/|\+-={}$%^&*()'.ToCharArray()

# Get all video files in the source folder
$fixfiles = Get-ChildItem -Path $sourceFolder -File -Recurse -Include *.mp4, *.mkv, *.avi, *.mov, *.mpg, *.srt

foreach ($fixfile in $fixfiles)
{
	# Remove illegal characters from the file name
	$cleanedfilename = $fixfile.name
	$arrInvalidChars | % { $cleanedfilename = $cleanedfilename.replace($_, '.') }
	cmd.exe /c ren $fixfile $cleanedFileName
}

# Get all video files in the source folder
$fixfolders = Get-ChildItem -Path $sourceFolder -Directory -Recurse

foreach ($fixfolder in $fixfolders)
{
	# Remove illegal characters from the file name
	$cleanedfoldername = $fixfolder.name
	$arrInvalidChars | % { $cleanedfoldername = $cleanedfoldername.replace($_, '.') }
	cmd.exe /c ren $fixfolder $cleanedFolderName
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
		"^(?<showName>.+?)[.|\s|-]+(?<season>\d{1,2})[xX](?<episode>\d{1,2})", # Show-Name-1x01
		"^(?<showName>.+?)[.|\s|-]+\s?[Ss](?<season>\d{1,2})[Ee](?<episode>\d{1,2})" # Show Name - S01E01
	)
	
	foreach ($pattern in $patterns)
	{
		if ($fileName -match $pattern)
		{
			$showName = $matches['showName'] -replace '[.\s|-]', ' ' -replace '\s+', ' ' -replace '\s$', ''
			$season = "{0:D2}" -f [int]$matches['season']
			$episode = "{0:D2}" -f [int]$matches['episode']
			$season = $season -replace '^0+', ''
			return @{ ShowName = $showName; Season = $season; Episode = $episode }
		}
	}
	
	return $null
}

function Sort-TVShows
{
	param (
		[string]$sourceFolder,
		[hashtable]$showPaths
	)
	
	# Get all video files in the source folder
	$files = Get-ChildItem -Path $sourceFolder -File -Recurse -Include *.mp4, *.mkv, *.srt
	
	foreach ($file in $files)
	{
		# Parse the file name
		$parsed = Parse-TVShowFileName -fileName $file.Name
		
		if ($parsed -ne $null)
		{
			$showName = $parsed.ShowName
			
			# Find the show path from the INI file
			$showPath = $showPaths[$showName]
			
			if ($showPath -ne $null)
			{
				# Create the destination folder structure
				$seasonFolder = Join-Path $showPath ("Season " + $parsed.Season)
				
				# Create directories if they don't exist
				if (-not (Test-Path $seasonFolder))
				{
					New-Item -Path $seasonFolder -ItemType Directory | Out-Null
				}
				
				# Move the file to the new destination
				$destinationPath = Join-Path $seasonFolder $file.Name
				Move-Item -Path $file.FullName -Destination $destinationPath -Force
				
				Write-Host "Moved: $($file.Name) -> $destinationPath"
			}
			else
			{
				Write-Warning "Show not found in INI file: $showName"
			}
		}
		else
		{
			Write-Warning "Could not parse file name: $($file.Name)"
		}
		$parentfolder = split-path $file -parent
		if (!(Get-ChildItem -Path $parentFolder) -and ($parentfolder -ne $sourceFolder))
		{
			# Delete the parent folder if it's empty
			Remove-Item -Path $parentFolder -Force -Confirm:$false
		}
	}
}

# Load INI file content
$showPaths = Get-IniContent -iniFile $iniFile

# Call the sorting function
Sort-TVShows -sourceFolder $sourceFolder -showPaths $showPaths
