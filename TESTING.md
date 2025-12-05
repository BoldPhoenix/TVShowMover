# TVShowMover - Test Suite and Quality Documentation

## Overview

This document describes the test suite, code quality standards, and validation procedures for the TV Show Mover application.

## Test Suite

The application includes a comprehensive Pester test suite located in `Tests/tvshowmover.tests.ps1`.

### Running the Tests

#### Prerequisites
- PowerShell 5.0 or higher
- Pester module installed

```powershell
# Install Pester if not already installed
Install-Module -Name Pester -Force -SkipPublisherCheck

# Run all tests
Invoke-Pester -Path "Tests\tvshowmover.tests.ps1" -Output Detailed

# Run specific test group
Invoke-Pester -Path "Tests\tvshowmover.tests.ps1" -Output Detailed -Container (New-PesterContainer -Path "Tests\tvshowmover.tests.ps1" -Data @{ TestGroup = "Function Tests" })

# Generate HTML report
Invoke-Pester -Path "Tests\tvshowmover.tests.ps1" -Output Detailed -PassThru | Export-NunitReport -Path "TestResults.xml"
```

### Test Coverage

The test suite covers the following areas:

#### 1. **Script Structure and Best Practices**
- ✅ Valid PowerShell syntax
- ✅ Help documentation completeness
- ✅ Version information
- ✅ Update date tracking

#### 2. **Function Tests**
- ✅ `Get-IniContent`: INI file parsing with edge cases
- ✅ `Get-StrictRegex`: Regex generation for show matching
- ✅ `Test-FuzzyMatch`: Fuzzy string matching logic
- ✅ Configuration validation

#### 3. **File Operations**
- ✅ Video file discovery (MP4, MKV, AVI)
- ✅ Season folder creation with proper naming
- ✅ File movement operations
- ✅ Source folder cleanup

#### 4. **Filename Parsing**
- ✅ Standard S##E## format matching
- ✅ Alternative #x## format (e.g., 4x05)
- ✅ Episode number extraction
- ✅ Filename sanitization

#### 5. **Security and Safety**
- ✅ Input validation
- ✅ Path traversal prevention
- ✅ File permission safety
- ✅ Error handling

#### 6. **Edge Cases**
- ✅ Multiple episode handling (S##E##-E##)
- ✅ Duplicate episode detection
- ✅ Empty folder cleanup
- ✅ Malformed filenames

#### 7. **Logging**
- ✅ Log file creation
- ✅ Log message formatting with timestamps

#### 8. **Configuration**
- ✅ INI file parsing
- ✅ Configuration validation
- ✅ Missing entries handling

## Code Quality Standards

### PSScriptAnalyzer Configuration

The project uses `PSScriptAnalyzer` for static code analysis. Configuration is in `PSScriptAnalyzerSettings.psd1`.

#### Running PSScriptAnalyzer

```powershell
# Install PSScriptAnalyzer if not already installed
Install-Module -Name PSScriptAnalyzer -Force

# Run analysis on main script
Invoke-ScriptAnalyzer -Path "Source\tvshowmover.ps1" -Settings PSScriptAnalyzerSettings.psd1 -ReportSummary

# Run analysis on test file
Invoke-ScriptAnalyzer -Path "Tests\tvshowmover.tests.ps1" -Settings PSScriptAnalyzerSettings.psd1

# Run analysis on all PowerShell files
Invoke-ScriptAnalyzer -Path "." -Recurse -Settings PSScriptAnalyzerSettings.psd1
```

### Compliance Standards

The following standards are enforced:

- **No cmdlet aliases**: Use full cmdlet names for maintainability
- **No Write-Host**: Use Write-Output, Write-Verbose, or Write-Information
- **No trailing whitespace**: Clean, consistent formatting
- **Error handling**: All operations wrapped in try-catch blocks
- **Comment documentation**: Complex logic is well-commented
- **Parameter validation**: All inputs are validated before use
- **Security**: No hardcoded credentials, safe path handling

### Quality Metrics

Current status:
- ✅ **Syntax**: Valid
- ✅ **Lint issues**: 0/0 violations (100% compliant)
- ✅ **Test coverage**: 8 major test groups with 30+ individual tests
- ✅ **Documentation**: Complete

## Security Considerations

### Input Validation
- File paths are resolved to absolute paths
- Directory traversal attempts are prevented
- INI configuration is validated before use
- Filename special characters are sanitized

### File Operations
- Operations use `-ErrorAction` to handle failures gracefully
- File move is atomic; fails safely if destination exists
- Source folders cleaned only after successful operations
- Proper permission checks before file operations

### API Calls
- TVMaze API calls include error handling
- API errors are logged but don't prevent operation
- Timeouts are configured to prevent hanging

### Logging
- All operations are logged with timestamps
- Sensitive information is not logged
- Log files are created with proper paths

## Best Practices Implemented

### PowerShell Standards
- ✅ CmdletBinding attribute for parameter handling
- ✅ Proper error handling with try-catch-finally
- ✅ Verbose output with Write-Verbose where appropriate
- ✅ Consistent naming conventions (PascalCase for functions)
- ✅ Comment-based help
- ✅ Parameter validation and typing

### Performance
- ✅ Efficient regex matching
- ✅ Minimal API calls (caching would be future enhancement)
- ✅ Batch operations where possible
- ✅ Early exit conditions to prevent unnecessary processing

### Maintainability
- ✅ Clear function documentation
- ✅ Logical code organization
- ✅ No hardcoded values (configurable via INI)
- ✅ Consistent code formatting
- ✅ Version tracking

## Continuous Improvement

### Future Enhancements
- Add performance benchmarking tests
- Implement hash-based duplicate detection (compare file contents)
- Add network connectivity checks for API calls
- Implement retry logic for failed API calls
- Add configuration schema validation

### Running Full Quality Checks

```powershell
# Complete quality check
$result = @{
    PSAnalyzerResult = Invoke-ScriptAnalyzer -Path "Source\tvshowmover.ps1" -Settings PSScriptAnalyzerSettings.psd1
    TestResult = Invoke-Pester -Path "Tests\tvshowmover.tests.ps1" -PassThru
}

# Display results
$result | Format-List

# Exit with error code if any failures
if ($result.PSAnalyzerResult -or -not $result.TestResult.Passed) { exit 1 }
```

## Troubleshooting

### Common Issues

**Q: Pester not installed**
```powershell
Install-Module -Name Pester -Force -SkipPublisherCheck -Scope CurrentUser
```

**Q: PSScriptAnalyzer not installed**
```powershell
Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser
```

**Q: Tests fail due to path issues**
- Ensure you're running from the root directory of the project
- Check that test directories have proper permissions

**Q: API tests timeout**
- Verify internet connectivity
- Check TVMaze API status
- Increase timeout values if network is slow

## References

- [Pester Documentation](https://pester.dev/)
- [PSScriptAnalyzer Documentation](https://docs.microsoft.com/en-us/powershell/module/psscriptanalyzer/)
- [PowerShell Best Practices](https://docs.microsoft.com/en-us/powershell/scripting/developer/windows-powershell-best-practices)
- [TVMaze API Documentation](https://www.tvmaze.com/api)
