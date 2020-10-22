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
# Version 2.0.0.6 - 10/14/2020 - See Readme file for update details.
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

$separator = "S[0-9]*E[0-9]*"
$RegEx = '[^-\w\.]'
$folderlist = Get-ChildItem -Path $DownloadDirectory | Where-Object -FilterScript { $_.Name -match $RegEx }
foreach ($Folder in $folderlist)
{
    $ConvertedName = ($Folder.Name -replace '[\[+*?()\]]', '')
    $NewName = ((Split-Path -Path $Folder.FullName -Parent) + "\" + $ConvertedName)
    $Oldname = $folder.FullName
    rename-Item -literalpath $oldname $NewName -force
}

$filelist = Get-ChildItem -Path $DownloadDirectory -recurse | Where-Object -FilterScript { $_.Name -match $RegEx }
foreach ($File in $filelist)
{
    $ConvertedName = ($File.Name -replace '[\[+*?()\]]', '')
    $NewName = ((Split-Path -Path $File.FullName -Parent) + "\" + $ConvertedName)
    $Oldname = $file.FullName
    rename-Item -literalpath $oldname $NewName -force
}
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

$listfilepaths = (get-childitem $DownloadDirectory -recurse | select | where { ((($_.Name -like '*S[0-9][0-9]E[0-9][0-9]*') -or ($_.Name -like '*S[0-9][0-9][0-9]E[0-9][0-9]*')) -and (($_.Name -like "*.mkv") -or ($_.Name -like "*.mp4") -and ($_.Name -notlike "*sample*.*"))) }).FullName
foreach ($file in $listfilepaths)
{
    $rawfilename = split-path -path $file -leaf
    $TorrentFolder = split-path -path $file -parent
    $ShowName = ($rawfilename -split $separator)[0]
    $torrent = $ShowName -replace '\.', ' '
    $filename = $torrent.trimend()
    $dropshowname = $rawfilename.trimstart($showname)
    $seasonepisode = ($rawfilename | select-string -pattern "S[0-9]*E[0-9]*").Matches.Value
    $season = (($seasonepisode -split ("E"))[0]).trimstart("S")
    $Episode = "E" + ($seasonepisode -split ("E"))[1]
    if ($season -eq "00") { $FullSeasonName = "Season 0" }
    elseif ($season -eq "01") { $FullSeasonName = "Season 1" }
    elseif ($season -eq "02") { $FullSeasonName = "Season 2" }
    elseif ($season -eq "03") { $FullSeasonName = "Season 3" }
    elseif ($season -eq "04") { $FullSeasonName = "Season 4" }
    elseif ($season -eq "05") { $FullSeasonName = "Season 5" }
    elseif ($season -eq "06") { $FullSeasonName = "Season 6" }
    elseif ($season -eq "07") { $FullSeasonName = "Season 7" }
    elseif ($season -eq "08") { $FullSeasonName = "Season 8" }
    elseif ($season -eq "09") { $FullSeasonName = "Season 9" }
    else { $FullSeasonName = "Season " + $season }
    $TVShowName = ($ShowObjSummary | select | where { $_.Name -eq $filename }).Name
    $INIShowPath = ($ShowObjSummary | select | where { $_.Name -eq $filename }).Path
    $TVShowPath = "$INIShowPath" + "$FullSeasonName"
    
    if (!(Test-Path $tvshowpath)) { New-Item $TVShowPath -Type Directory -force }
    
    if (($ShowObjSummary.name -contains $filename) -and ((Get-ChildItem $TVShowPath\*.mkv) -eq $null) -and ((Get-ChildItem $TVShowPath\*.mp4) -eq $null))
    {
        move-item -literalpath $file -Destination $TVShowPath -force
        Remove-Item -Path $TorrentFolder -recurse -Force
    }
    elseif (($ShowObjSummary.name -contains $filename) -and ((Get-ChildItem $TVShowPath | where { $_.name -like "*$showname*$episode*" }) -eq $null))
    {
        move-item -literalpath $file -Destination $TVShowPath -force
        Remove-Item -Path $TorrentFolder -recurse -Force
    }
}
