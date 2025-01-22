<#
This example is used to test new resources and showcase the usage of new resources being worked on.
It is not meant to use as a production baseline.
#>

Configuration Example
{
    param
    (
        [Parameter()]
        [System.String]
        $ApplicationId,

        [Parameter()]
        [System.String]
        $TenantId,

        [Parameter()]
        [System.String]
        $CertificateThumbprint
    )
    Import-DscResource -ModuleName Microsoft365DSC

    node localhost
    {
        IntuneAppProtectionPolicyAndroid 'ConfigureAppProtectionPolicyAndroid'
        {
            DisplayName                                        = 'My DSC Android App Protection Policy'
            AllowedDataStorageLocations                        = @('sharePoint')
            AllowedInboundDataTransferSources                  = 'managedApps'
            AllowedOutboundClipboardSharingLevel               = 'managedAppsWithPasteIn'
            AllowedOutboundDataTransferDestinations            = 'managedApps'
            Apps                                               = @('com.cisco.jabberimintune.ios', 'com.pervasent.boardpapers.ios', 'com.sharefile.mobile.intune.ios')
            ContactSyncBlocked                                 = $true # Updated Property
            DataBackupBlocked                                  = $false
            Description                                        = ''
            DeviceComplianceRequired                           = $True
            DisableAppPinIfDevicePinIsSet                      = $True
            FingerprintBlocked                                 = $False
            ManagedBrowserToOpenLinksRequired                  = $True
            MaximumPinRetries                                  = 5
            MinimumPinLength                                   = 4
            OrganizationalCredentialsRequired                  = $false
            PinRequired                                        = $True
            PrintBlocked                                       = $True
            SaveAsBlocked                                      = $True
            SimplePinBlocked                                   = $True
            Ensure                                             = 'Present'
            AllowedDataIngestionLocations                      = @("oneDriveForBusiness","sharePoint","camera");
            AppActionIfAndroidDeviceManufacturerNotAllowed     = "block";
            AppActionIfAndroidDeviceModelNotAllowed            = "block";
            AppActionIfAndroidSafetyNetAppsVerificationFailed  = "block";
            AppActionIfAndroidSafetyNetDeviceAttestationFailed = "block";
            AppActionIfDeviceComplianceRequired                = "block";
            AppActionIfDeviceLockNotSet                        = "block";
            AppActionIfMaximumPinRetriesExceeded               = "block";
            ApprovedKeyboards                                  = @("com.google.android.inputmethod.latin|Gboard - the Google Keyboard","com.touchtype.swiftkey|SwiftKey Keyboard","com.sec.android.inputmethod|Samsung Keyboard","com.google.android.apps.inputmethod.hindi|Google Indic Keyboard","com.google.android.inputmethod.pinyin|Google Pinyin Input","com.google.android.inputmethod.japanese|Google Japanese Input","com.google.android.inputmethod.korean|Google Korean Input","com.google.android.apps.handwriting.ime|Google Handwriting Input","com.google.android.googlequicksearchbox|Google voice typing","com.samsung.android.svoiceime|Samsung voice input","com.samsung.android.honeyboard|Samsung Keyboard","lg keyboard:com.lge.ime|LG Keyboard:com.lge.ime");
            DialerRestrictionLevel                             = "allApps";
            ExemptedAppPackages                                = @("fakestring|fakestring");
            MaximumAllowedDeviceThreatLevel                    = "low";
            MobileThreatDefenseRemediationAction               = "block";
            NotificationRestriction                            = "block";
            ProtectedMessagingRedirectAppType                  = "anyApp";
            RequiredAndroidSafetyNetAppsVerificationType       = "enabled";
            RequiredAndroidSafetyNetDeviceAttestationType      = "basicIntegrityAndDeviceCertification";
            RequiredAndroidSafetyNetEvaluationType             = "basic";
            TargetedAppManagementLevels                        = "unspecified";
            ApplicationId                                      = $ApplicationId;
            TenantId                                           = $TenantId;
            CertificateThumbprint                              = $CertificateThumbprint;
        }
    }
}
