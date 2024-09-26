###########################################################################################################################################
# TV Show Mover App
# Application Name: tvshowmover.exe
# Authors: Carl Roach
# ===========================================================================
# TVShowMover is designed to scan a directory for tv shows in any movie format, then move them
# to their appropriate folder based on show name and season indicated in the ini file.
# 
# Version 0.0.0.1 - 03/26/2019 - Initial Creation.
# Version 2.0.0.5 - 06/10/2020 - See Readme file for update details.
# Version 2.0.0.6 - 10/14/2020 - See Readme file for update details.
# Version 2.0.0.7 - 10/22/2020 - See Readme file for update details.
# Version 2.0.0.8 - 10/28/2020 - See Readme file for update details.
# Version 2.0.0.9 - 02/17/2021 - See Readme file for update details.
# Version 2.0.1.0 - 05/17/2024 - See Readme file for update details.
# Version 2.0.1.1 - 05/17/2024 - See Readme file for update details.
# Version 3.0.0.0 - 09/22/2024 - See Readme file for update details.
# Version 3.0.0.1 - 09/24/2024 - See Readme file for update details.
###########################################################################################################################################

# Define the path of the folder to scan
$sourceFolder = "$PSScriptRoot"

# Define the path to the provided INI file
$iniFile = "$PSScriptRoot\TVShowMover.ini"


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

# Function to match show name from INI and sort the files
function Sort-TVShows
{
	param (
		[string]$sourceFolder,
		[hashtable]$showPaths
	)
	
	# Get all video files in the source folder
	$files = Get-ChildItem -Path $sourceFolder -File -Recurse -Include *.mp4, *.mkv, *.avi, *.mov, *.mpg, *.wmv, *.srt
	
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
			Remove-Item -Path $parentFolder -Force
		}
	}
}

# Load INI file content
$showPaths = Get-IniContent -iniFile $iniFile

# Call the sorting function
Sort-TVShows -sourceFolder $sourceFolder -showPaths $showPaths
