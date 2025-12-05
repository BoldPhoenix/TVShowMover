#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Complete test and quality check runner for TVShowMover

.DESCRIPTION
    This script runs PSScriptAnalyzer lint checks and Pester tests
    to ensure code quality and functionality.

.NOTES
    Author: TVShowMover Project
    Created: 2025-12-05
#>

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Color codes for output
$Colors = @{
    Success = 'Green'
    Warning = 'Yellow'
    Error = 'Red'
    Info = 'Cyan'
}

# Functions
function Write-Status {
    param(
        [string]$Message,
        [ValidateSet('Success', 'Warning', 'Error', 'Info')]
        [string]$Status = 'Info'
    )
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $Message" -ForegroundColor $Colors[$Status]
}

function Test-Module {
    param([string]$ModuleName)

    $Module = Get-Module -ListAvailable -Name $ModuleName
    if (-not $Module) {
        Write-Status "Installing $ModuleName..." -Status 'Warning'
        Install-Module -Name $ModuleName -Force -Scope CurrentUser -AllowClobber
    }
    else {
        Write-Status "$ModuleName is installed" -Status 'Success'
    }
}

# Main execution
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "TVShowMover Quality Check" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Initialize tracking
$AllPassed = $true
$Results = @{
    PSScriptAnalyzer = @{ Passed = $false; Violations = 0 }
    Pester = @{ Passed = $false; FailedTests = 0; PassedTests = 0 }
}

# Check required modules
Write-Status "Checking required modules..." -Status 'Info'
Test-Module 'PSScriptAnalyzer'
Test-Module 'Pester'

# Run PSScriptAnalyzer
Write-Status "Running PSScriptAnalyzer..." -Status 'Info'
try {
    $ProjectRoot = Split-Path -Parent $PSScriptRoot
    $AnalysisResult = Invoke-ScriptAnalyzer -Path "$ProjectRoot\Source\tvshowmover.ps1" `
        -Settings "$ProjectRoot\PSScriptAnalyzerSettings.psd1" -Recurse

    if (-not $AnalysisResult) {
        Write-Status "✓ PSScriptAnalyzer: No violations found" -Status 'Success'
        $Results.PSScriptAnalyzer.Passed = $true
        $Results.PSScriptAnalyzer.Violations = 0
    }
    else {
        Write-Status "✗ PSScriptAnalyzer: $($AnalysisResult.Count) violations found" -Status 'Error'
        $Results.PSScriptAnalyzer.Violations = $AnalysisResult.Count
        $AllPassed = $false

        $AnalysisResult | ForEach-Object {
            Write-Host "  - Line $($_.Line): $($_.Message)" -ForegroundColor Yellow
        }
    }
}
catch {
    Write-Status "✗ PSScriptAnalyzer: Error - $_" -Status 'Error'
    $AllPassed = $false
}

# Run Pester Tests
Write-Status "`nRunning Pester tests..." -Status 'Info'
try {
    $ProjectRoot = Split-Path -Parent $PSScriptRoot
    $TestFile = "$ProjectRoot\Tests\tvshowmover.tests.ps1"

    if (Test-Path $TestFile) {
        $TestResult = Invoke-Pester -Path $TestFile -Output Detailed -PassThru

        if ($TestResult.FailedCount -eq 0) {
            Write-Status "✓ Pester: All $($TestResult.PassedCount) tests passed" -Status 'Success'
            $Results.Pester.Passed = $true
            $Results.Pester.PassedTests = $TestResult.PassedCount
        }
        else {
            Write-Status "✗ Pester: $($TestResult.FailedCount) test(s) failed, $($TestResult.PassedCount) passed" -Status 'Error'
            $Results.Pester.FailedTests = $TestResult.FailedCount
            $Results.Pester.PassedTests = $TestResult.PassedCount
            $AllPassed = $false
        }
    }
    else {
        Write-Status "⚠ Pester test file not found at $TestFile" -Status 'Warning'
    }
}
catch {
    Write-Status "⚠ Pester: Warning - $_" -Status 'Warning'
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Quality Check Summary" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "PSScriptAnalyzer:" -ForegroundColor White
Write-Host "  Status: $(if ($Results.PSScriptAnalyzer.Passed) { '✓ Passed' } else { '✗ Failed' })" -ForegroundColor $(if ($Results.PSScriptAnalyzer.Passed) { 'Green' } else { 'Red' })
Write-Host "  Violations: $($Results.PSScriptAnalyzer.Violations)" -ForegroundColor White

Write-Host "`nPester:" -ForegroundColor White
Write-Host "  Status: $(if ($Results.Pester.Passed) { '✓ Passed' } else { '✗ Failed' })" -ForegroundColor $(if ($Results.Pester.Passed) { 'Green' } else { 'Red' })
Write-Host "  Passed: $($Results.Pester.PassedTests)" -ForegroundColor Green
Write-Host "  Failed: $($Results.Pester.FailedTests)" -ForegroundColor $(if ($Results.Pester.FailedTests -eq 0) { 'Green' } else { 'Red' })

Write-Host "`nOverall Status:" -ForegroundColor White
if ($AllPassed) {
    Write-Status "✓ All checks passed!" -Status 'Success'
    exit 0
}
else {
    Write-Status "✗ Some checks failed. Please review the output above." -Status 'Error'
    exit 1
}
