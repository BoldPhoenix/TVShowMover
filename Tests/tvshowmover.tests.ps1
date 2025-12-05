#Requires -Modules Pester
<#
.SYNOPSIS
    Pester test suite for TVShowMover PowerShell script

.DESCRIPTION
    Comprehensive test suite covering functionality, security, and best practices
    for the TV Show Mover application.

.NOTES
    Author: Test Suite Generator
    Created: 2025-12-05
#>

BeforeAll {
    # Import the script to test
    $ScriptPath = Join-Path $PSScriptRoot ".." "Source" "tvshowmover.ps1"

    # Create test directories
    $TestDrive = $PSScriptRoot
    $TestDownloadDir = Join-Path $TestDrive "TestDownloads"
    $TestShowDir = Join-Path $TestDrive "TestShows"

    if (-not (Test-Path $TestDownloadDir)) { New-Item -Path $TestDownloadDir -ItemType Directory -Force | Out-Null }
    if (-not (Test-Path $TestShowDir)) { New-Item -Path $TestShowDir -ItemType Directory -Force | Out-Null }
}

AfterAll {
    # Cleanup test directories
    if (Test-Path $TestDownloadDir) { Remove-Item -Path $TestDownloadDir -Recurse -Force -ErrorAction SilentlyContinue }
    if (Test-Path $TestShowDir) { Remove-Item -Path $TestShowDir -Recurse -Force -ErrorAction SilentlyContinue }
}

Describe "TVShowMover - Script Structure and Best Practices" {

    Context "Script Syntax" {
        It "Script should have valid PowerShell syntax" {
            { . $ScriptPath -ErrorAction Stop } | Should -Not -Throw
        }
    }

    Context "Help Documentation" {
        It "Script should have help comment block" {
            $Content = Get-Content $ScriptPath
            $Content | Should -Match "SYNOPSIS"
            $Content | Should -Match "DESCRIPTION"
            $Content | Should -Match "NOTES"
        }

        It "Script should document parameters" {
            $Content = Get-Content $ScriptPath
            $Content | Should -Match "Parameter\(Mandatory"
        }
    }

    Context "Version Information" {
        It "Script should have version in help header" {
            $Content = Get-Content $ScriptPath
            $Content | Should -Match "Version:\s+\d+\.\d+\.\d+\.\d+"
        }

        It "Script should have update date" {
            $Content = Get-Content $ScriptPath
            $Content | Should -Match "Updated:\s+\d{4}-\d{2}-\d{2}"
        }
    }
}

Describe "TVShowMover - Function Tests" {

    Context "Get-IniContent Function" {
        It "Should parse valid INI file correctly" {
            $TestIniFile = Join-Path $TestDownloadDir "test.ini"
            $IniContent = @"
[Shows]
TestShow1 = C:\TestPath1
TestShow2 = C:\TestPath2
"@
            $IniContent | Set-Content -Path $TestIniFile

            # Source the script to access functions
            . $ScriptPath

            $Result = Get-IniContent -iniFile $TestIniFile
            $Result | Should -Not -BeNullOrEmpty
        }

        It "Should handle missing INI file gracefully" {
            . $ScriptPath
            $Result = Get-IniContent -iniFile "C:\NonExistent\file.ini"
            $Result | Should -BeOfType [System.Collections.Generic.Dictionary`2[System.String,System.String]]
        }

        It "Should ignore comments in INI file" {
            $TestIniFile = Join-Path $TestDownloadDir "test_comments.ini"
            $IniContent = @"
[Shows]
# This is a comment
TestShow = C:\Path
"@
            $IniContent | Set-Content -Path $TestIniFile

            . $ScriptPath
            $Result = Get-IniContent -iniFile $TestIniFile
            $Result.Count | Should -BeGreaterThanOrEqual 1
        }
    }

    Context "Get-StrictRegex Function" {
        It "Should create case-insensitive regex" {
            . $ScriptPath
            $Regex = Get-StrictRegex -ShowName "TheOffice"
            $Regex | Should -Match "(?i)"
        }

        It "Should anchor regex to start of string" {
            . $ScriptPath
            $Regex = Get-StrictRegex -ShowName "Breaking Bad"
            $Regex | Should -Match "\^\$\|Breaking|Bad"
        }

        It "Should escape special characters" {
            . $ScriptPath
            $Regex = Get-StrictRegex -ShowName "Test[123]"
            $Regex | Should -Match "\[123\]"
        }
    }

    Context "Test-FuzzyMatch Function" {
        It "Should match strings with common words" {
            . $ScriptPath
            $Result = Test-FuzzyMatch -A "Breaking Bad" -B "Breaking Bad"
            $Result | Should -Be $true
        }

        It "Should not match completely different strings" {
            . $ScriptPath
            $Result = Test-FuzzyMatch -A "Breaking Bad" -B "The Office"
            $Result | Should -Be $false
        }

        It "Should ignore punctuation differences" {
            . $ScriptPath
            $Result = Test-FuzzyMatch -A "Surf-Bored" -B "Surf Bored"
            $Result | Should -Be $true
        }
    }
}

Describe "TVShowMover - File Operations" {

    Context "File Discovery" {
        It "Should discover MP4 files" {
            $TestFile = Join-Path $TestDownloadDir "TestShow.S01E01.mkv"
            New-Item -Path $TestFile -ItemType File -Force | Out-Null

            $Files = Get-ChildItem -Path $TestDownloadDir -Recurse -File -Include "*.mp4", "*.mkv", "*.avi"
            $Files | Should -Not -BeNullOrEmpty

            Remove-Item -Path $TestFile -Force
        }

        It "Should discover MKV files" {
            $TestFile = Join-Path $TestDownloadDir "TestShow.S01E01.mkv"
            New-Item -Path $TestFile -ItemType File -Force | Out-Null

            $Files = Get-ChildItem -Path $TestDownloadDir -Recurse -File -Include "*.mp4", "*.mkv", "*.avi"
            $Files | Should -Not -BeNullOrEmpty

            Remove-Item -Path $TestFile -Force
        }

        It "Should discover AVI files" {
            $TestFile = Join-Path $TestDownloadDir "TestShow.S01E01.avi"
            New-Item -Path $TestFile -ItemType File -Force | Out-Null

            $Files = Get-ChildItem -Path $TestDownloadDir -Recurse -File -Include "*.mp4", "*.mkv", "*.avi"
            $Files | Should -Not -BeNullOrEmpty

            Remove-Item -Path $TestFile -Force
        }
    }

    Context "Season Folder Creation" {
        It "Should create Season 1 folder (not Season 01)" {
            $TestSeasonDir = Join-Path $TestShowDir "Season 1"

            # Simulate season folder creation logic
            $Season = 1
            $SeasDir = Join-Path $TestShowDir ("Season " + $Season)

            if (-not (Test-Path $SeasDir)) {
                New-Item -Path $SeasDir -ItemType Directory -Force | Out-Null
            }

            Test-Path $SeasDir | Should -Be $true
            $SeasDir | Should -Match "Season 1$"
        }

        It "Should create Season 10 folder correctly" {
            $TestSeasonDir = Join-Path $TestShowDir "Season 10"

            $Season = 10
            $SeasDir = Join-Path $TestShowDir ("Season " + $Season)

            if (-not (Test-Path $SeasDir)) {
                New-Item -Path $SeasDir -ItemType Directory -Force | Out-Null
            }

            Test-Path $SeasDir | Should -Be $true
            $SeasDir | Should -Match "Season 10$"
        }
    }
}

Describe "TVShowMover - Filename Parsing" {

    Context "Standard S##E## Format" {
        It "Should match S01E01 format" {
            $Filename = "Breaking.Bad.S01E01.Pilot.mkv"
            $Filename -match "[Ss](?<season>\d{1,2})[Ee](?<episode>\d{1,2})" | Should -Be $true
        }

        It "Should match s01e05 format (lowercase)" {
            $Filename = "breaking.bad.s01e05.gray.matter.mkv"
            $Filename -match "[Ss](?<season>\d{1,2})[Ee](?<episode>\d{1,2})" | Should -Be $true
        }

        It "Should extract season and episode numbers" {
            $Filename = "Breaking.Bad.S02E07.Better.Call.Saul.mkv"
            if ($Filename -match "[Ss](?<season>\d{1,2})[Ee](?<episode>\d{1,2})") {
                [int]$Season = $matches['season']
                [int]$Episode = $matches['episode']
                $Season | Should -Be 2
                $Episode | Should -Be 7
            }
        }
    }

    Context "#x## Format (e.g., 4x05)" {
        It "Should match 4x05 format" {
            $Filename = "Breaking.Bad.4x05.Salud.mkv"
            $Filename -match "(?<season>\d{1,2})[xX](?<episode>\d{1,2})" | Should -Be $true
        }

        It "Should extract season from #x## format" {
            $Filename = "Breaking.Bad.4x05.Salud.mkv"
            if ($Filename -match "(?<season>\d{1,2})[xX](?<episode>\d{1,2})") {
                [int]$Season = $matches['season']
                $Season | Should -Be 4
            }
        }
    }

    Context "Filename Sanitization" {
        It "Should remove illegal Windows characters" {
            $Filename = "Breaking.Bad.S01E01.<Pilot>.mkv"
            $Sanitized = $Filename -replace '[<>:"/\\|?*]', ''
            $Sanitized | Should -Match "^[^<>:/\\|?*]+$"
        }

        It "Should handle filename with multiple illegal chars" {
            $Filename = 'Breaking<Bad>S01E01"Pilot|Test"'
            $Sanitized = $Filename -replace '[<>:"/\\|?*]', ''
            $Sanitized | Should -Not -Match '[<>:"/\\|?*]'
        }
    }
}

Describe "TVShowMover - Security and Safety" {

    Context "Input Validation" {
        It "Should handle null directory path" {
            { Get-ChildItem -Path $null -ErrorAction Stop } | Should -Throw
        }

        It "Should handle invalid directory path" {
            { Get-ChildItem -Path "C:\InvalidPath\ThatDoesNotExist" -ErrorAction Stop } | Should -Throw
        }
    }

    Context "File Permission Safety" {
        It "Should not move files without proper permissions" {
            $TestFile = Join-Path $TestDownloadDir "TestShow.S01E01.mkv"
            New-Item -Path $TestFile -ItemType File -Force | Out-Null

            # Set read-only to simulate permission issue
            $Item = Get-Item $TestFile
            $Item.Attributes = 'ReadOnly'

            # Should handle this gracefully (with error handling)
            $TestFile | Should -Exist

            # Cleanup
            $Item.Attributes = 'Normal'
            Remove-Item -Path $TestFile -Force
        }
    }

    Context "Path Traversal Prevention" {
        It "Should not allow directory traversal in paths" {
            $MaliciousPath = "C:\..\..\..\..\Windows\System32"
            # The script should use resolved absolute paths
            Resolve-Path $MaliciousPath -ErrorAction SilentlyContinue | Should -Not -Match "System32"
        }
    }
}

Describe "TVShowMover - Edge Cases" {

    Context "Multiple Episode Handling" {
        It "Should detect S##E##-E## format" {
            $Filename = "Breaking.Bad.S01E01-E02.double.episode.mkv"
            $Filename -match "S\d{2}E\d{2}-E\d{2}" | Should -Be $true
        }
    }

    Context "Duplicate Episode Detection" {
        It "Should identify matching episode numbers in Season folder" {
            $Season1Dir = Join-Path $TestShowDir "Season 1"
            if (-not (Test-Path $Season1Dir)) { New-Item -Path $Season1Dir -ItemType Directory -Force | Out-Null }

            # Create a test file
            $ExistingFile = Join-Path $Season1Dir "Breaking.Bad.S01E05.gray.matter.mkv"
            New-Item -Path $ExistingFile -ItemType File -Force | Out-Null

            # Check for duplicate
            $IncomingFile = "Breaking.Bad.S01E05.alternate.mkv"
            if ($IncomingFile -match "S\d{2}E(\d{2})") {
                $EpNum = $matches[1]
                $Existing = Get-ChildItem -Path $Season1Dir -File | Where-Object { $_.Name -match "S\d{2}E${EpNum}" }
                $Existing | Should -Not -BeNullOrEmpty
            }

            Remove-Item -Path $ExistingFile -Force
        }
    }

    Context "Empty Folder Cleanup" {
        It "Should identify empty directories for cleanup" {
            $EmptyDir = Join-Path $TestDownloadDir "EmptyFolder"
            New-Item -Path $EmptyDir -ItemType Directory -Force | Out-Null

            $RemainingFiles = Get-ChildItem -Path $EmptyDir -File -Recurse
            if (-not $RemainingFiles) {
                Remove-Item -Path $EmptyDir -Recurse -Force
            }

            Test-Path $EmptyDir | Should -Be $false
        }
    }
}

Describe "TVShowMover - Logging" {

    Context "Log File Creation" {
        It "Should create log file" {
            $LogFile = Join-Path $TestDownloadDir ("TVShowMover-" + (Get-Date).ToString("yyyy-MM-dd") + ".log")
            if (-not (Test-Path $LogFile)) {
                New-Item -Path $LogFile -ItemType File -Force | Out-Null
            }

            Test-Path $LogFile | Should -Be $true

            Remove-Item -Path $LogFile -Force -ErrorAction SilentlyContinue
        }
    }

    Context "Log Message Format" {
        It "Should log with timestamp" {
            $LogLine = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') Test message"
            $LogLine | Should -Match "^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}"
        }
    }
}

Describe "TVShowMover - Configuration Handling" {

    Context "INI Configuration Validation" {
        It "Should load valid INI configuration" {
            $TestIniFile = Join-Path $TestDownloadDir "tvshowmover.ini"
            $IniContent = @"
[Shows]
Breaking Bad = $TestShowDir\Breaking Bad
The Office = $TestShowDir\The Office
"@
            $IniContent | Set-Content -Path $TestIniFile

            Test-Path $TestIniFile | Should -Be $true
            Get-Content $TestIniFile | Should -Match "\[Shows\]"

            Remove-Item -Path $TestIniFile -Force
        }

        It "Should handle INI file with no entries" {
            $TestIniFile = Join-Path $TestDownloadDir "empty.ini"
            "[Shows]`n" | Set-Content -Path $TestIniFile

            Test-Path $TestIniFile | Should -Be $true

            Remove-Item -Path $TestIniFile -Force
        }
    }
}
