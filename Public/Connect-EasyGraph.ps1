﻿function Connect-EasyGraph {
<#
.SYNOPSIS
    Creates an authenticated connection to Microsoft Graph.

.DESCRIPTION
    Creates an authenticated connection to Microsoft Graph. The authentication can be made using a certificate, client secret or device code.

.PARAMETER TenantId
    Specifies the name or the id or name of the Azure AD tenant.

.PARAMETER AppId
    Specifies the id of the Azure AD App you are conecting with.

.PARAMETER CertificateThumbprint
    The Certificate Thumbprint of a client certificate. The public key of the certificate must be registered in your App.

.PARAMETER ClientSecret
    The Client Secret used to connect. The Secret must be registered in your App.

.PARAMETER DeviceCode
    Denotes that you are connecting with a Device Code.

.PARAMETER ManagedIdentity
    Denotes that you are connecting with Azure Managed Identities.

.PARAMETER PfxFilePath
    The full path to the Pfx file you are authenticating with. The public key of the certificate must be registered in your App.

.PARAMETER PfxPassword
    The password of the Pfx certificate.

.EXAMPLE
    # Connect with username and password
    Connect-EasyGraph -AppId $AppId
    Connect-EasyGraph -AppId $AppId -UserPrincipalName user@contoso.onmicrosoft.com

.EXAMPLE
    # Connect using a client certificate
    Connect-EasyGraph -TenantId 'contoso.onmicrosoft.com' -AppId $AppId -CertificateThumbprint $CertificateThumbprint

.EXAMPLE
    # Connect using a client secret
    Connect-EasyGraph -TenantId 'contoso.onmicrosoft.com' -AppId $AppId -ClientSecret $ClientSecret

.EXAMPLE
    # Connect using device code
    Connect-EasyGraph -TenantId 'contoso.onmicrosoft.com' -AppId $AppId -DeviceCode

.EXAMPLE
    # Connect using an Azure Managed Identity
    Connect-EasyGraph -ManagedIdentity

.EXAMPLE
    # Connect using an Azure Automation Run As Account
    $AzureRunAsConnection = Get-AutomationConnection -Name 'AzureRunAsConnection'
    Connect-EasyGraph @AzureRunAsConnection

.EXAMPLE
    # Connect using a pfx file
    Connect-EasyGraph -TenantId 'contoso.onmicrosoft.com' -AppId $AppId -PfxFilePath 'c:\cert.pfx' -PfxPassword (ConvertTo-Securestring -AsPlainText '1234' -Force)

.INPUTS
    None

.OUTPUTS
    None

.LINK
    Disconnect-EasyGraph
#>
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter','')]

    [CmdletBinding(DefaultParameterSetName='UserAuth')]
    Param
    (
        [Parameter(ParameterSetName='UserAuth',Mandatory=$false)]
        [Parameter(ParameterSetName='Thumbprint',Mandatory=$true)]
        [Parameter(ParameterSetName='ClientSecret',Mandatory=$true)]
        [Parameter(ParameterSetName='DeviceCode',Mandatory=$true)]
        [Parameter(ParameterSetName='Pfx',Mandatory=$true)]
        [Alias('TenantName','Organization')]
        [string]$TenantId,

        [Parameter(ParameterSetName='UserAuth',Mandatory=$true)]
        [Parameter(ParameterSetName='Thumbprint',Mandatory=$true)]
        [Parameter(ParameterSetName='ClientSecret',Mandatory=$true)]
        [Parameter(ParameterSetName='DeviceCode',Mandatory=$true)]
        [Parameter(ParameterSetName='Pfx',Mandatory=$true)]
        [Parameter(ParameterSetName='ManagedIdentity',Mandatory=$false)]
        [Alias('ApplicationId','ClientId')]
        [guid]$AppId,

        [Parameter(ParameterSetName='UserAuth',Mandatory=$false)]
        [Alias('UserName')]
        [string]$UserPrincipalName,

        [Parameter(ParameterSetName='Thumbprint',Mandatory=$true)]
        [Alias('Thumbprint')]
        [string]$CertificateThumbprint,

        [Parameter(ParameterSetName='Pfx',Mandatory=$true)]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [System.IO.FileInfo]$PfxFilePath,

        [Parameter(ParameterSetName='Pfx',Mandatory=$true)]
        [securestring]$PfxPassword,

        # Dummy parameter to be able to use splatting with Azure Automation Connection objects
        [Parameter(ParameterSetName='Thumbprint',Mandatory=$false,DontShow)]
        [guid]$SubscriptionId,

        [Parameter(ParameterSetName='ClientSecret',Mandatory=$true)]
        [securestring]$ClientSecret,

        [Parameter(ParameterSetName='DeviceCode',Mandatory=$true)]
        [switch]$DeviceCode,

        [Parameter(ParameterSetName='ManagedIdentity',Mandatory=$true)]
        [switch]$ManagedIdentity
    )

    Disconnect-EasyGraph

    $GraphConnection.TenantId = $TenantId
    $GraphConnection.AppId = $AppId
    $GraphConnection.ClientSecret = $ClientSecret
    $GraphConnection.CertificateThumbprint = $CertificateThumbprint
    $GraphConnection.AuthType = $PSCmdlet.ParameterSetName
    $GraphConnection.UserName = $UserPrincipalName
    if ($PfxFilePath) {
        $GraphConnection.PfxFilePath = Resolve-Path -Path $PfxFilePath
        $GraphConnection.PfxPassword = $PfxPassword
    }

    Get-EasyGraphAuthToken
}