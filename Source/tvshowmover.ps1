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
# Version 2.0.0.7 - 10/22/2020 - See Readme file for update details.
# Version 2.0.0.8 - 10/28/2020 - See Readme file for update details.
# Version 2.0.0.9 - 02/17/2021 - See Readme file for update details.
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

$listfilepaths = (get-childitem $DownloadDirectory -recurse | select | where { ((($_.Name -like '*.S[0-9][0-9]E[0-9][0-9].*') -or ($_.Name -like '*.S[0-9][0-9][0-9]E[0-9][0-9].*')) -and (($_.Name -like "*.mkv") -or ($_.Name -like "*.mp4") -and ($_.Name -notlike "*sample*.*"))) }).FullName
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
    elseif ($season -eq "S31") { $FullSeasonName = "Season 31" }
    elseif ($season -eq "S32") { $FullSeasonName = "Season 32" }
    elseif ($season -eq "S33") { $FullSeasonName = "Season 33" }
    elseif ($season -eq "S34") { $FullSeasonName = "Season 34" }
    elseif ($season -eq "S35") { $FullSeasonName = "Season 35" }
    elseif ($season -eq "S36") { $FullSeasonName = "Season 36" }
    elseif ($season -eq "S37") { $FullSeasonName = "Season 37" }
    elseif ($season -eq "S38") { $FullSeasonName = "Season 38" }
    elseif ($season -eq "S39") { $FullSeasonName = "Season 39" }
    elseif ($season -eq "S40") { $FullSeasonName = "Season 40" }
    elseif ($season -eq "S41") { $FullSeasonName = "Season 41" }
    elseif ($season -eq "S42") { $FullSeasonName = "Season 42" }
    elseif ($season -eq "S43") { $FullSeasonName = "Season 43" }
    elseif ($season -eq "S44") { $FullSeasonName = "Season 44" }
    elseif ($season -eq "S45") { $FullSeasonName = "Season 45" }
    elseif ($season -eq "S46") { $FullSeasonName = "Season 46" }
    elseif ($season -eq "S47") { $FullSeasonName = "Season 47" }
    elseif ($season -eq "S48") { $FullSeasonName = "Season 48" }
    elseif ($season -eq "S49") { $FullSeasonName = "Season 49" }
    elseif ($season -eq "S50") { $FullSeasonName = "Season 50" }
    elseif ($season -eq "S51") { $FullSeasonName = "Season 51" }
    elseif ($season -eq "S52") { $FullSeasonName = "Season 52" }
    elseif ($season -eq "S53") { $FullSeasonName = "Season 53" }
    elseif ($season -eq "S54") { $FullSeasonName = "Season 54" }
    elseif ($season -eq "S55") { $FullSeasonName = "Season 55" }
    elseif ($season -eq "S56") { $FullSeasonName = "Season 56" }
    elseif ($season -eq "S57") { $FullSeasonName = "Season 57" }
    elseif ($season -eq "S58") { $FullSeasonName = "Season 58" }
    elseif ($season -eq "S59") { $FullSeasonName = "Season 59" }
    elseif ($season -eq "S60") { $FullSeasonName = "Season 60" }
    elseif ($season -eq "S61") { $FullSeasonName = "Season 61" }
    elseif ($season -eq "S62") { $FullSeasonName = "Season 62" }
    elseif ($season -eq "S63") { $FullSeasonName = "Season 63" }
    elseif ($season -eq "S64") { $FullSeasonName = "Season 64" }
    elseif ($season -eq "S65") { $FullSeasonName = "Season 65" }
    elseif ($season -eq "S66") { $FullSeasonName = "Season 66" }
    elseif ($season -eq "S67") { $FullSeasonName = "Season 67" }
    elseif ($season -eq "S68") { $FullSeasonName = "Season 68" }
    elseif ($season -eq "S69") { $FullSeasonName = "Season 69" }
    elseif ($season -eq "S70") { $FullSeasonName = "Season 70" }
    elseif ($season -eq "S71") { $FullSeasonName = "Season 71" }
    elseif ($season -eq "S72") { $FullSeasonName = "Season 72" }
    elseif ($season -eq "S73") { $FullSeasonName = "Season 73" }
    elseif ($season -eq "S74") { $FullSeasonName = "Season 74" }
    elseif ($season -eq "S75") { $FullSeasonName = "Season 75" }
    elseif ($season -eq "S76") { $FullSeasonName = "Season 76" }
    elseif ($season -eq "S77") { $FullSeasonName = "Season 77" }
    elseif ($season -eq "S78") { $FullSeasonName = "Season 78" }
    elseif ($season -eq "S79") { $FullSeasonName = "Season 79" }
    elseif ($season -eq "S80") { $FullSeasonName = "Season 80" }
    elseif ($season -eq "S81") { $FullSeasonName = "Season 81" }
    elseif ($season -eq "S82") { $FullSeasonName = "Season 82" }
    elseif ($season -eq "S83") { $FullSeasonName = "Season 83" }
    elseif ($season -eq "S84") { $FullSeasonName = "Season 84" }
    elseif ($season -eq "S85") { $FullSeasonName = "Season 85" }
    elseif ($season -eq "S86") { $FullSeasonName = "Season 86" }
    elseif ($season -eq "S87") { $FullSeasonName = "Season 87" }
    elseif ($season -eq "S88") { $FullSeasonName = "Season 88" }
    elseif ($season -eq "S89") { $FullSeasonName = "Season 89" }
    elseif ($season -eq "S90") { $FullSeasonName = "Season 90" }
    elseif ($season -eq "S91") { $FullSeasonName = "Season 91" }
    elseif ($season -eq "S92") { $FullSeasonName = "Season 92" }
    elseif ($season -eq "S93") { $FullSeasonName = "Season 93" }
    elseif ($season -eq "S94") { $FullSeasonName = "Season 94" }
    elseif ($season -eq "S95") { $FullSeasonName = "Season 95" }
    elseif ($season -eq "S96") { $FullSeasonName = "Season 96" }
    elseif ($season -eq "S97") { $FullSeasonName = "Season 97" }
    elseif ($season -eq "S98") { $FullSeasonName = "Season 98" }
    elseif ($season -eq "S99") { $FullSeasonName = "Season 99" }
    $TVShowName = ($ShowObjSummary | select | where { $_.Name -eq $filename }).Name
    $INIShowPath = ($ShowObjSummary | select | where { $_.Name -eq $filename }).Path
    $TVShowPath = "$INIShowPath" + "$FullSeasonName"
    
    if (!(Test-Path $tvshowpath)) { New-Item $TVShowPath -Type Directory -force }
    
    if (($ShowObjSummary.name -contains $filename) -and ((Get-ChildItem $TVShowPath\*.mkv) -eq $null) -and ((Get-ChildItem $TVShowPath\*.mp4) -eq $null))
    {
        move-item -literalpath $file -Destination $TVShowPath -force
        if (!($TorrentFolder -eq $PSScriptRoot))
        {
            Remove-Item -Path $TorrentFolder -recurse -Force
        }
    }
    elseif (($ShowObjSummary.name -contains $filename) -and ((Get-ChildItem $TVShowPath | where { $_.name -like "*$showname*$episode*" }) -eq $null))
    {
        move-item -literalpath $file -Destination $TVShowPath -force
        if (!($TorrentFolder -eq $PSScriptRoot))
        {
            Remove-Item -Path $TorrentFolder -recurse -Force
        }
    }
}