function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $DisplayName,

        [Parameter()]
        [System.String]
        $Description,

        [Parameter()]
        [System.Boolean]
        $DeviceThreatProtectionEnabled,
#mine
        [Parameter()]
        [System.String]
        [ValidateSet('none', 'low', 'medium', 'high')] #The password complexity types that can be set on Android. One of: NONE, LOW, MEDIUM, HIGH. This is an API targeted to Android 11+
        $requiredPasswordComplexity,

        [Parameter()]
        [System.Boolean]
        $securityBlockDeviceAdministratorManagedDevices, #Setting securityBlockDeviceAdministratorManagedDevices to true enhances security by preventing devices managed through the legacy device administrator method from accessing corporate resources

        [Parameter()]
        [System.String[]]
        $restrictedApps, #specify applications that users are prohibited from installing or using on their devices.

        [Parameter()]
        [System.String]
        [ValidateSet('deviceDefault', 'lowSecurityBiometric', 'required', 'atLeastNumeric', 'numericComplex', 'atLeastAlphabetic', 'atLeastAlphanumeric', 'alphanumericWithSymbols')] #Specifies Android Work Profile password type.
        $workProfilePasswordRequiredType,

        [Parameter()]
        [System.String]
        [ValidateSet('None', 'Low', 'Medium', 'High')] #Specifies Android Work Profile password complexity.
        $workProfileRequiredPasswordComplexity, 

        [Parameter()]
        [System.Boolean]
        $WorkProfileRequirePassword, #Specifies if Android Work Profile password is required.

        [Parameter()]
        [System.Int32]
        $workProfilePreviousPasswordBlockCount, #Specifies the number of previous passwords that cannot be reused in an Android Work Profile compliance policy.

        [Parameter()]
        [System.Int32]
        $workProfileInactiveBeforeScreenLockInMinutes, #Defines the duration of inactivity (in minutes) after which the screen is locked.

        [Parameter()]
        [System.Int32]
        $workProfilePasswordMinimumLength, #Specifies the minimum number of characters required in a password for an Android Work Profile

        [Parameter()]
        [System.Int32]
        $workProfilePasswordExpirationInDays, #Specifies the number of days before a password expires for an Android Work Profile

<#
        [Parameter()]
        [System.Boolean]
        $passcodeBlockSimple

#end mine #>
        [Parameter()]
        [System.String]
        [ValidateSet('unavailable', 'secured', 'low', 'medium', 'high', 'notSet')]
        $DeviceThreatProtectionRequiredSecurityLevel,

        [Parameter()]
        [System.String]
        [ValidateSet('unavailable', 'secured', 'low', 'medium', 'high', 'notSet')]
        $AdvancedThreatProtectionRequiredSecurityLevel,

        [Parameter()]
        [System.Boolean]
        $SecurityRequireSafetyNetAttestationBasicIntegrity,

        [Parameter()]
        [System.Boolean]
        $SecurityRequireSafetyNetAttestationCertifiedDevice,

        [Parameter()]
        [System.String]
        $OsMinimumVersion,

        [Parameter()]
        [System.String]
        $OsMaximumVersion,

        [Parameter()]
        [System.Boolean]
        $PasswordRequired,

        [Parameter()]
        [System.Int32]
        $PasswordMinimumLength,

        [Parameter()]
        [System.String]
        [ValidateSet('deviceDefault', 'alphabetic', 'alphanumeric', 'alphanumericWithSymbols', 'lowSecurityBiometric', 'numeric', 'numericComplex', 'any')]
        $PasswordRequiredType,

        [Parameter()]
        [System.Int32]
        $PasswordMinutesOfInactivityBeforeLock,

        [Parameter()]
        [System.Int32]
        $PasswordExpirationDays,

        [Parameter()]
        [System.Int32]
        $PasswordPreviousPasswordCountToBlock,

        [Parameter()]
        [System.Boolean]
        $StorageRequireEncryption,

        [Parameter()]
        [System.Boolean]
        $SecurityRequireIntuneAppIntegrity,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Assignments,

        [Parameter()]
        [System.String[]]
        $RoleScopeTagIds,

        [Parameter()]
        [System.String]
        [ValidateSet('Absent', 'Present')]
        $Ensure = 'Present',

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter()]
        [System.String]
        $ApplicationId,

        [Parameter()]
        [System.String]
        $TenantId,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $ApplicationSecret,

        [Parameter()]
        [System.String]
        $CertificateThumbprint,

        [Parameter()]
        [Switch]
        $ManagedIdentity,

        [Parameter()]
        [System.String[]]
        $AccessTokens
    )

    Write-Verbose -Message "Checking for the Intune Android Work Profile Device Compliance Policy {$DisplayName}"
    $ConnectionMode = New-M365DSCConnection -Workload 'MicrosoftGraph' `
        -InboundParameters $PSBoundParameters

    #Ensure the proper dependencies are installed in the current environment.
    Confirm-M365DSCDependencies

    #region Telemetry
    $ResourceName = $MyInvocation.MyCommand.ModuleName.Replace('MSFT_', '')
    $CommandName = $MyInvocation.MyCommand
    $data = Format-M365DSCTelemetryParameters -ResourceName $ResourceName `
        -CommandName $CommandName `
        -Parameters $PSBoundParameters
    Add-M365DSCTelemetryEvent -Data $data
    #endregion

    $nullResult = $PSBoundParameters
    $nullResult.Ensure = 'Absent'
    try
    {
        $devicePolicy = Get-MgBetaDeviceManagementDeviceCompliancePolicy `
            -All `
            -ErrorAction Stop | Where-Object `
            -FilterScript {
            $_.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.androidDeviceOwnerCompliancePolicy' -and `
                $_.displayName -eq $($DisplayName)
        }
        if (([array]$devicePolicy).count -gt 1)
        {
            throw "A policy with a duplicated displayName {'$DisplayName'} was found - Ensure displayName is unique"
        }
        if ($null -eq $devicePolicy)
        {
            Write-Verbose -Message "No Intune Android Device Owner Device Compliance Policy with displayName {$DisplayName} was found"
            return $nullResult
        }

        Write-Verbose -Message "Found Intune Android Device Owner Device Compliance Policy with displayName {$DisplayName}"
        $results = @{
            requiredPasswordComplexity                         = $devicePolicy.AdditionalProperties.requiredPasswordComplexity
            securityBlockDeviceAdministratorManagedDevices     = $devicePolicy.AdditionalProperties.securityBlockDeviceAdministratorManagedDevices
            restrictedApps                                     = $devicePolicy.AdditionalProperties.restrictedApps
            
            DisplayName                                        = $devicePolicy.DisplayName
            Description                                        = $devicePolicy.Description
            DeviceThreatProtectionEnabled                      = $devicePolicy.AdditionalProperties.deviceThreatProtectionEnabled
            DeviceThreatProtectionRequiredSecurityLevel        = $devicePolicy.AdditionalProperties.deviceThreatProtectionRequiredSecurityLevel
            AdvancedThreatProtectionRequiredSecurityLevel      = $devicePolicy.AdditionalProperties.advancedThreatProtectionRequiredSecurityLevel
            SecurityRequireSafetyNetAttestationBasicIntegrity  = $devicePolicy.AdditionalProperties.securityRequireSafetyNetAttestationBasicIntegrity
            SecurityRequireSafetyNetAttestationCertifiedDevice = $devicePolicy.AdditionalProperties.securityRequireSafetyNetAttestationCertifiedDevice
            OsMinimumVersion                                   = $devicePolicy.AdditionalProperties.osMinimumVersion
            OsMaximumVersion                                   = $devicePolicy.AdditionalProperties.osMaximumVersion
            PasswordRequired                                   = $devicePolicy.AdditionalProperties.passwordRequired
            PasswordMinimumLength                              = $devicePolicy.AdditionalProperties.passwordMinimumLength
            PasswordRequiredType                               = $devicePolicy.AdditionalProperties.passwordRequiredType
            PasswordMinutesOfInactivityBeforeLock              = $devicePolicy.AdditionalProperties.passwordMinutesOfInactivityBeforeLock
            PasswordExpirationDays                             = $devicePolicy.AdditionalProperties.passwordExpirationDays
            PasswordPreviousPasswordCountToBlock               = $devicePolicy.AdditionalProperties.passwordPreviousPasswordCountToBlock
            StorageRequireEncryption                           = $devicePolicy.AdditionalProperties.storageRequireEncryption
            SecurityRequireIntuneAppIntegrity                  = $devicePolicy.AdditionalProperties.securityRequireIntuneAppIntegrity
            RoleScopeTagIds                                    = $devicePolicy.roleScopeTagIds
            Ensure                                             = 'Present'
            Credential                                         = $Credential
            ApplicationId                                      = $ApplicationId
            TenantId                                           = $TenantId
            ApplicationSecret                                  = $ApplicationSecret
            CertificateThumbprint                              = $CertificateThumbprint
            Managedidentity                                    = $ManagedIdentity.IsPresent
            AccessTokens                                       = $AccessTokens
        }

        $returnAssignments = @()
        $graphAssignments = Get-MgBetaDeviceManagementDeviceCompliancePolicyAssignment -DeviceCompliancePolicyId $devicePolicy.Id
        if ($graphAssignments.count -gt 0)
        {
            $returnAssignments += ConvertFrom-IntunePolicyAssignment `
                -IncludeDeviceFilter:$true `
                -Assignments ($graphAssignments)
        }
        $results.Add('Assignments', $returnAssignments)

        return [System.Collections.Hashtable] $results
    }
    catch
    {
        New-M365DSCLogEntry -Message 'Error retrieving data:' `
            -Exception $_ `
            -Source $($MyInvocation.MyCommand.Source) `
            -TenantId $TenantId `
            -Credential $Credential

        $nullResult = Clear-M365DSCAuthenticationParameter -BoundParameters $nullResult
        return $nullResult
    }
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $DisplayName,

        [Parameter()]
        [System.String]
        $Description,

        [Parameter()]
        [System.Boolean]
        $DeviceThreatProtectionEnabled,

        [Parameter()]
        [System.String]
        [ValidateSet('unavailable', 'secured', 'low', 'medium', 'high', 'notSet')]
        $DeviceThreatProtectionRequiredSecurityLevel,

        [Parameter()]
        [System.String]
        [ValidateSet('unavailable', 'secured', 'low', 'medium', 'high', 'notSet')]
        $AdvancedThreatProtectionRequiredSecurityLevel,

        [Parameter()]
        [System.Boolean]
        $SecurityRequireSafetyNetAttestationBasicIntegrity,

        [Parameter()]
        [System.Boolean]
        $SecurityRequireSafetyNetAttestationCertifiedDevice,

        [Parameter()]
        [System.String]
        $OsMinimumVersion,

        [Parameter()]
        [System.String]
        $OsMaximumVersion,

        [Parameter()]
        [System.Boolean]
        $PasswordRequired,

        [Parameter()]
        [System.Int32]
        $PasswordMinimumLength,

        [Parameter()]
        [System.String]
        [ValidateSet('deviceDefault', 'alphabetic', 'alphanumeric', 'alphanumericWithSymbols', 'lowSecurityBiometric', 'numeric', 'numericComplex', 'any')]
        $PasswordRequiredType,

        [Parameter()]
        [System.Int32]
        $PasswordMinutesOfInactivityBeforeLock,

        [Parameter()]
        [System.Int32]
        $PasswordExpirationDays,

        [Parameter()]
        [System.Int32]
        $PasswordPreviousPasswordCountToBlock,

        [Parameter()]
        [System.Boolean]
        $StorageRequireEncryption,

        [Parameter()]
        [System.Boolean]
        $SecurityRequireIntuneAppIntegrity,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Assignments,

        [Parameter()]
        [System.String[]]
        $RoleScopeTagIds,

        [Parameter()]
        [System.String]
        [ValidateSet('Absent', 'Present')]
        $Ensure = 'Present',

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter()]
        [System.String]
        $ApplicationId,

        [Parameter()]
        [System.String]
        $TenantId,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $ApplicationSecret,

        [Parameter()]
        [System.String]
        $CertificateThumbprint,

        [Parameter()]
        [Switch]
        $ManagedIdentity,

        [Parameter()]
        [System.String[]]
        $AccessTokens
    )

    Write-Verbose -Message "Intune Android Device Owner Device Compliance Policy {$DisplayName}"

    $ConnectionMode = New-M365DSCConnection -Workload 'MicrosoftGraph' `
        -InboundParameters $PSBoundParameters

    #Ensure the proper dependencies are installed in the current environment.
    Confirm-M365DSCDependencies

    #region Telemetry
    $ResourceName = $MyInvocation.MyCommand.ModuleName.Replace('MSFT_', '')
    $CommandName = $MyInvocation.MyCommand
    $data = Format-M365DSCTelemetryParameters -ResourceName $ResourceName `
        -CommandName $CommandName `
        -Parameters $PSBoundParameters
    Add-M365DSCTelemetryEvent -Data $data
    #endregion

    $currentDeviceAndroidPolicy = Get-TargetResource @PSBoundParameters

    $PSBoundParameters.Remove('Ensure') | Out-Null
    $PSBoundParameters.Remove('Credential') | Out-Null
    $PSBoundParameters.Remove('ApplicationId') | Out-Null
    $PSBoundParameters.Remove('TenantId') | Out-Null
    $PSBoundParameters.Remove('ApplicationSecret') | Out-Null
    $PSBoundParameters.Remove('CertificateThumbprint') | Out-Null
    $PSBoundParameters.Remove('ManagedIdentity') | Out-Null
    $PSBoundParameters.Remove('AccessTokens') | Out-Null

    $scheduledActionsForRule = @{
        ruleName                      = 'PasswordRequired'
        scheduledActionConfigurations = @(
            @{
                '@odata.type' = '#microsoft.graph.deviceComplianceActionItem'
                actionType    = 'block'
            }
        )
    }

    if ($Ensure -eq 'Present' -and $currentDeviceAndroidPolicy.Ensure -eq 'Absent')
    {
        Write-Verbose -Message "Creating new Intune Android Work Profile Device Compliance Policy {$DisplayName}"
        $PSBoundParameters.Remove('DisplayName') | Out-Null
        $PSBoundParameters.Remove('Description') | Out-Null
        $PSBoundParameters.Remove('Assignments') | Out-Null

        $AdditionalProperties = Get-M365DSCIntuneDeviceCompliancePolicyAndroidDeviceOwnerAdditionalProperties -Properties ([System.Collections.Hashtable]$PSBoundParameters)
        $policy = New-MgBetaDeviceManagementDeviceCompliancePolicy -DisplayName $DisplayName `
            -Description $Description `
            -AdditionalProperties $AdditionalProperties `
            -ScheduledActionsForRule $scheduledActionsForRule

        #region Assignments
        $assignmentsHash = ConvertTo-IntunePolicyAssignment -IncludeDeviceFilter:$true -Assignments $Assignments
        if ($policy.id)
        {
            Update-DeviceConfigurationPolicyAssignment -DeviceConfigurationPolicyId $policy.id `
                -Targets $assignmentsHash `
                -Repository 'deviceManagement/deviceCompliancePolicies'
        }
        #endregion

    }
    elseif ($Ensure -eq 'Present' -and $currentDeviceAndroidPolicy.Ensure -eq 'Present')
    {
        Write-Verbose -Message "Updating Intune Android Device Owner Device Compliance Policy {$DisplayName}"
        $configDeviceAndroidPolicy = Get-MgBetaDeviceManagementDeviceCompliancePolicy `
            -ErrorAction Stop | Where-Object `
            -FilterScript {
            $_.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.androidDeviceOwnerCompliancePolicy' -and `
                $_.displayName -eq $($DisplayName)
        }

        $PSBoundParameters.Remove('DisplayName') | Out-Null
        $PSBoundParameters.Remove('Description') | Out-Null
        $PSBoundParameters.Remove('Assignments') | Out-Null

        $AdditionalProperties = Get-M365DSCIntuneDeviceCompliancePolicyAndroidDeviceOwnerAdditionalProperties -Properties ([System.Collections.Hashtable]$PSBoundParameters)
        Update-MgBetaDeviceManagementDeviceCompliancePolicy -AdditionalProperties $AdditionalProperties `
            -Description $Description `
            -DeviceCompliancePolicyId $configDeviceAndroidPolicy.Id

        #region Assignments
        $assignmentsHash = ConvertTo-IntunePolicyAssignment -IncludeDeviceFilter:$true -Assignments $Assignments
        Update-DeviceConfigurationPolicyAssignment -DeviceConfigurationPolicyId $configDeviceAndroidPolicy.id `
            -Targets $assignmentsHash `
            -Repository 'deviceManagement/deviceCompliancePolicies'
        #endregion
    }
    elseif ($Ensure -eq 'Absent' -and $currentDeviceAndroidPolicy.Ensure -eq 'Present')
    {
        Write-Verbose -Message "Removing Intune Android Device Owner Device Compliance Policy {$DisplayName}"
        $configDeviceAndroidPolicy = Get-MgBetaDeviceManagementDeviceCompliancePolicy `
            -ErrorAction Stop | Where-Object `
            -FilterScript {
            $_.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.androidDeviceOwnerCompliancePolicy' -and `
                $_.displayName -eq $($DisplayName)
        }

        Remove-MgBetaDeviceManagementDeviceCompliancePolicy -DeviceCompliancePolicyId $configDeviceAndroidPolicy.Id
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $DisplayName,

        [Parameter()]
        [System.String]
        $Description,

        [Parameter()]
        [System.Boolean]
        $DeviceThreatProtectionEnabled,

        [Parameter()]
        [System.String]
        [ValidateSet('unavailable', 'secured', 'low', 'medium', 'high', 'notSet')]
        $DeviceThreatProtectionRequiredSecurityLevel,

        [Parameter()]
        [System.String]
        [ValidateSet('unavailable', 'secured', 'low', 'medium', 'high', 'notSet')]
        $AdvancedThreatProtectionRequiredSecurityLevel,

        [Parameter()]
        [System.Boolean]
        $SecurityRequireSafetyNetAttestationBasicIntegrity,

        [Parameter()]
        [System.Boolean]
        $SecurityRequireSafetyNetAttestationCertifiedDevice,

        [Parameter()]
        [System.String]
        $OsMinimumVersion,

        [Parameter()]
        [System.String]
        $OsMaximumVersion,

        [Parameter()]
        [System.Boolean]
        $PasswordRequired,

        [Parameter()]
        [System.Int32]
        $PasswordMinimumLength,

        [Parameter()]
        [System.String]
        [ValidateSet('deviceDefault', 'alphabetic', 'alphanumeric', 'alphanumericWithSymbols', 'lowSecurityBiometric', 'numeric', 'numericComplex', 'any')]
        $PasswordRequiredType,

        [Parameter()]
        [System.Int32]
        $PasswordMinutesOfInactivityBeforeLock,

        [Parameter()]
        [System.Int32]
        $PasswordExpirationDays,

        [Parameter()]
        [System.Int32]
        $PasswordPreviousPasswordCountToBlock,

        [Parameter()]
        [System.Boolean]
        $StorageRequireEncryption,

        [Parameter()]
        [System.Boolean]
        $SecurityRequireIntuneAppIntegrity,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Assignments,

        [Parameter()]
        [System.String[]]
        $RoleScopeTagIds,

        [Parameter()]
        [System.String]
        [ValidateSet('Absent', 'Present')]
        $Ensure = 'Present',

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter()]
        [System.String]
        $ApplicationId,

        [Parameter()]
        [System.String]
        $TenantId,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $ApplicationSecret,

        [Parameter()]
        [System.String]
        $CertificateThumbprint,

        [Parameter()]
        [Switch]
        $ManagedIdentity,

        [Parameter()]
        [System.String[]]
        $AccessTokens
    )

    #Ensure the proper dependencies are installed in the current environment.
    Confirm-M365DSCDependencies

    #region Telemetry
    $ResourceName = $MyInvocation.MyCommand.ModuleName.Replace('MSFT_', '')
    $CommandName = $MyInvocation.MyCommand
    $data = Format-M365DSCTelemetryParameters -ResourceName $ResourceName `
        -CommandName $CommandName `
        -Parameters $PSBoundParameters
    Add-M365DSCTelemetryEvent -Data $data
    #endregion

    Write-Verbose -Message "Testing configuration of Intune Android Work Profile Device Compliance Policy {$DisplayName}"

    $CurrentValues = Get-TargetResource @PSBoundParameters
    if (-not (Test-M365DSCAuthenticationParameter -BoundParameters $CurrentValues))
    {
        Write-Verbose "An error occured in Get-TargetResource, the policy {$displayName} will not be processed"
        throw "An error occured in Get-TargetResource, the policy {$displayName} will not be processed. Refer to the event viewer logs for more information."
    }

    Write-Verbose -Message "Current Values: $(Convert-M365DscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-M365DscHashtableToString -Hashtable $PSBoundParameters)"

    $ValuesToCheck = $PSBoundParameters

    $testResult = $true
    if ($CurrentValues.Ensure -ne $Ensure)
    {
        $testResult = $false
    }
    #region Assignments
    if ($testResult)
    {
        $source = Get-M365DSCDRGComplexTypeToHashtable -ComplexObject $PSBoundParameters.Assignments
        $target = $CurrentValues.Assignments
        $testResult = Compare-M365DSCIntunePolicyAssignment -Source $source -Target $target
        $ValuesToCheck.Remove('Assignments') | Out-Null
    }
    #endregion

    if ($testResult)
    {
        $TestResult = Test-M365DSCParameterState -CurrentValues $CurrentValues `
            -Source $($MyInvocation.MyCommand.Source) `
            -DesiredValues $PSBoundParameters `
            -ValuesToCheck $ValuesToCheck.Keys
    }
    Write-Verbose -Message "Test-TargetResource returned $TestResult"

    return $TestResult
}

function Export-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter()]
        [System.String]
        $Filter,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter()]
        [System.String]
        $ApplicationId,

        [Parameter()]
        [System.String]
        $TenantId,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $ApplicationSecret,

        [Parameter()]
        [System.String]
        $CertificateThumbprint,

        [Parameter()]
        [Switch]
        $ManagedIdentity,

        [Parameter()]
        [System.String[]]
        $AccessTokens
    )

    $ConnectionMode = New-M365DSCConnection -Workload 'MicrosoftGraph' `
        -InboundParameters $PSBoundParameters

    #Ensure the proper dependencies are installed in the current environment.
    Confirm-M365DSCDependencies

    #region Telemetry
    $ResourceName = $MyInvocation.MyCommand.ModuleName.Replace('MSFT_', '')
    $CommandName = $MyInvocation.MyCommand
    $data = Format-M365DSCTelemetryParameters -ResourceName $ResourceName `
        -CommandName $CommandName `
        -Parameters $PSBoundParameters
    Add-M365DSCTelemetryEvent -Data $data
    #endregion

    try
    {
        if (-not [string]::IsNullOrEmpty($Filter))
        {
            $complexFunctions = Get-ComplexFunctionsFromFilterQuery -FilterQuery $Filter
            $Filter = Remove-ComplexFunctionsFromFilterQuery -FilterQuery $Filter
        }
        [array]$configDeviceAndroidPolicies = Get-MgBetaDeviceManagementDeviceCompliancePolicy `
            -ErrorAction Stop -All:$true -Filter $Filter | Where-Object `
            -FilterScript {
            $_.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.androidDeviceOwnerCompliancePolicy'
        }
        $configDeviceAndroidPolicies = Find-GraphDataUsingComplexFunctions -ComplexFunctions $complexFunctions -Policies $configDeviceAndroidPolicies

        $i = 1
        $dscContent = ''
        if ($configDeviceAndroidPolicies.Length -eq 0)
        {
            Write-Host $Global:M365DSCEmojiGreenCheckMark
        }
        else
        {
            Write-Host "`r`n" -NoNewline
        }
        foreach ($configDeviceAndroidPolicy in $configDeviceAndroidPolicies)
        {
            if ($null -ne $Global:M365DSCExportResourceInstancesCount)
            {
                $Global:M365DSCExportResourceInstancesCount++
            }

            Write-Host "    |---[$i/$($configDeviceAndroidPolicies.Count)] $($configDeviceAndroidPolicy.displayName)" -NoNewline
            $params = @{
                DisplayName           = $configDeviceAndroidPolicy.displayName
                Ensure                = 'Present'
                Credential            = $Credential
                ApplicationId         = $ApplicationId
                TenantId              = $TenantId
                ApplicationSecret     = $ApplicationSecret
                CertificateThumbprint = $CertificateThumbprint
                Managedidentity       = $ManagedIdentity.IsPresent
                AccessTokens          = $AccessTokens
            }
            $Results = Get-TargetResource @params
            if (-not (Test-M365DSCAuthenticationParameter -BoundParameters $Results))
            {
                Write-Verbose "An error occured in Get-TargetResource, the policy {$($params.displayName)} will not be processed"
                throw "An error occured in Get-TargetResource, the policy {$($params.displayName)} will not be processed. Refer to the event viewer logs for more information."
            }

            if ($Results.Assignments)
            {
                $complexTypeStringResult = Get-M365DSCDRGComplexTypeToString -ComplexObject ([Array]$Results.Assignments) -CIMInstanceName DeviceManagementConfigurationPolicyAssignments

                if ($complexTypeStringResult)
                {
                    $Results.Assignments = $complexTypeStringResult
                }
                else
                {
                    $Results.Remove('Assignments') | Out-Null
                }
            }

            $Results = Update-M365DSCExportAuthenticationResults -ConnectionMode $ConnectionMode `
                -Results $Results
            $currentDSCBlock = Get-M365DSCExportContentForResource -ResourceName $ResourceName `
                -ConnectionMode $ConnectionMode `
                -ModulePath $PSScriptRoot `
                -Results $Results `
                -Credential $Credential


            if ($Results.Assignments)
            {
                $isCIMArray = $false
                if ($Results.Assignments.getType().Fullname -like '*[[\]]')
                {
                    $isCIMArray = $true
                }
                $currentDSCBlock = Convert-DSCStringParamToVariable -DSCBlock $currentDSCBlock -ParameterName 'Assignments' -IsCIMArray:$isCIMArray
            }

            $dscContent += $currentDSCBlock

            Save-M365DSCPartialExport -Content $currentDSCBlock `
                -FileName $Global:PartialExportFileName
            $i++
            Write-Host $Global:M365DSCEmojiGreenCheckMark
        }
        return $dscContent
    }
    catch
    {
        if ($_.Exception -like '*401*' -or $_.ErrorDetails.Message -like "*`"ErrorCode`":`"Forbidden`"*" -or `
                $_.Exception -like '*Request not applicable to target tenant*')
        {
            Write-Host "`r`n    $($Global:M365DSCEmojiYellowCircle) The current tenant is not registered for Intune."
        }
        else
        {
            Write-Host $Global:M365DSCEmojiRedX

            New-M365DSCLogEntry -Message 'Error during Export:' `
                -Exception $_ `
                -Source $($MyInvocation.MyCommand.Source) `
                -TenantId $TenantId `
                -Credential $Credential
        }

        return ''
    }
}

function Get-M365DSCIntuneDeviceCompliancePolicyAndroidDeviceOwnerAdditionalProperties
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = 'true')]
        [System.Collections.Hashtable]
        $Properties
    )

    $results = @{'@odata.type' = '#microsoft.graph.androidDeviceOwnerCompliancePolicy' }
    foreach ($property in $properties.Keys)
    {
        if ($property -ne 'Verbose')
        {
            $propertyName = $property[0].ToString().ToLower() + $property.Substring(1, $property.Length - 1)
            $propertyValue = $properties.$property
            $results.Add($propertyName, $propertyValue)
        }
    }
    return $results
}

Export-ModuleMember -Function *-TargetResource
