function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        #region resource generator code
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
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $airPrintDestinations,

        [Parameter()]
        [System.String]
        $assetTagTemplate,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $contentFilterSettings,

        [Parameter()]
        [System.String]
        $lockScreenFootnote,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $homeScreenDockIcons,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $homeScreenPages,

        [Parameter()]
        [System.Int32]
        $homeScreenGridWidth,

        [Parameter()]
        [System.Int32]
        $homeScreenGridHeight,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $notificationSettings,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $singleSignOnSettings,

        [Parameter()]
        [ValidateSet("notConfigured", "lockScreen", "homeScreen", "lockAndHomeScreens")]
        [System.String]
        $wallpaperDisplayLocation,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $wallpaperImage,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $iosSingleSignOnExtension,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Assignments,
        #endregion

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

    try
    {
        $ConnectionMode = New-M365DSCConnection -Workload 'MicrosoftGraph' `
            -InboundParameters $PSBoundParameters
    }
    catch
    {
        Write-Verbose -Message 'Connection to the workload failed.'
    }

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
        if (-not [string]::IsNullOrWhiteSpace($id))
        { 
            $getValue = Get-MgBetaDeviceManagementDeviceConfiguration -DeviceConfigurationId $id -ErrorAction SilentlyContinue 
        }

        #region resource generator code
        if ($null -eq $getValue)
        {
            $getValue = Get-MgBetaDeviceManagementDeviceConfiguration -All -Filter "DisplayName eq '$Displayname'" -ErrorAction SilentlyContinue | Where-Object `
            -FilterScript { `
                $_.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.iosDeviceFeaturesConfiguration' `
            }
        }
        #endregion

        if ($null -eq $getValue)
        {
            Write-Verbose -Message "No Intune VPN Policy for iOS with Id {$id} was found"
            return $nullResult
        }

        $Id = $getValue.Id

        Write-Verbose -Message "An Intune VPN Policy for iOS with id {$id} and DisplayName {$DisplayName} was found"



        $results = @{
            #region resource generator code
            Id                       = $getValue.Id
            Description              = $getValue.Description
            DisplayName              = $getValue.DisplayName
            Ensure                   = 'Present'
            Credential               = $Credential
            ApplicationId            = $ApplicationId
            TenantId                 = $TenantId
            ApplicationSecret        = $ApplicationSecret
            CertificateThumbprint    = $CertificateThumbprint
            Managedidentity          = $ManagedIdentity.IsPresent
            AccessTokens             = $AccessTokens
            airPrintDestinations     = Convert-ComplexObjectToHashtableArray $getValue.AdditionalProperties.airPrintDestinations
            assetTagTemplate         = $getValue.AdditionalProperties.assetTagTemplate
            contentFilterSettings    = Convert-ComplexObjectToHashtableArray $getValue.AdditionalProperties.contentFilterSettings
            lockScreenFootnote       = $getValue.AdditionalProperties.lockScreenFootnote
            homeScreenDockIcons      = Convert-ComplexObjectToHashtableArray $getValue.AdditionalProperties.homeScreenDockIcons
            homeScreenPages          = Convert-ComplexObjectToHashtableArray $getValue.AdditionalProperties.homeScreenPages
            homeScreenGridWidth      = $getValue.AdditionalProperties.homeScreenGridWidth
            homeScreenGridHeight     = $getValue.AdditionalProperties.homeScreenGridHeight
            notificationSettings     = Convert-ComplexObjectToHashtableArray $getValue.AdditionalProperties.notificationSettings
            singleSignOnSettings     = Convert-ComplexObjectToHashtableArray $getValue.AdditionalProperties.singleSignOnSettings
            wallpaperDisplayLocation = Convert-ComplexObjectToHashtableArray $getValue.AdditionalProperties.wallpaperDisplayLocation 
            wallpaperImage           = Convert-ComplexObjectToHashtableArray $getValue.AdditionalProperties.wallpaperImage
            iosSingleSignOnExtension = Convert-ComplexObjectToHashtableArray $getValue.AdditionalProperties.iosSingleSignOnExtension
        }
                                          
        $assignmentsValues = Get-MgBetaDeviceManagementDeviceConfigurationAssignment -DeviceConfigurationId $Results.Id
        $assignmentResult = @()
        if ($assignmentsValues.Count -gt 0)
        {
            $assignmentResult += ConvertFrom-IntunePolicyAssignment `
                                -IncludeDeviceFilter:$true `
                                -Assignments ($assignmentsValues)
        }
        $results.Add('Assignments', $assignmentResult)

        return [System.Collections.Hashtable] $results
    }
    catch
    {
        New-M365DSCLogEntry -Message 'Error retrieving data:' `
            -Exception $_ `
            -Source $($MyInvocation.MyCommand.Source) `
            -TenantId $TenantId `
            -Credential $Credential

        return $nullResult
    }
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        #region resource generator code
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
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $airPrintDestinations,

        [Parameter()]
        [System.String]
        $assetTagTemplate,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $contentFilterSettings,

        [Parameter()]
        [System.String]
        $lockScreenFootnote,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $homeScreenDockIcons,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $homeScreenPages,

        [Parameter()]
        [System.Int32]
        $homeScreenGridWidth,

        [Parameter()]
        [System.Int32]
        $homeScreenGridHeight,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $notificationSettings,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $singleSignOnSettings,

        [Parameter()]
        [ValidateSet("notConfigured", "lockScreen", "homeScreen", "lockAndHomeScreens")]
        [System.String]
        $wallpaperDisplayLocation,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $wallpaperImage,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $iosSingleSignOnExtension,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Assignments,
        #endregion

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

    try
    {
        $ConnectionMode = New-M365DSCConnection -Workload 'MicrosoftGraph' `
            -InboundParameters $PSBoundParameters
    }
    catch
    {
        Write-Verbose -Message $_
    }

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

    $currentInstance = Get-TargetResource @PSBoundParameters
    $BoundParameters = Remove-M365DSCAuthenticationParameter -BoundParameters $PSBoundParameters



    if ($Ensure -eq 'Present' -and $currentInstance.Ensure -eq 'Absent')
    {
        Write-Verbose -Message "Creating {$DisplayName}"
        $BoundParameters.Remove('Assignments') | Out-Null
        $CreateParameters = ([Hashtable]$BoundParameters).clone()
        $CreateParameters = Rename-M365DSCCimInstanceParameter -Properties $CreateParameters

        $CreateParameters.Remove('Id') | Out-Null

        foreach ($key in ($CreateParameters.clone()).Keys)
        {
            if ($CreateParameters[$key].getType().Fullname -like '*CimInstance*')
            {
                $CreateParameters[$key] = Convert-M365DSCDRGComplexTypeToHashtable -ComplexObject $CreateParameters[$key]
            }
        }

        $CreateParameters.add('AdditionalProperties', $AdditionalProperties)
           
        #region resource generator code
        $policy = New-MgBetaDeviceManagementDeviceConfiguration @CreateParameters
        $assignmentsHash = ConvertTo-IntunePolicyAssignment -IncludeDeviceFilter:$true -Assignments $Assignments

        if ($policy.id)
        {
            Update-DeviceConfigurationPolicyAssignment -DeviceConfigurationPolicyId $policy.id `
                -Targets $assignmentsHash `
                -Repository 'deviceManagement/deviceConfigurations'
        }
        #endregion
    }
    elseif ($Ensure -eq 'Present' -and $currentInstance.Ensure -eq 'Present')
    {
        Write-Verbose -Message "Updating {$DisplayName}"
        $BoundParameters.Remove('Assignments') | Out-Null

        $UpdateParameters = ([Hashtable]$BoundParameters).clone()
        $UpdateParameters = Rename-M365DSCCimInstanceParameter -Properties $UpdateParameters

        $UpdateParameters.Remove('Id') | Out-Null

        $keys = (([Hashtable]$UpdateParameters).clone()).Keys
        foreach ($key in $keys)
        {
            if ($null -ne $UpdateParameters.$key -and $UpdateParameters.$key.getType().Name -like '*cimInstance*')
            {
                $UpdateParameters.$key = Convert-M365DSCDRGComplexTypeToHashtable -ComplexObject $UpdateParameters.$key
            }
        }

        if ($UpdateParameters.iosSingleSignOnExtension.count -gt 0)
        {
            $tempHashtable = Convert-ComplexSchema $UpdateParameters.iosSingleSignOnExtension
            $UpdateParameters.Remove('iosSingleSignOnExtension') #this is not in a format Update-MgBetaDeviceManagementDeviceConfiguration will accept
            $UpdateParameters.add('iosSingleSignOnExtension',$tempHashtable) #replaced with the hashtable we created earlier
        }

        if ($UpdateParameters.wallpaperImage.count -gt 0)
        {
            $tempHashtable = Convert-ComplexSchema $UpdateParameters.wallpaperImage
            $UpdateParameters.Remove('wallpaperImage') #this is not in a format Update-MgBetaDeviceManagementDeviceConfiguration will accept
            $UpdateParameters.add('wallpaperImage',$tempHashtable) #replaced with the hashtable we created earlier
        }

        if ($UpdateParameters.contentFilterSettings.count -gt 0)
        {
            $tempHashtable = Convert-ComplexSchema $UpdateParameters.contentFilterSettings
            $UpdateParameters.Remove('contentFilterSettings') #this is not in a format Update-MgBetaDeviceManagementDeviceConfiguration will accept
            $UpdateParameters.add('contentFilterSettings',$tempHashtable) #replaced with the hashtable we created earlier
        }

        if ($UpdateParameters.singleSignOnSettings.count -gt 0)
        {
            $tempHashtable = Convert-ComplexSchema $UpdateParameters.singleSignOnSettings
            $UpdateParameters.Remove('singleSignOnSettings') #this is not in a format Update-MgBetaDeviceManagementDeviceConfiguration will accept
            $UpdateParameters.add('singleSignOnSettings',$tempHashtable) #replaced with the hashtable we created earlier
        }
$UpdateParameters | out-file "C:\dsc-IOSdevFeat\UpdateParameters-BEFORE.txt"
        if ($UpdateParameters.homeScreenPages.count -gt 0)
        {
$UpdateParameters.homeScreenPages |  out-file "C:\dsc-IOSdevFeat\homeScreenPages.txt"
            $tempHashtable = Convert-ComplexSchema $UpdateParameters.homeScreenPages
            $UpdateParameters.Remove('homeScreenPages') #this is not in a format Update-MgBetaDeviceManagementDeviceConfiguration will accept
$tempHashtable | out-file "C:\dsc-IOSdevFeat\tempHASH.txt"
            #$tempHashtable.Add('@odata.type', '#microsoft.graph.iosHomeScreenApp')
            $UpdateParameters.add('homeScreenPages',$tempHashtable) #replaced with the hashtable we created earlier
        }
$UpdateParameters | out-file "C:\dsc-IOSdevFeat\UpdateParameters-AFTER.txt"
        $UpdateParameters.Add('@odata.type', '#microsoft.graph.iosDeviceFeaturesConfiguration')

        #region resource generator code
        Update-MgBetaDeviceManagementDeviceConfiguration  `
            -DeviceConfigurationId $currentInstance.Id `
            -BodyParameter $UpdateParameters
        $assignmentsHash = ConvertTo-IntunePolicyAssignment -IncludeDeviceFilter:$true -Assignments $Assignments
        Update-DeviceConfigurationPolicyAssignment -DeviceConfigurationPolicyId $currentInstance.id `
            -Targets $assignmentsHash `
            -Repository 'deviceManagement/deviceConfigurations'
        #endregion
    }
    elseif ($Ensure -eq 'Absent' -and $currentInstance.Ensure -eq 'Present')
    {
        Write-Verbose -Message "Removing {$DisplayName}"
        #region resource generator code
        Remove-MgBetaDeviceManagementDeviceConfiguration -DeviceConfigurationId $currentInstance.Id
        #endregion
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        #region resource generator code
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
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $airPrintDestinations,

        [Parameter()]
        [System.String]
        $assetTagTemplate,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $contentFilterSettings,

        [Parameter()]
        [System.String]
        $lockScreenFootnote,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $homeScreenDockIcons,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $homeScreenPages,

        [Parameter()]
        [System.Int32]
        $homeScreenGridWidth,

        [Parameter()]
        [System.Int32]
        $homeScreenGridHeight,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $notificationSettings,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $singleSignOnSettings,

        [Parameter()]
        [ValidateSet("notConfigured", "lockScreen", "homeScreen", "lockAndHomeScreens")]
        [System.String]
        $wallpaperDisplayLocation,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $wallpaperImage,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $iosSingleSignOnExtension,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Assignments,
        #endregion

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

    Write-Verbose -Message "Testing configuration of {$id}"

    $CurrentValues = Get-TargetResource @PSBoundParameters
    $ValuesToCheck = ([Hashtable]$PSBoundParameters).clone()

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

        if ($source.GetType().Name -like '*CimInstance*')
        {
            $testResult = Compare-M365DSCComplexObject `
                -Source ($source) `
                -Target ($target)

            if (-not $testResult) { break }

            $ValuesToCheck.Remove($key) | Out-Null
        }
    }

    $ValuesToCheck.Remove('Id') | Out-Null
    $ValuesToCheck = Remove-M365DSCAuthenticationParameter -BoundParameters $ValuesToCheck

    Write-Verbose -Message "Current Values: $(Convert-M365DscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-M365DscHashtableToString -Hashtable $ValuesToCheck)"

    #Convert any DateTime to String
    foreach ($key in $ValuesToCheck.Keys)
    {
        if (($null -ne $CurrentValues[$key]) `
                -and ($CurrentValues[$key].getType().Name -eq 'DateTime'))
        {
            $CurrentValues[$key] = $CurrentValues[$key].toString()
        }
    }

    if ($testResult)
    {
        $testResult = Test-M365DSCParameterState -CurrentValues $CurrentValues `
            -Source $($MyInvocation.MyCommand.Source) `
            -DesiredValues $PSBoundParameters `
            -ValuesToCheck $ValuesToCheck.Keys
    }

    Write-Verbose -Message "Test-TargetResource returned $testResult"

    return $testResult
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

        #region resource generator code
        [array]$getValue = Get-MgBetaDeviceManagementDeviceConfiguration -Filter $Filter -All `
            -ErrorAction Stop | Where-Object `
            -FilterScript { `
                $_.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.iosDeviceFeaturesConfiguration'  `
        }
        #endregion

        $i = 1
        $dscContent = ''
        if ($getValue.Length -eq 0)
        {
            Write-Host $Global:M365DSCEmojiGreenCheckMark
        }
        else
        {
            Write-Host "`r`n" -NoNewline
        }
        foreach ($config in $getValue)
        {
            if ($null -ne $Global:M365DSCExportResourceInstancesCount)
            {
                $Global:M365DSCExportResourceInstancesCount++
            }

            Write-Host "    |---[$i/$($getValue.Count)] $($config.DisplayName)" -NoNewline
            $params = @{
                Id                    = $config.id
                DisplayName           = $config.DisplayName
                Ensure                = 'Present'
                Credential            = $Credential
                ApplicationId         = $ApplicationId
                TenantId              = $TenantId
                ApplicationSecret     = $ApplicationSecret
                CertificateThumbprint = $CertificateThumbprint
                Managedidentity       = $ManagedIdentity.IsPresent
                AccessTokens          = $AccessTokens
            }

            $Results = Get-TargetResource @Params
            $Results = Update-M365DSCExportAuthenticationResults -ConnectionMode $ConnectionMode `
                -Results $Results

            if ($Results.Assignments)
            {
                $complexTypeStringResult = Get-M365DSCDRGComplexTypeToString -ComplexObject $Results.Assignments -CIMInstanceName DeviceManagementConfigurationPolicyAssignments
                if ($complexTypeStringResult)
                {
                    $Results.Assignments = $complexTypeStringResult
                }
                else
                {
                    $Results.Remove('Assignments') | Out-Null
                }
            }

            if ($null -ne $Results.airPrintDestinations)
            {
                $complexTypeStringResult = Get-M365DSCDRGComplexTypeToString `
                    -ComplexObject $Results.airPrintDestinations `
                    -CIMInstanceName 'MSFT_airPrintDestination' 
                if (-Not [String]::IsNullOrWhiteSpace($complexTypeStringResult))
                {
                    $Results.airPrintDestinations = $complexTypeStringResult
                }
                else
                {
                    $Results.Remove('airPrintDestinations') | Out-Null
                }
            }

            if ($null -ne $Results.contentFilterSettings)
            {
                $complexMapping = @(
                    @{
                        Name = 'websiteList'
                        CimInstanceName = 'iosWebContentFilterBase'
                        IsRequired = $false
                    }
                    @{
                        Name = 'specificWebsitesOnly'
                        CimInstanceName = 'iosWebContentFilterBase'
                        IsRequired = $false
                    }
                )
                $complexTypeStringResult = Get-M365DSCDRGComplexTypeToString `
                    -ComplexObject $Results.contentFilterSettings `
                    -CIMInstanceName 'MSFT_iosWebContentFilterSpecificWebsitesAccess' `
                    -ComplexTypeMapping $complexMapping
                if (-Not [String]::IsNullOrWhiteSpace($complexTypeStringResult))
                {
                    $Results.contentFilterSettings = $complexTypeStringResult
                }
                else
                {
                    $Results.Remove('contentFilterSettings') | Out-Null
                }
            }

            if ($null -ne $Results.homeScreenDockIcons)
            {
                $complexTypeStringResult = Get-M365DSCDRGComplexTypeToString `
                    -ComplexObject $Results.homeScreenDockIcons `
                    -CIMInstanceName 'MSFT_iosHomeScreenApp' 
                if (-Not [String]::IsNullOrWhiteSpace($complexTypeStringResult))
                {
                    $Results.homeScreenDockIcons = $complexTypeStringResult
                }
                else
                {
                    $Results.Remove('homeScreenDockIcons') | Out-Null
                }
            }

            if ($null -ne $Results.homeScreenPages)
            {
                $complexMapping = @(
                    @{
                        Name = 'icons'
                        CimInstanceName = 'iosHomeScreenApp'
                        IsRequired = $false
                    }
                )
                $complexTypeStringResult = Get-M365DSCDRGComplexTypeToString `
                    -ComplexObject $Results.homeScreenPages `
                    -CIMInstanceName 'MSFT_iosHomeScreenItem' `
                    -ComplexTypeMapping $complexMapping
                if (-Not [String]::IsNullOrWhiteSpace($complexTypeStringResult))
                {
                    $Results.homeScreenPages = $complexTypeStringResult
                }
                else
                {
                    $Results.Remove('homeScreenPages') | Out-Null
                }
            }

            if ($null -ne $Results.wallpaperImage)
            {
                $complexTypeStringResult = Get-M365DSCDRGComplexTypeToString `
                    -ComplexObject $Results.wallpaperImage `
                    -CIMInstanceName 'MSFT_mimeContent' 
                if (-Not [String]::IsNullOrWhiteSpace($complexTypeStringResult))
                {
                    $Results.wallpaperImage = $complexTypeStringResult
                }
                else
                {
                    $Results.Remove('wallpaperImage') | Out-Null
                }
            }
            
            if ($null -ne $Results.iosSingleSignOnExtension)
            {
                $complexMapping = @(
                    @{
                        Name = 'configurations'
                        CimInstanceName = 'keyStringValuePair'
                        IsRequired = $false
                    }
                )
                $complexTypeStringResult = Get-M365DSCDRGComplexTypeToString `
                    -ComplexObject $Results.iosSingleSignOnExtension `
                    -CIMInstanceName 'MSFT_iosSingleSignOnExtension' `
                    -ComplexTypeMapping $complexMapping
                if (-Not [String]::IsNullOrWhiteSpace($complexTypeStringResult))
                {
                    $Results.iosSingleSignOnExtension = $complexTypeStringResult
                }
                else
                {
                    $Results.Remove('iosSingleSignOnExtension') | Out-Null
                }
            }

            if ($null -ne $Results.notificationSettings)
            {
                $complexTypeStringResult = Get-M365DSCDRGComplexTypeToString `
                    -ComplexObject $Results.notificationSettings `
                    -CIMInstanceName 'MSFT_iosNotificationSettings' 
                if (-Not [String]::IsNullOrWhiteSpace($complexTypeStringResult))
                {
                    $Results.notificationSettings = $complexTypeStringResult
                }
                else
                {
                    $Results.Remove('notificationSettings') | Out-Null
                }
            }

            if ($null -ne $Results.singleSignOnSettings)
            {
                $complexMapping = @(
                    @{
                        Name = 'allowedAppsList'
                        CimInstanceName = 'appListItem'
                        IsRequired = $false
                    }
                )
                $complexTypeStringResult = Get-M365DSCDRGComplexTypeToString `
                    -ComplexObject $Results.singleSignOnSettings `
                    -CIMInstanceName 'MSFT_iosSingleSignOnSettings' `
                    -ComplexTypeMapping $complexMapping
                if (-Not [String]::IsNullOrWhiteSpace($complexTypeStringResult))
                {
                    $Results.singleSignOnSettings = $complexTypeStringResult
                }
                else
                {
                    $Results.Remove('singleSignOnSettings') | Out-Null
                }
            }

            $currentDSCBlock = Get-M365DSCExportContentForResource -ResourceName $ResourceName `
                -ConnectionMode $ConnectionMode `
                -ModulePath $PSScriptRoot `
                -Results $Results `
                -Credential $Credential

            if ($Results.airPrintDestinations)
            {
                $currentDSCBlock = Convert-DSCStringParamToVariable -DSCBlock $currentDSCBlock -ParameterName "airPrintDestinations" -isCIMArray:$True
            }

            if ($Results.contentFilterSettings)
            {
                $currentDSCBlock = Convert-DSCStringParamToVariable -DSCBlock $currentDSCBlock -ParameterName "contentFilterSettings" -isCIMArray:$True
            }

            if ($Results.homeScreenDockIcons)
            {
                $currentDSCBlock = Convert-DSCStringParamToVariable -DSCBlock $currentDSCBlock -ParameterName "homeScreenDockIcons" -isCIMArray:$True
            }

            if ($Results.homeScreenPages)
            {
                $currentDSCBlock = Convert-DSCStringParamToVariable -DSCBlock $currentDSCBlock -ParameterName "homeScreenPages" -isCIMArray:$True
            }

            if ($Results.wallpaperImage)
            {
                $currentDSCBlock = Convert-DSCStringParamToVariable -DSCBlock $currentDSCBlock -ParameterName "wallpaperImage" -isCIMArray:$True
            }

            if ($Results.iosSingleSignOnExtension)
            {
                $currentDSCBlock = Convert-DSCStringParamToVariable -DSCBlock $currentDSCBlock -ParameterName "iosSingleSignOnExtension" -isCIMArray:$True
            }

            if ($Results.notificationSettings)
            {
                $currentDSCBlock = Convert-DSCStringParamToVariable -DSCBlock $currentDSCBlock -ParameterName "notificationSettings" -isCIMArray:$True
            }

            if ($Results.singleSignOnSettings)
            {
                $currentDSCBlock = Convert-DSCStringParamToVariable -DSCBlock $currentDSCBlock -ParameterName "singleSignOnSettings" -isCIMArray:$True
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
        $_.Exception -like "*Request not applicable to target tenant*")
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

function Get-M365DSCAdditionalProperties
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = 'true')]
        [System.Collections.Hashtable]
        $Properties
    )

    $additionalProperties = @(
        'assetTagTemplate'
        'lockScreenFootnote'
        'homeScreenGridWidth'
        'homeScreenGridHeight'
        'wallpaperDisplayLocation'
        'airPrintDestinations'
        'contentFilterSettings'
        'homeScreenDockIcons'
        'homeScreenPages'
        'notificationSettings'
        'singleSignOnSettings'
        'wallpaperImage'
        'iosSingleSignOnExtension'
    )

    $results = @{'@odata.type' = '#microsoft.graph.iosDeviceFeaturesConfiguration' }
    $cloneProperties = $Properties.clone()
    foreach ($property in $cloneProperties.Keys)
    {
        if ($property -in ($additionalProperties) )
        {
            $propertyName = $property[0].ToString().ToLower() + $property.Substring(1, $property.Length - 1)
            if ($properties.$property -and $properties.$property.getType().FullName -like '*CIMInstance*')
            {
                if ($properties.$property.getType().FullName -like '*[[\]]')
                {
                    $array = @()
                    foreach ($item in $properties.$property)
                    {
                        $array += Convert-M365DSCDRGComplexTypeToHashtable -ComplexObject $item
                    }
                    $propertyValue = $array
                }
                else
                {
                    $propertyValue = Convert-M365DSCDRGComplexTypeToHashtable -ComplexObject $properties.$property
                }

            }
            else
            {
                $propertyValue = $properties.$property
            }

            $results.Add($propertyName, $propertyValue)
        }
    }
    if ($results.Count -eq 1)
    {
        return $null
    }
    return $results
}

function Convert-ComplexObjectToHashtableArray {
    param (
        [Parameter()]
        [Object]$InputObject
        
    )

    $resultArray = @()

    foreach ($item in $InputObject) {
        $hashTable = @{}
        
        foreach ($key in $item.Keys) {
            $keyValue = $item.$key
            if ($key -ne '@odata.type')
            {
                if ($keyValue -is [array])
                {
                    $elementTypes = $keyValue | ForEach-Object { $_.GetType().Name }
                    if($elementTypes -contains 'Dictionary`2') #another embedded complex type, not a string array
                    {
                        $keyValue = Convert-ComplexObjectToHashtableArray $keyValue #recurse the function
                    }
                }
                $hashTable.Add($key, $keyValue)
            }
        }
        
        # Add the hash table to the result array only if it contains non-null values       
        if ($hashTable.Values.Where({ $null -ne $_ }).Count -gt 0) {
            $resultArray += $hashTable
        }
    }

    return ,$resultArray
}

function Convert-ComplexSchema {
    param (
        [Parameter()]
        [Object]$InputObject
        
    )
    $Block = $InputObject

    $hashtable = @{}
    $block -split ";" | ForEach-Object {
        if ($_ -match '^(.*?)=(.*)$') {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()
            $hashtable[$key] = $value
        }
    }

    return ,$hashtable
}

Export-ModuleMember -Function *-TargetResource
