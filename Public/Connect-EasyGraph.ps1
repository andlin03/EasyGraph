function Connect-EasyGraph {
<#
.SYNOPSIS
    Creates an authenticated connection to Microsoft Graph.

.DESCRIPTION
    Creates an authenticated connection to Microsoft Graph. The authentication can be made using a certificate, client secret or device code.

.EXAMPLE
    # Connect using a client certificate
    Connect-EasyGraph -TenantName 'contoso.onmicrosoft.com' -AppId $AppId -CertificateThumbprint $CertificateThumbprint

.EXAMPLE
    # Connect using a client secret
    Connect-EasyGraph -TenantName 'contoso.onmicrosoft.com' -AppId $AppId -ClientSecret $ClientSecret

.EXAMPLE
    # Connect using device code
    Connect-EasyGraph -TenantName 'contoso.onmicrosoft.com' -AppId $AppId -DeviceCode

.EXAMPLE
    # Connect using an Azure Automation Run As Account
    $AzureRunAsConnection = Get-AutomationConnection -Name 'AzureRunAsConnection'
    Connect-EasyGraph @AzureRunAsConnection

.PARAMETER TenantId
    Specifies the name or the id of the Azure AD tenant

.PARAMETER AppId
    Specifies the id of the Azure AD App you are conecting with

.PARAMETER CertificateThumbprint
    The Certificate Thumbprint of a client certificate. The public key of the certificate must be registered in your App Registration.

.PARAMETER ClientSecret
    The Client Secret used to connect. The Secret must be registered in your App Registration.

.PARAMETER DeviceCode
    Denotes that you are connecting with a Device Code.

.INPUTS
    None

.OUTPUTS
    None

.LINK
    Disconnect-EasyGraph
#>
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter','')]

    [CmdletBinding()]
    Param
    (
        [Parameter(ParameterSetName='Certificate',Mandatory=$true)]
        [Parameter(ParameterSetName='ClientSecret',Mandatory=$true)]
        [Parameter(ParameterSetName='DeviceCode',Mandatory=$true)]
        [Alias('TenantName')]
        [string]$TenantId,

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

    $GraphConnection.TenantName = $TenantId
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