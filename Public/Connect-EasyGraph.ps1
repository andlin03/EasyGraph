function Connect-EasyGraph {

    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter','')]

    [CmdletBinding()]
    Param
    (
        [Parameter(ParameterSetName='Certificate',Mandatory=$true)]
        [Parameter(ParameterSetName='ClientSecret',Mandatory=$true)]
        [Parameter(ParameterSetName='DeviceCode',Mandatory=$true)]
        [Alias('TenantId')]
        [string]$TenantName,

        [Parameter(ParameterSetName='Certificate',Mandatory=$true)]
        [Parameter(ParameterSetName='ClientSecret',Mandatory=$true)]
        [Parameter(ParameterSetName='DeviceCode',Mandatory=$true)]
        [Alias('ApplicationId')]
        [string]$AppId,

        [Parameter(ParameterSetName='Certificate',Mandatory=$true)]
        [Alias('Thumbprint')]
        [string]$CertificateThumbprint,

        # Dummy parameter to be able to use splatting with Azure Automation Connection objects
        [Parameter(ParameterSetName='Certificate',Mandatory=$false,DontShow)]
        [string]$SubscriptionId,

        [Parameter(ParameterSetName='ClientSecret',Mandatory=$true)]
        [string]$ClientSecret,

        [Parameter(ParameterSetName='DeviceCode',Mandatory=$true)]
        [switch]$DeviceCode
    )

    $GraphConnection.TenantName = $TenantName
    $GraphConnection.AppId = $AppId
    $GraphConnection.ClientSecret = $ClientSecret
    $GraphConnection.CertificateThumbprint = $CertificateThumbprint
    $GraphConnection.AuthType = $PSCmdlet.ParameterSetName

    switch ($PSCmdlet.ParameterSetName) {
        'Certificate' {
            Get-EasyGraphAuthTokenCert
        }
        'ClientSecret' {
            Get-EasyGraphAuthTokenClientSecret
        }
        'DeviceCode' {
            Get-EasyGraphAuthTokenDeviceCode
        }
    }
}