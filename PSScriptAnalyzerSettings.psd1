# PSScriptAnalyzer configuration for TVShowMover
# This file defines linting rules for the project

@{
    # Severity rules
    IncludeRules = @(
        'PSAlignAssignmentStatement'
        'PSAvoidDefaultValueForMandatoryParameter'
        'PSAvoidDefaultValueSwitchParameter'
        'PSAvoidGlobalAliases'
        'PSAvoidGlobalFunctions'
        'PSAvoidGlobalVariables'
        'PSAvoidInvokingEmptyMemberExpression'
        'PSAvoidLongLines'
        'PSAvoidMSGlobal'
        'PSAvoidNullReferenceException'
        'PSAvoidOverwritingBuiltInCmdlets'
        'PSAvoidShouldContinueWithoutForce'
        'PSAvoidTrailingWhitespace'
        'PSAvoidUnicodeStringLiterals'
        'PSAvoidUsingCmdletAliases'
        'PSAvoidUsingComputerNameHardcoded'
        'PSAvoidUsingConvertToSecureStringWithPlainText'
        'PSAvoidUsingDeprecatedManifestFields'
        'PSAvoidUsingEmptyCatchBlock'
        'PSAvoidUsingInvokeExpression'
        'PSAvoidUsingPlainTextForPassword'
        'PSAvoidUsingPositionalParameters'
        'PSAvoidUsingUserNameAndPassWordParams'
        'PSAvoidUsingWildcardCharactersInName'
        'PSAvoidUsingWriteHost'
        'PSMissingModuleManifestField'
        'PSPlaceCloseBrace'
        'PSPlaceOpenBrace'
        'PSPossibleIncorrectComparisonWithNull'
        'PSPossibleIncorrectUsageOfComparisonOperator'
        'PSPossibleIncorrectUsageOfRedirectionOperator'
        'PSProvideCommentHelp'
        'PSReservedCmdletChar'
        'PSReservedParams'
        'PSShouldProcess'
        'PSUseApprovedVerbs'
        'PSUseCompatibleCmdlets'
        'PSUseCompatibleCompiledDlls'
        'PSUseCompatibleSyntax'
        'PSUseConsistentIndentation'
        'PSUseConsistentWhitespace'
        'PSUseDeclaredVarsMoreThanAssignments'
        'PSUseOutputTypeCorrectly'
        'PSUsePSCredentialType'
        'PSUseShouldProcessForStateChangingFunctions'
        'PSUseSingularNouns'
    )

    # Rules to skip
    ExcludeRules = @(
        'PSProvideCommentHelp'  # Allow minimal comments where code is self-explanatory
        'PSMissingModuleManifestField'  # Not applicable to script files
    )

    # Severity levels
    Severity = @('Error', 'Warning')

    # Rules with parameters
    Rules = @{
        PSAvoidLongLines = @{
            MaximumLineLength = 120
        }
        PSAlignAssignmentStatement = @{
            Enable = $true
        }
        PSUseConsistentIndentation = @{
            IndentationSize = 4
            PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
            Enable = $true
        }
        PSUseConsistentWhitespace = @{
            CheckInnerBrace = $true
            CheckOpenBrace = $true
            CheckOpenParen = $true
            CheckOperator = $true
            CheckPipe = $true
            CheckSeparator = $true
            Enable = $true
        }
    }
}
