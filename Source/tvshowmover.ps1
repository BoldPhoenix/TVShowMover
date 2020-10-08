###########################################################################################################################################
# TV Show Mover App
# Application Name: tvshowmover.exe
# Authors: Carl Roach
# ===========================================================================
# TVShowMover is designed to scan a directory for tv shows in either mp4 or mkv format, then move them
# to their appropriate folder based on show name and season indicated in the ini file.
# 
# Version 0.0.0.1 - 03/26/2019 - Initial Creation.
# Version 2.0.0.5 - 06/10/2020 - See Readme file for update details.
###########################################################################################################################################

$filepath = "$PSScriptRoot\TVShowMover.ini"
$DownloadDirectory = "$PSScriptRoot"

function Get-IniContent($filePath)
{
    $ini = @{ }
    switch -regex -file $FilePath
    {
        "^\[(.+)\]" # Section
        {
            $section = $matches[1]
            $ini[$section] = @{ }
            $CommentCount = 0
        }
        "^(;.*)$" # Comment
        {
            $value = $matches[1]
            $CommentCount = $CommentCount + 1
            $name = "Comment" + $CommentCount
            $ini[$section][$name] = $value
        }
        "(.+?)\s*=(.*)" # Key
        {
            $name, $value = $matches[1 .. 2]
            $ini[$section][$name] = $value
        }
    }
    return $ini
}

#endregion Config File Parameters

$separator = "S[0-9][0-9]E[0-9][0-9]"
$listfilepaths = (get-childitem $DownloadDirectory -recurse | select | where { (($_.Name -like '*S[0-9][0-9]E[0-9][0-9]*') -and (($_.Name -like "*.mkv") -or ($_.Name -like "*.mp4") -and ($_.Name -notlike "*sample*.*"))) }).FullName
$iniContent = Get-IniContent -filepath $filepath
$ShowObjSummary = @()

foreach ($Show in $inicontent.keys)
{
    $StringContent = $iniContent[$Show].Keys | %{ $iniContent[$Show][$_] }
    $ShowName = $stringcontent.Split([Environment]::NewLine)[0]
    $ShowPath = $stringcontent.Split([Environment]::NewLine)[1]
    
    $ShowObj = New-Object PSObject
    $ShowObj | Add-Member -MemberType NoteProperty -Name Name -Value $ShowName
    $ShowObj | Add-Member -MemberType NoteProperty -Name Path -Value $ShowPath
    $ShowObjSummary += $ShowObj
}

foreach ($file in $listfilepaths)
{
    $rawfilename = split-path -path $file -leaf
    $ShowName = ($rawfilename -split $separator)[0]
    $torrent = $ShowName -replace '\.', ' '
    $filename = $torrent.trimend()
    $dropshowname = $rawfilename.trimstart($showname)
    $seasonepisode = ($rawfilename | select-string -pattern "S[0-9][0-9]E[0-9][0-9]").Matches.Value
    $season = $seasonepisode.Substring(0, 3)
    $Episode = $seasonepisode.Substring($seasonepisode.length - 3)
    if ($season -eq "S00") { $FullSeasonName = "Season 0" }
    elseif ($season -eq "S01") { $FullSeasonName = "Season 1" }
    elseif ($season -eq "S02") { $FullSeasonName = "Season 2" }
    elseif ($season -eq "S03") { $FullSeasonName = "Season 3" }
    elseif ($season -eq "S04") { $FullSeasonName = "Season 4" }
    elseif ($season -eq "S05") { $FullSeasonName = "Season 5" }
    elseif ($season -eq "S06") { $FullSeasonName = "Season 6" }
    elseif ($season -eq "S07") { $FullSeasonName = "Season 7" }
    elseif ($season -eq "S08") { $FullSeasonName = "Season 8" }
    elseif ($season -eq "S09") { $FullSeasonName = "Season 9" }
    elseif ($season -eq "S10") { $FullSeasonName = "Season 10" }
    elseif ($season -eq "S11") { $FullSeasonName = "Season 11" }
    elseif ($season -eq "S12") { $FullSeasonName = "Season 12" }
    elseif ($season -eq "S13") { $FullSeasonName = "Season 13" }
    elseif ($season -eq "S14") { $FullSeasonName = "Season 14" }
    elseif ($season -eq "S15") { $FullSeasonName = "Season 15" }
    elseif ($season -eq "S16") { $FullSeasonName = "Season 16" }
    elseif ($season -eq "S17") { $FullSeasonName = "Season 17" }
    elseif ($season -eq "S18") { $FullSeasonName = "Season 18" }
    elseif ($season -eq "S19") { $FullSeasonName = "Season 19" }
    elseif ($season -eq "S20") { $FullSeasonName = "Season 20" }
    elseif ($season -eq "S21") { $FullSeasonName = "Season 21" }
    elseif ($season -eq "S22") { $FullSeasonName = "Season 22" }
    elseif ($season -eq "S23") { $FullSeasonName = "Season 23" }
    elseif ($season -eq "S24") { $FullSeasonName = "Season 24" }
    elseif ($season -eq "S25") { $FullSeasonName = "Season 25" }
    elseif ($season -eq "S26") { $FullSeasonName = "Season 26" }
    elseif ($season -eq "S27") { $FullSeasonName = "Season 27" }
    elseif ($season -eq "S28") { $FullSeasonName = "Season 28" }
    elseif ($season -eq "S29") { $FullSeasonName = "Season 29" }
    elseif ($season -eq "S30") { $FullSeasonName = "Season 30" }
    $TVShowName = ($ShowObjSummary | select | where { $_.Name -eq $filename }).Name
    $INIShowPath = ($ShowObjSummary | select | where { $_.Name -eq $filename }).Path
    $TVShowPath = "$INIShowPath" + "$FullSeasonName"
    
    if (!(Test-Path $tvshowpath)) { New-Item $TVShowPath -Type Directory -force }
    
    if (($ShowObjSummary.name -contains $filename) -and ((Get-ChildItem $TVShowPath\*.mkv) -eq $null) -and ((Get-ChildItem $TVShowPath\*.mp4) -eq $null))
    {
        move-item -literalpath $file -Destination $TVShowPath -force
    }
    elseif (($ShowObjSummary.name -contains $filename) -and ((Get-ChildItem $TVShowPath | where { $_.name -like "*$showname*$episode*" }) -eq $null))
    {
        move-item -literalpath $file -Destination $TVShowPath -force
    }
}
