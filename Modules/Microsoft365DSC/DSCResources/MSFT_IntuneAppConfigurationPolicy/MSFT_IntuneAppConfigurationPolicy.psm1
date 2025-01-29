function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter()]
        [System.String]
        $Id,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DisplayName,

        [Parameter()]
        [System.String]
        $Description,

        [Parameter()]
        [System.String[]]
        $RoleScopeTagIds,

        [Parameter()]
        [System.String]
        [ValidateSet('unspecified','unmanaged','mdm','androidEnterprise','androidEnterpriseDedicatedDevicesWithAzureAdSharedMode','androidOpenSourceProjectUserAssociated','androidOpenSourceProjectUserless','unknownFutureValue')]
        $TargetedAppManagementLevels,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Apps,

        [Parameter()]
        [System.String]
        [ValidateSet(
        'selectedPublicApps','allCoreMicrosoftApps','allMicrosoftApps','allApps')]
        $AppGroupType,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $CustomSettings,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Assignments,

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

    Write-Verbose -Message "Getting configuration of the Intune App Configuration Policy with Id {$Id} and DisplayName {$DisplayName}"

    try
    {
        if (-not $Script:exportedInstance)
        {
            $ConnectionMode = New-M365DSCConnection -Workload 'MicrosoftGraph' `
                -InboundParameters $PSBoundParameters

            #Ensure the proper dependencies are installed in the current environment.
            Confirm-M365DSCDependencies

            #region Telemetry
            $ResourceName = $MyInvocation.MyCommand.ModuleName -replace 'MSFT_', ''
            $CommandName = $MyInvocation.MyCommand
            $data = Format-M365DSCTelemetryParameters -ResourceName $ResourceName `
                -CommandName $CommandName `
                -Parameters $PSBoundParameters
            Add-M365DSCTelemetryEvent -Data $data
            #endregion

            $nullResult = ([Hashtable]$PSBoundParameters).clone()
            $nullResult.Ensure = 'Absent'

            $configPolicy = $null
            if (-not [string]::IsNullOrEmpty($Id))
            {
                $configPolicy = Get-MgBetaDeviceAppManagementTargetedManagedAppConfiguration -TargetedManagedAppConfigurationId $Id -ExpandProperty 'Apps' `
                    -ErrorAction SilentlyContinue
            }

            if ($null -eq $configPolicy)
            {
                Write-Verbose -Message "Could not find an Intune App Configuration Policy with Id {$Id}, searching by DisplayName {$DisplayName}"

                try
                {
                    $configPolicy = Get-MgBetaDeviceAppManagementTargetedManagedAppConfiguration -All -Filter "displayName eq '$DisplayName'" -ExpandProperty 'Apps' `
                        -ErrorAction Stop
                }
                catch
                {
                    $configPolicy = $null
                }

                if ($null -eq $configPolicy)
                {
                    Write-Verbose -Message "No App Configuration Policy with DisplayName {$DisplayName} was found"
                    return $nullResult
                }
                if (([array]$configPolicy).count -gt 1)
                {
                    throw "A policy with a duplicated displayName {'$DisplayName'} was found - Ensure displayName is unique"
                }
            }
        }
        else
        {
            $configPolicy = $Script:exportedInstance
        }

        Write-Verbose -Message "Found App Configuration Policy with Id {$($configPolicy.Id)} and DisplayName {$($configPolicy.DisplayName)}"
        #get the full app details and replace what was retrieved using Get-MgBetaDeviceAppManagementTargetedManagedAppConfiguration
        if($null -ne $configPolicy.Apps)
        {
            $AppConfiguration = Get-MgBetaDeviceAppManagementTargetedManagedAppConfigurationApp -TargetedManagedAppConfigurationId $configPolicy.Id
            $complexAppsArray = @()
            foreach($currentValue in $AppConfiguration){
                if ($null -ne $currentValue)
                {
                    if($null -ne $currentValue.mobileAppIdentifier.AdditionalProperties.bundleId)
                    {
                        $complexMobileAppIdentifier = @{}
                        $complexMobileAppIdentifier = @{
                            #'@odata.type' = "#microsoft.graph.iosMobileAppIdentifier"
                            bundleID       = $currentValue.mobileAppIdentifier.AdditionalProperties.bundleId
                        }
                    }

                    if($null -ne $currentValue.mobileAppIdentifier.AdditionalProperties.packageId)
                    {
                        $complexMobileAppIdentifier = @{}
                        $complexMobileAppIdentifier = @{
                            #'@odata.type' = "#microsoft.graph.androidMobileAppIdentifier"
                            packageId       = $currentValue.mobileAppIdentifier.AdditionalProperties.packageId
                        }
                    }

                    if($null -ne $currentValue.mobileAppIdentifier.AdditionalProperties.windowsAppId)
                    {
                        $complexMobileAppIdentifier = @{}
                        $complexMobileAppIdentifier = @{
                            #'@odata.type' = "#microsoft.graph.windowsAppIdentifier"
                            windowsAppId       = $currentValue.mobileAppIdentifier.AdditionalProperties.windowsAppId
                        }
                    }
                    $complexAppsHash = @{}
                    $complexAppsHash.Add('id', $currentValue.Id)
                    $complexAppsHash.Add('version', $currentValue.Version)
                    $complexAppsHash.Add('mobileAppIdentifier', $complexMobileAppIdentifier)
                    $complexAppsArray += $complexAppsHash
                }
            }
        }

        $returnHashtable = @{
            Id                          = $configPolicy.Id
            DisplayName                 = $configPolicy.DisplayName
            Description                 = $configPolicy.Description
            CustomSettings              = $configPolicy.customSettings
            Ensure                      = 'Present'
            Credential                  = $Credential
            ApplicationId               = $ApplicationId
            TenantId                    = $TenantId
            ApplicationSecret           = $ApplicationSecret
            CertificateThumbprint       = $CertificateThumbprint
            Managedidentity             = $ManagedIdentity.IsPresent
            AccessTokens                = $AccessTokens
            RoleScopeTagIds             = $configPolicy.RoleScopeTagIds
            TargetedAppManagementLevels = [String]$configPolicy.TargetedAppManagementLevels
            AppGroupType                = [String]$configPolicy.AppGroupType
            Apps                        = $complexAppsArray
        }

        $returnAssignments = @()
        $graphAssignments = Get-MgBetaDeviceAppManagementTargetedManagedAppConfigurationAssignment -TargetedManagedAppConfigurationId $configPolicy.Id
        if ($graphAssignments.count -gt 0)
        {
            $returnAssignments += ConvertFrom-IntunePolicyAssignment `
                -IncludeDeviceFilter:$true `
                -Assignments ($graphAssignments)
        }
        $returnHashtable.Add('Assignments', $returnAssignments)

        return $returnHashtable
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
        [Parameter()]
        [System.String]
        $Id,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DisplayName,

        [Parameter()]
        [System.String]
        $Description,

        [Parameter()]
        [System.String[]]
        $RoleScopeTagIds,

        [Parameter()]
        [System.String]
        [ValidateSet('unspecified','unmanaged','mdm','androidEnterprise','androidEnterpriseDedicatedDevicesWithAzureAdSharedMode','androidOpenSourceProjectUserAssociated','androidOpenSourceProjectUserless','unknownFutureValue')]
        $TargetedAppManagementLevels,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Apps,

        [Parameter()]
        [System.String]
        [ValidateSet(
        'selectedPublicApps','allCoreMicrosoftApps','allMicrosoftApps','allApps')]
        $AppGroupType,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $CustomSettings,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Assignments,

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

    Write-Verbose -Message "Setting configuration of Intune App Configuration Policy {$DisplayName}"

    $ConnectionMode = New-M365DSCConnection -Workload 'MicrosoftGraph' `
        -InboundParameters $PSBoundParameters

    #Ensure the proper dependencies are installed in the current environment.
    Confirm-M365DSCDependencies

    #region Telemetry
    $ResourceName = $MyInvocation.MyCommand.ModuleName -replace 'MSFT_', ''
    $CommandName = $MyInvocation.MyCommand
    $data = Format-M365DSCTelemetryParameters -ResourceName $ResourceName `
        -CommandName $CommandName `
        -Parameters $PSBoundParameters
    Add-M365DSCTelemetryEvent -Data $data
    #endregion

    $currentconfigPolicy = Get-TargetResource @PSBoundParameters

    if ($Ensure -eq 'Present' -and $currentconfigPolicy.Ensure -eq 'Absent')
    {
        Write-Verbose -Message "Creating new Intune App Configuration Policy {$DisplayName}"
        $creationParams = @{
            displayName = $DisplayName
            description = $Description
        }
        if ($null -ne $CustomSettings)
        {
            [System.Object[]]$customSettingsValue = ConvertTo-M365DSCIntuneAppConfigurationPolicyCustomSettings -Settings $CustomSettings
            $creationParams.Add('customSettings', $customSettingsValue)
        }

        if ($null -ne $Apps)
        {
            $appsArray = @()
            foreach($app in $Apps){
                if($null -ne $app.mobileAppIdentifier.bundleID)
                {
                $mobileAppIdentifierHashtable = @{}
                $mobileAppIdentifierHashtable['@odata.type'] = "#microsoft.graph.iosMobileAppIdentifier"
                $mobileAppIdentifierHashtable['bundleId'] = $app.mobileAppIdentifier.bundleID
                }

                if($null -ne $app.mobileAppIdentifier.packageID)
                {
                    $mobileAppIdentifierHashtable = @{}
                    $mobileAppIdentifierHashtable['@odata.type'] = "#microsoft.graph.androidMobileAppIdentifier"
                    $mobileAppIdentifierHashtable['packageId'] = $app.mobileAppIdentifier.packageId
                }

                if($null -ne $app.mobileAppIdentifier.windowsAppID)
                {
                    $mobileAppIdentifierHashtable = @{}
                    $mobileAppIdentifierHashtable['@odata.type'] = "#microsoft.graph.windowsAppIdentifier"
                    $mobileAppIdentifierHashtable['windowsAppId'] = $app.mobileAppIdentifier.windowsAppId
                }

                $appHashtable = @{}
                $appHashtable['id'] = $App.Id
                $appHashtable['version'] = $App.Version
                $appHashtable['mobileAppIdentifier'] = $mobileAppIdentifierHashtable
                $appsArray += $appHashtable
            }
            $creationParams.Add('apps', $appsArray)
        }

        $policy = New-MgBetaDeviceAppManagementTargetedManagedAppConfiguration @creationParams

        #region Assignments
        $assignmentsHash = ConvertTo-IntunePolicyAssignment -IncludeDeviceFilter:$true -Assignments $Assignments

        if ($policy.id)
        {
            Update-DeviceConfigurationPolicyAssignment -DeviceConfigurationPolicyId $policy.id `
                -Targets $assignmentsHash `
                -Repository 'deviceAppManagement/targetedManagedAppConfigurations'
        }
        #endregion
    }
    elseif ($Ensure -eq 'Present' -and $currentconfigPolicy.Ensure -eq 'Present')
    {
        Write-Verbose -Message "Updating Intune App Configuration Policy {$DisplayName}"
        #apps handled separately as not supported by Update-MgBetaDeviceAppManagementTargetedManagedAppConfiguration
        $updateParams = @{
            targetedManagedAppConfigurationId = $currentconfigPolicy.Id
            displayName                       = $DisplayName
            description                       = $Description
        }
        if ($null -ne $CustomSettings)
        {
            $customSettingsValue = ConvertTo-M365DSCIntuneAppConfigurationPolicyCustomSettings -Settings $CustomSettings
            $updateParams.Add('customSettings', $customSettingsValue)
        }
        
        if ($null -ne $Apps)
        {
            $appsArray = @()
            foreach ($app in $Apps)
            {
                if ($null -ne $app.mobileAppIdentifier.bundleID)
                {
                    $mobileAppIdentifierHashtable = @{
                        '@odata.type' = "#microsoft.graph.iosMobileAppIdentifier"
                        bundleId      = $app.mobileAppIdentifier.bundleID
                    }
                }

                if ($null -ne $app.mobileAppIdentifier.packageID)
                {
                    $mobileAppIdentifierHashtable = @{
                        '@odata.type' = "#microsoft.graph.androidMobileAppIdentifier"
                        packageId     = $app.mobileAppIdentifier.packageId
                    }
                }

                if ($null -ne $app.mobileAppIdentifier.windowsAppID)
                {
                    $mobileAppIdentifierHashtable = @{
                        '@odata.type' = "#microsoft.graph.windowsAppIdentifier"
                        windowsAppId  = $app.mobileAppIdentifier.windowsAppId
                    }
                }

                $appsArray += @{
                    'mobileAppIdentifier' = $mobileAppIdentifierHashtable
                }
            }

            $appsBody = @{
                appGroupType = $AppGroupType
                apps = $appsArray
            }

            Write-Verbose -Message "Updating Apps for Intune App Configuration Policy {$DisplayName}"
            $Uri = (Get-MSCloudLoginConnectionProfile -Workload MicrosoftGraph).ResourceUrl + "beta/deviceAppManagement/targetedManagedAppConfigurations('$($currentconfigPolicy.Id)')/targetApps"
            Invoke-MgGraphRequest -Method POST -Uri $Uri -Body $($appsBody | ConvertTo-Json -Depth 10) -Verbose
        }

        Update-MgBetaDeviceAppManagementTargetedManagedAppConfiguration @updateParams

        $assignmentsHash = ConvertTo-IntunePolicyAssignment -IncludeDeviceFilter:$true -Assignments $Assignments
        Update-DeviceConfigurationPolicyAssignment -DeviceConfigurationPolicyId $currentconfigPolicy.Id `
            -Targets $assignmentsHash `
            -Repository 'deviceAppManagement/targetedManagedAppConfigurations'
    }
    elseif ($Ensure -eq 'Absent' -and $currentconfigPolicy.Ensure -eq 'Present')
    {
        Write-Verbose -Message "Removing Intune App Configuration Policy {$DisplayName}"
        Remove-MgBetaDeviceAppManagementTargetedManagedAppConfiguration -TargetedManagedAppConfigurationId $currentconfigPolicy.Id
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [System.String]
        $Id,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DisplayName,

        [Parameter()]
        [System.String]
        $Description,

        [Parameter()]
        [System.String[]]
        $RoleScopeTagIds,

        [Parameter()]
        [System.String]
        [ValidateSet('unspecified','unmanaged','mdm','androidEnterprise','androidEnterpriseDedicatedDevicesWithAzureAdSharedMode','androidOpenSourceProjectUserAssociated','androidOpenSourceProjectUserless','unknownFutureValue')]
        $TargetedAppManagementLevels,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Apps,

        [Parameter()]
        [System.String]
        [ValidateSet(
        'selectedPublicApps','allCoreMicrosoftApps','allMicrosoftApps','allApps')]
        $AppGroupType,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $CustomSettings,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Assignments,

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
    $ResourceName = $MyInvocation.MyCommand.ModuleName -replace 'MSFT_', ''
    $CommandName = $MyInvocation.MyCommand
    $data = Format-M365DSCTelemetryParameters -ResourceName $ResourceName `
        -CommandName $CommandName `
        -Parameters $PSBoundParameters
    Add-M365DSCTelemetryEvent -Data $data
    #endregion
    Write-Verbose -Message "Testing configuration of Intune App Configuration Policy {$DisplayName}"

    $CurrentValues = Get-TargetResource @PSBoundParameters
    if (-not (Test-M365DSCAuthenticationParameter -BoundParameters $CurrentValues))
    {
        Write-Verbose "An error occured in Get-TargetResource, the policy {$displayName} will not be processed"
        throw "An error occured in Get-TargetResource, the policy {$displayName} will not be processed. Refer to the event viewer logs for more information."
    }
    $ValuesToCheck = ([Hashtable]$PSBoundParameters).clone()
    $ValuesToCheck = Remove-M365DSCAuthenticationParameter -BoundParameters $ValuesToCheck
    $ValuesToCheck.Remove('Id') | Out-Null

    Write-Verbose -Message "Current Values: $(Convert-M365DscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-M365DscHashtableToString -Hashtable $PSBoundParameters)"

    if ($CurrentValues.Ensure -ne $Ensure)
    {
        Write-Verbose -Message "Test-TargetResource returned $false"
        return $false
    }
    $testResult = $true

    #Compare Cim instances
    foreach ($key in $PSBoundParameters.Keys)
    {
        $source = $PSBoundParameters.$key
        $target = $CurrentValues.$key
        if ($source.getType().Name -like '*CimInstance*')
        {
            $testResult = Compare-M365DSCComplexObject `
                -Source ($source) `
                -Target ($target)

            if (-Not $testResult)
            {
                $testResult = $false
                break
            }

            $ValuesToCheck.Remove($key) | Out-Null
        }
    }

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
    $ResourceName = $MyInvocation.MyCommand.ModuleName -replace 'MSFT_', ''
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
        [array]$configPolicies = Get-MgBetaDeviceAppManagementTargetedManagedAppConfiguration -ExpandProperty 'Apps' -All:$true -Filter $Filter -ErrorAction Stop
        $configPolicies = Find-GraphDataUsingComplexFunctions -ComplexFunctions $complexFunctions -Policies $configPolicies

        $i = 1
        $dscContent = ''
        if ($configPolicies.Length -eq 0)
        {
            Write-Host $Global:M365DSCEmojiGreenCheckMark
        }
        else
        {
            Write-Host "`r`n" -NoNewline
        }
        foreach ($configPolicy in $configPolicies)
        {
            if ($null -ne $Global:M365DSCExportResourceInstancesCount)
            {
                $Global:M365DSCExportResourceInstancesCount++
            }

            Write-Host "    |---[$i/$($configPolicies.Count)] $($configPolicy.displayName)" -NoNewline
            $params = @{
                Id                    = $configPolicy.Id
                DisplayName           = $configPolicy.displayName
                Ensure                = 'Present'
                Credential            = $Credential
                ApplicationID         = $ApplicationId
                TenantId              = $TenantId
                ApplicationSecret     = $ApplicationSecret
                CertificateThumbprint = $CertificateThumbprint
                Managedidentity       = $ManagedIdentity.IsPresent
                AccessTokens          = $AccessTokens
            }

            $Script:exportedInstance = $configPolicy
            $Results = Get-TargetResource @params
            if (-not (Test-M365DSCAuthenticationParameter -BoundParameters $Results))
            {
                Write-Verbose "An error occured in Get-TargetResource, the policy {$($params.displayName)} will not be processed"
                throw "An error occured in Get-TargetResource, the policy {$($params.displayName)} will not be processed. Refer to the event viewer logs for more information."
            }

            if ($Results.CustomSettings.Count -gt 0)
            {
                $Results.CustomSettings = Get-M365DSCIntuneAppConfigurationPolicyCustomSettingsAsString -Settings $Results.CustomSettings
            }

            if ($Results.Apps)
            {
                $complexTypeMapping = @(
                    @{
                        Name            = 'Apps'
                        CimInstanceName = 'managedMobileApp'
                    }
                    @{
                        Name            = 'mobileAppIdentifier'
                        CimInstanceName = 'AppIdentifier'
                        isRequired      = $true
                    }
                )

                $complexTypeStringResult = Get-M365DSCDRGComplexTypeToString `
                    -ComplexObject $Results.Apps `
                    -CIMInstanceName managedMobileApp `
                    -ComplexTypeMapping $complexTypeMapping
                if ($complexTypeStringResult)
                {
                    $Results.Apps = $complexTypeStringResult
                }
                else
                {
                    $Results.Remove('Apps') | Out-Null
                }
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
            if ($null -ne $Results.CustomSettings)
            {
                $currentDSCBlock = Convert-DSCStringParamToVariable -DSCBlock $currentDSCBlock -ParameterName 'CustomSettings'
            }

            if ($Results.Assignments)
            {
                $isCIMArray = $false
                if ($Results.Assignments.getType().Fullname -like '*[[\]]')
                {
                    $isCIMArray = $true
                }
                $currentDSCBlock = Convert-DSCStringParamToVariable -DSCBlock $currentDSCBlock -ParameterName 'Assignments' -IsCIMArray:$isCIMArray
            }

            if ($Results.Apps)
            {
                $isCIMArray = $false
                if ($Results.Apps.getType().Fullname -like '*[[\]]')
                {
                    $isCIMArray = $true
                }
                $currentDSCBlock = Convert-DSCStringParamToVariable -DSCBlock $currentDSCBlock -ParameterName 'Apps' -IsCIMArray:$isCIMArray
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

function Get-M365DSCIntuneAppConfigurationPolicyCustomSettingsAsString
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param(
        [Parameter(Mandatory = $true)]
        [System.Object[]]
        $Settings
    )

    $StringContent = '@('
    $space = '                '
    $indent = '    '

    $i = 1
    foreach ($setting in $Settings)
    {
        if ($Settings.Count -gt 1)
        {
            $StringContent += "`r`n"
            $StringContent += "$space"
        }
        $StringContent += "MSFT_IntuneAppConfigurationPolicyCustomSetting { `r`n"
        $StringContent += "$($space)$($indent)name  = '" + $setting.name + "'`r`n"
        $StringContent += "$($space)$($indent)value = '" + $setting.value + "'`r`n"
        $StringContent += "$space}"

        $i++
    }

    $StringContent += ')'
    return $StringContent
}

function ConvertTo-M365DSCIntuneAppConfigurationPolicyCustomSettings
{
    [OutputType([System.Object[]])]
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]
        $Settings
    )

    $result = @()
    foreach ($setting in $Settings)
    {
        $currentSetting = @{
            name  = $setting.name
            value = $setting.value
        }
        $result += $currentSetting
    }
    return $result
}

Export-ModuleMember -Function *-TargetResource
