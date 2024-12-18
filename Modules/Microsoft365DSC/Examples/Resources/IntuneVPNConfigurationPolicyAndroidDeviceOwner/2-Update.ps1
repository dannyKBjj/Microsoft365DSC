<#
This example is used to test new resources and showcase the usage of new resources being worked on.
It is not meant to use as a production baseline.
#>

Configuration Example
{
    param(
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
        IntuneVPNConfigurationPolicyAndroidDeviceOwner "IntuneVPNConfigurationPolicyAndroidDeviceOwner-Example"
        {
            ApplicationId                       = $ApplicationId;
            TenantId                            = $TenantId;
            CertificateThumbprint               = $CertificateThumbprint;
            Assignments                         = @();
            authenticationMethod                = "usernameAndPassword";
            connectionName                      = "IntuneVPNConfigurationPolicyAndroidDeviceOwner ConnectionName";
            connectionType                      = "ciscoAnyConnect";
            Description                         = "IntuneVPNConfigurationPolicyAndroidDeviceOwner Description";
            DisplayName                         = "IntuneVPNConfigurationPolicyAndroidDeviceOwner DisplayName";
            Ensure                              = "Present";
            Id                                  = "12345678-1234-abcd-1234-12345678ABCD";
            servers                             = @(
                MSFT_MicrosoftGraphvpnServer{
                    isDefaultServer             = $True
                    description                 = 'server'
                    address                     = 'vpn.newAddress.com' #updated VPN address
                }
            );
        }
    }
}
