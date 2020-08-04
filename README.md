# EasyGraph

EasyGraph is a cross-platform PowerShell module that simplifies working with [Microsoft Graph](https://docs.microsoft.com/en-us/graph/) from PowerShell. The module manages authentication, paging and throttling without having to fiddle with JSON requests and responses.
The EasyGraph module is designed for use in unattended scripts, and supports [Azure Automation](https://azure.microsoft.com/en-us/services/automation/).

Supported authentication methods:

* Certificate based authentication with thumbprint (Windows only)
* Certificate based authentication with Pfx file
* Username and password (Windows only)
* Client credentials
* Device Code

## Get Started

### Install the module

The EasyGraph module is installed from [PowerShell Gallery](https://www.powershellgallery.com/packages/EasyGraph).

```powershell
Install-Module -Name EasyGraph
```

### Register your App

To use the module you first have to [register your app](https://docs.microsoft.com/en-us/graph/auth-register-app-v2) in Azure AD and [delegate permissions and consents](https://docs.microsoft.com/en-us/azure/active-directory/develop/v2-permissions-and-consent) for the type of requests your script will use.

For Certificate and Client Secret authentication your App need Application permissions, and for User and Device Code authentication your App need Delegated permissions.

Delegated authentication also requires that your App has a Redirect URI specified (for example <https://login.microsoftonline.com/common/oauth2/nativeclient>), and Device Code authentication requires that your Default client type is set to Public Client.

You can find more information about [App Registrations in the Microsoft documentation](https://docs.microsoft.com/en-us/azure/active-directory/develop/scenario-desktop-app-registration).

### Create a certificate

If you plan to use Certificate Authentication you can create a certificate with just a few lines of PowerShell code

```powershell
$Params = @{
    NotBefore         = Get-Date
    NotAfter          = (Get-Date).AddYears(2)   #Create a certificate with two years validity
    DnsName           = $env:computername
    CertStoreLocation = 'Cert:\LocalMachine\My'
    Provider          = 'Microsoft Enhanced RSA and AES Cryptographic Provider'
}
$Certificate = New-SelfSignedCertificate @Params
```

After the certificate is created you must export the public key and [upload it to your App](https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal#upload-a-certificate-or-create-a-secret-for-signing-in).

## Examples

### Connect with username and password

```powershell
# Without specifying user
Connect-EasyGraph -AppId $AppId
```
```powershell
# Specify user for Single sign-on (when applicable)
Connect-EasyGraph -AppId $AppId -UserPrincipalName 'user@contoso.onmicrosoft.com'
```

### Connect with DeviceCode

```powershell
Connect-EasyGraph -AppId $AppId -TenantId $TenantId -DeviceCode
```

### Connect with a certificate in the Windows Certificate Store

```powershell
Connect-EasyGraph -AppId $AppId -TenantId $TenantId -CertificateThumbprint $Certificate.Thumbprint
```

### Connect with Azure Automation

If you are using Azure Automation for your scripts you can use the [Azure Run As Account](https://docs.microsoft.com/en-us/azure/automation/manage-runas-account) to access Microsoft Graph

```powershell
$AzureRunAsConnection = Get-AutomationConnection -Name 'AzureRunAsConnection'
Connect-EasyGraph @AzureRunAsConnection
```

### Get users

<https://docs.microsoft.com/en-us/graph/api/user-list>

```powershell
Invoke-EasyGraphRequest -Resource '/users'
```

### Get users from the 'beta' endpoint

<https://docs.microsoft.com/en-us/graph/use-the-api#version>

```powershell
Invoke-EasyGraphRequest -Resource '/users' -APIVersion beta
```

### Get all users with automatic paging

<https://docs.microsoft.com/en-us/graph/paging>

```powershell
Invoke-EasyGraphRequest -Resource '/users' -All
```

### Get the 'Sales' group using filter parameter

<https://docs.microsoft.com/en-us/graph/query-parameters>

```powershell
$group = Invoke-EasyGraphRequest -Resource '/groups?$filter=displayName eq ''Sales'''
```

### Get members of the 'Sales' group

<https://docs.microsoft.com/en-us/graph/api/group-list-members>

```powershell
Invoke-EasyGraphRequest -Resource "/groups/$($group.id)/members"
```

### Create a user

<https://docs.microsoft.com/en-us/graph/api/user-post-users>

```powershell
$body = @{
    accountEnabled = $true
    displayName = 'displayName-value'
    mailNickname = 'mailNickname-value'
    userPrincipalName = 'upn-value@tenant-value.onmicrosoft.com'
    passwordProfile = @{
        forceChangePasswordNextSignIn = $true
        password = 'password-value'
    }
}
Invoke-EasyGraphRequest -Resource '/users' -Method Post -Body $body
```

### Disconnect session

```powershell
Disconnect-EasyGraph
```

## Issues, Requests, Bugs

Please submit via the [Issues](https://github.com/andlin03/EasyGraph/issues) link.

## Changelog

The change log is maintained in the [Releases](https://github.com/andlin03/EasyGraph/releases) section of GitHub.
