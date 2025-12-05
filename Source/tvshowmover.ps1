<#
.SYNOPSIS
    TV Show Mover - Auto-Enrichment & Deep Matching Edition (Fixed for #x## format)

.DESCRIPTION
    Scans a download directory for TV show video files, matches them against a user-defined INI file, 
    fetches episode metadata from the TVMaze API (Titles, Multi-Episode ranges), and moves them 
    to organized folders.

    Features:
    - Strict Anchoring: Prevents false positives (e.g. "Riverdale" matching inside other filenames).
    - Auto-Enrichment: Fetches episode titles for standard "SxxExx" files.
    - Deep Matching: Handles complex filenames lacking standard S/E numbering.
    - Dot Separators: Renames files using the "Show.SxxExx.Title.ext" format.
    - FIXED: Now supports #x## format (e.g., "4x05" in addition to "S04E05")

.NOTES
    Author:  Carl Roach
    Version: 3.5.0.5
    Updated: 2025-12-05
    Fixed by: BoldPhoenix, with enhancements for duplicate episode detection
#>

[CmdletBinding()]
Param (
    # The root directory to scan for video files. Defaults to script location.
    [Parameter(Mandatory = $false)]
    [string]$DownloadDirectory,

    # The configuration file mapping "Show Name" keys to "Destination Path" values.
    [Parameter(Mandatory = $false)]
    [string]$IniFileName = "TVShowMover.ini"
)

# =================================================================================================
# 1. SETUP & INITIALIZATION
# =================================================================================================

# Determine the working directory. If not provided, default to the script's own folder.
if ([string]::IsNullOrWhiteSpace($DownloadDirectory))
{
    if ($PSScriptRoot) { $DownloadDirectory = $PSScriptRoot }
    else { $DownloadDirectory = Get-Location } # Fallback for console execution
}

# Define paths for the Configuration and Log files
$IniPath = Join-Path -Path $DownloadDirectory -ChildPath $IniFileName
$LogFile = Join-Path -Path $DownloadDirectory -ChildPath ("TVShowMover-" + (Get-Date).ToString("yyyy-MM-dd") + ".log")

# FUNCTION: Write-Log
# Purpose:  Writes a timestamped message to the log file and outputs to the console.
function Write-Log
{
    Param ([string]$Message)
    $Line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $Message"
    Add-Content -Path $LogFile -Value $Line -ErrorAction SilentlyContinue
    Write-Host $Line
}

# Initialize Log File if it doesn't exist
if (-not (Test-Path $LogFile)) { New-Item -Path $LogFile -ItemType File -Force | Out-Null }


# =================================================================================================
# 2. HELPER FUNCTIONS
# =================================================================================================

# FUNCTION: Get-IniContent
# Purpose:  Parses the INI file into a case-insensitive Hashtable/Dictionary.
#           Keys = Show Names (as found in filenames)
#           Values = Destination Folder Paths
function Get-IniContent
{
    param ([string]$iniFile)
    $iniContent = [System.Collections.Generic.Dictionary[string, string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    
    if (Test-Path $iniFile)
    {
        foreach ($line in Get-Content -Path $iniFile)
        {
            # Regex matches "Key = Value" format
            if ($line -match "^(.*?)\s*=\s*(.*)$")
            {
                $k = $matches[1].Trim(); $v = $matches[2].Trim()
                
                # Ignore comments (#) or Section Headers ([Shows])
                if ($k -notmatch "^[\[#]" -and -not [string]::IsNullOrWhiteSpace($k))
                {
                    if (-not $iniContent.ContainsKey($k)) { $iniContent.Add($k, $v) }
                }
            }
        }
    }
    return $iniContent
}

# FUNCTION: Get-StrictRegex
# Purpose:  Creates a strict Regular Expression to match the Show Name.
#           1. Escapes special characters in the show name.
#           2. Replaces spaces with flexible separators (dots, underscores, hyphens).
#           3. ANCHORS the match to the start of the string (^) to prevent partial matches.
function Get-StrictRegex
{
    param ([string]$ShowName)
    
    $Safe = [regex]::Escape($ShowName) -replace "\\ ", "[._\-\s']+"
    return "(?i)^$Safe([._\-\s]|$)"
}

# FUNCTION: Test-FuzzyMatch
# Purpose:  Compares two strings to see if they share significant words.
#           Used when API titles differ slightly from filenames (e.g. punctuation differences).
function Test-FuzzyMatch
{
    param ([string]$A, [string]$B)
    
    # Remove non-alphanumeric characters and split into word arrays
    $WA = ($A -replace '[^a-zA-Z0-9]', ' ').ToLower() -split '\s+' | Where { $_.Length -gt 1 }
    $WB = ($B -replace '[^a-zA-Z0-9]', ' ').ToLower() -split '\s+' | Where { $_.Length -gt 1 }
    
    if ($WA.Count -eq 0 -or $WB.Count -eq 0) { return $false }
    
    # Check if any word in A exists in B
    foreach ($w in $WA) { if ($WB -contains $w) { return $true } }
    return $false
}

# FUNCTION: Get-TitleFromSE
# Purpose:  Simple API lookup. Given a Show Name, Season, and Episode, return the Official Title.
#           Used for standard "SxxExx" files.
function Get-TitleFromSE
{
    param ($SearchTerm, $Season, $Episode)
    
    Write-Log "    ...Enriching: Querying TVMaze for '$SearchTerm' (S${Season}E${Episode})..."
    try
    {
        $Uri = "http://api.tvmaze.com/search/shows?q=" + [uri]::EscapeDataString($SearchTerm)
        $Shows = Invoke-RestMethod -Uri $Uri -Method Get -ErrorAction Stop
        
        foreach ($Item in $Shows)
        {
            $Show = $Item.show
            # Fetch full episode list for this specific show ID
            $Eps = Invoke-RestMethod -Uri "http://api.tvmaze.com/shows/$($Show.id)/episodes" -Method Get -ErrorAction SilentlyContinue
            if ($Eps)
            {
                # Find exact match by Season/Number
                $Match = $Eps | Where-Object { $_.season -eq $Season -and $_.number -eq $Episode } | Select-Object -First 1
                if ($Match) { return $Match.name }
            }
        }
    }
    catch { Write-Log "    API Error: $($_.Exception.Message)" }
    return $null
}

# FUNCTION: Get-DeepMatch
# Purpose:  Complex API lookup for files without standard numbering or with multiple episodes.
#           Tries to match based on Episode Title fuzzy matching.
function Get-DeepMatch
{
    param ([string]$SearchTerm, [int]$EpHint, [string]$RawTitleString)
    
    Write-Log "    ...Deep Match: Querying TVMaze for '$SearchTerm'..."
    try
    {
        $Uri = "http://api.tvmaze.com/search/shows?q=" + [uri]::EscapeDataString($SearchTerm)
        $Shows = Invoke-RestMethod -Uri $Uri -Method Get -ErrorAction Stop
        
        # Extract the first title candidate from filename (e.g., "Title1" from "Title1.-.Title2")
        $Title1 = ($RawTitleString -split '[\.\-]')[0].Trim()
        
        foreach ($Item in $Shows)
        {
            $Show = $Item.show
            $Eps = Invoke-RestMethod -Uri "http://api.tvmaze.com/shows/$($Show.id)/episodes" -Method Get -ErrorAction SilentlyContinue
            
            if ($Eps)
            {
                # Try to find a candidate using the Episode Number Hint found in the filename (E##)
                if ($EpHint -gt 0)
                {
                    $Cand = $Eps | Where-Object { $_.number -eq $EpHint } | Select-Object -First 1
                    if ($Cand)
                    {
                        # VERIFICATION: Does the title vaguely match? 
                        # If yes, OR if title is too short to verify, we accept the match.
                        if ((Test-FuzzyMatch -A $Title1 -B $Cand.name) -or ($Title1.Length -lt 3))
                        {
                            $Result = @{ ShowName = $Show.name; Season = $Cand.season; EpStart = $Cand.number; EpEnd = $Cand.number; FullTitle = $Cand.name }
                            return $Result
                        }
                    }
                }
                
                # Fallback: Try matching against ALL episodes if we have a title string
                foreach ($Ep in $Eps)
                {
                    if (Test-FuzzyMatch -A $Title1 -B $Ep.name)
                    {
                        # Check if this could be a multi-episode file (e.g., Title1.-.Title2)
                        $NextEp = $Eps | Where-Object { $_.season -eq $Ep.season -and $_.number -eq ($Ep.number + 1) } | Select-Object -First 1
                        $EpEnd = $Ep.number
                        $FullTitle = $Ep.name
                        
                        if ($NextEp -and $RawTitleString -match "\.[-\.]\..*$")
                        {
                            $Title2 = ($RawTitleString -split '\.[-\.]\.')[1] -replace '\.[^.]+$', ''
                            if (Test-FuzzyMatch -A $Title2 -B $NextEp.name)
                            {
                                $EpEnd = $NextEp.number
                                $FullTitle = "$($Ep.name) & $($NextEp.name)"
                            }
                        }
                        
                        $Result = @{ ShowName = $Show.name; Season = $Ep.season; EpStart = $Ep.number; EpEnd = $EpEnd; FullTitle = $FullTitle }
                        return $Result
                    }
                }
            }
        }
    }
    catch { Write-Log "    API Error: $($_.Exception.Message)" }
    return $null
}


# =================================================================================================
# 3. MAIN EXECUTION LOOP
# =================================================================================================

Write-Log "Starting Scan in $DownloadDirectory"

# Load INI Configuration
$ShowPaths = Get-IniContent $IniPath
if (-not $ShowPaths) { Write-Log "CRITICAL: No INI entries found."; exit }

# Sort Keys by length (Descending) to ensure "NCIS New Orleans" matches before "NCIS"
$SortedKeys = $ShowPaths.Keys | Sort-Object { $_.Length } -Descending

# Get List of Video Files
$Files = @(Get-ChildItem -Path $DownloadDirectory -Recurse -File -Include "*.mp4", "*.mkv", "*.avi")

foreach ($File in $Files)
{
    $MatchedKey = $null
    
    # --- STEP 1: MATCHING ---
    # Check if the filename starts with a known Show Name from the INI
    foreach ($Key in $SortedKeys)
    {
        if ($File.Name -match (Get-StrictRegex -ShowName $Key)) { $MatchedKey = $Key; break }
    }
    
    if ($MatchedKey)
    {
        $Dest = $ShowPaths[$MatchedKey]
        $Processed = $false; $NewName = $null
        
        # --- STEP 2: PARSING & ENRICHMENT ---
        
        # SCENARIO A: Standard SxxExx or #x## Format
        # Updated to handle both "S04E05" and "4x05" formats
        if ($File.Name -match "(?:[Ss](?<season>\d{1,2})[Ee](?<episode>\d{1,2})|(?<season>\d{1,2})[xX](?<episode>\d{1,2}))")
        {
            $Season = [int]$matches['season']; $Episode = [int]$matches['episode']
            $S = "{0:D2}" -f $Season; $E = "{0:D2}" -f $Episode
            
            Write-Log "MATCH (Standard): '$($File.Name)' -> S${S}E${E}"
            
            # Attempt to get official title from API
            $EpTitle = Get-TitleFromSE -SearchTerm $MatchedKey -Season $Season -Episode $Episode
            if (-not $EpTitle)
            {
                # Fallback: Search using the Destination Folder Name (helpful if INI Key is generic like "Sabrina")
                $Folder = Split-Path -Path $Dest -Leaf
                if ($Folder -ne $MatchedKey) { $EpTitle = Get-TitleFromSE -SearchTerm $Folder -Season $Season -Episode $Episode }
            }
            
            if ($EpTitle)
            {
                # Format: Show.S01E01.Title.ext
                $NewName = "$MatchedKey.S${S}E${E}.$EpTitle$($File.Extension)"
                Write-Log "  > Found Title: '$EpTitle'"
            }
            else
            {
                # Format: Show.S01E01.ext (Basic Rename)
                $NewName = "$MatchedKey.S${S}E${E}$($File.Extension)"
                Write-Log "  > No Title found. Using basic rename."
            }
            
            $Processed = $true
        }
        # SCENARIO B: Deep Match (Complex/Multi-Episode Files)
        # Matches patterns like: Show.-.E01.Title1.-.Title2.mp4
        elseif ($File.Name -match "\.-\.E(?<ep>\d+)\.(?<rest>.+)\.(?<ext>mp4|mkv|avi)$")
        {
            $Ep = [int]$matches['ep']
            Write-Log "  Deep Match: '$($File.Name)' (Hint: Ep $Ep)"
            
            # Attempt Deep Match via API
            $ApiData = Get-DeepMatch -SearchTerm $MatchedKey -EpHint $Ep -RawTitleString $matches['rest']
            if (-not $ApiData)
            {
                $Folder = Split-Path -Path $Dest -Leaf
                if ($Folder -ne $MatchedKey) { $ApiData = Get-DeepMatch -SearchTerm $Folder -EpHint $Ep -RawTitleString $matches['rest'] }
            }
            
            if ($ApiData)
            {
                # Format Resulting String
                $S = "{0:D2}" -f $ApiData.Season; $E1 = "{0:D2}" -f $ApiData.EpStart
                $EpStr = "S${S}E${E1}"
                
                # Append multi-episode indicator if applicable (e.g. S01E01-E02)
                if ($ApiData.EpEnd -ne $ApiData.EpStart) { $EpStr += "-E$("{0:D2}" -f $ApiData.EpEnd)" }
                
                $NewName = "$MatchedKey.$EpStr.$($ApiData.FullTitle)$($File.Extension)"
                $Processed = $true
                Write-Log "  API SUCCESS: -> '$NewName'"
            }
            else { Write-Log "  API FAIL: No match for '$MatchedKey'" }
        }
        else { Write-Log "IGNORED: '$($File.Name)' (Format unrecognized)" }
        
        # --- STEP 3: FILE OPERATION (MOVE) ---
        
        if ($Processed -and $NewName)
        {
            # Sanitize Filename (Remove illegal Windows chars)
            $NewName = $NewName -replace '[<>:"/\\|?*]', ''
            
            if ($NewName -match "S(?<season>\d{2})")
            {
                # Ensure Destination Folder Exists
                # Remove leading zero from season number (Season 1, not Season 01)
                $SeasonNum = [int]$matches['season']
                $SeasDir = Join-Path $Dest ("Season " + $SeasonNum)
                if (-not (Test-Path $SeasDir)) { New-Item -Path $SeasDir -ItemType Directory -Force | Out-Null }
                
                $DestFile = Join-Path $SeasDir $NewName
                
                # Check for existing file with same episode (regardless of filename)
                $ExistingEpisode = $null
                if (Test-Path $SeasDir)
                {
                    # Extract episode info from new filename to check for duplicates
                    if ($NewName -match "S\d{2}E(\d{2})")
                    {
                        $EpNum = $matches[1]
                        # Look for any file in this season with the same episode number
                        $ExistingEpisode = Get-ChildItem -Path $SeasDir -File | Where-Object { $_.Name -match "S\d{2}E${EpNum}" } | Select-Object -First 1
                    }
                }
                
                if ($ExistingEpisode)
                {
                    # Episode already exists - delete the new file and log it
                    try
                    {
                        Remove-Item -Path $File.FullName -Force -ErrorAction Stop
                        Write-Log "  DUPLICATE REMOVED: Episode $EpNum already exists as '$($ExistingEpisode.Name)'"
                        
                        # Cleanup: Delete source folder if it is now empty (and not the root download dir)
                        $SourceDir = Split-Path -Path $File.FullName -Parent
                        if ($SourceDir -ne $DownloadDirectory)
                        {
                            $RemainingFiles = Get-ChildItem -Path $SourceDir -File -Recurse
                            if (-not $RemainingFiles)
                            {
                                Remove-Item -Path $SourceDir -Recurse -Force -ErrorAction SilentlyContinue
                                Write-Log "  CLEANUP: Deleted empty folder '$SourceDir'"
                            }
                        }
                    }
                    catch { Write-Log "  ERROR removing duplicate: $($_.Exception.Message)" }
                }
                elseif (-not (Test-Path $DestFile))
                {
                    # File doesn't exist - proceed with move
                    try
                    {
                        Move-Item -Path $File.FullName -Destination $DestFile -Force -ErrorAction Stop
                        Write-Log "  MOVED: $NewName"
                        
                        # Cleanup: Delete source folder if it is now empty (and not the root download dir)
                        $SourceDir = Split-Path -Path $File.FullName -Parent
                        if ($SourceDir -ne $DownloadDirectory)
                        {
                            $RemainingFiles = Get-ChildItem -Path $SourceDir -File -Recurse
                            if (-not $RemainingFiles)
                            {
                                Remove-Item -Path $SourceDir -Recurse -Force -ErrorAction SilentlyContinue
                                Write-Log "  CLEANUP: Deleted empty folder '$SourceDir'"
                            }
                        }
                    }
                    catch { Write-Log "  ERROR: Failed to move file. $($_.Exception.Message)" }
                }
                else { Write-Log "  SKIPPED: File already exists at destination." }
            }
        }
    }
    else { Write-Log "IGNORED: '$($File.Name)' (No matching show in INI)" }
}

Write-Log "Scan Complete."
