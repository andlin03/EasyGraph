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

### Connect

```powershell
# With regular login prompt 
Connect-EasyGraph -AppId $AppId
```

```powershell
# Specify user for Single sign-on (when applicable)
Connect-EasyGraph -AppId $AppId -UserPrincipalName 'user@contoso.onmicrosoft.com'
```

```powershell
# Connect with Device Code
Connect-EasyGraph -AppId $AppId -TenantId $TenantId -DeviceCode
```

```powershell
# Connect with a certificate in the Windows Certificate Store
Connect-EasyGraph -AppId $AppId -TenantId $TenantId -CertificateThumbprint $Certificate.Thumbprint
```

```powershell
# Connect with Azure Automation RunAs Account
$AzureRunAsConnection = Get-AutomationConnection -Name 'AzureRunAsConnection'
Connect-EasyGraph @AzureRunAsConnection
```

### API Requests

```powershell
# Get all users: https://docs.microsoft.com/en-us/graph/api/user-list
Invoke-EasyGraphRequest -Resource '/users'
```

```powershell
# Get users from the 'beta' endpoint: https://docs.microsoft.com/en-us/graph/use-the-api#version
Invoke-EasyGraphRequest -Resource '/users' -APIVersion beta
```

```powershell
# Get all users with automatic paging: https://docs.microsoft.com/en-us/graph/paging
Invoke-EasyGraphRequest -Resource '/users' -All
```

```powershell
# Get the 'Sales' group using filter parameter: https://docs.microsoft.com/en-us/graph/query-parameters
$group = Invoke-EasyGraphRequest -Resource '/groups?$filter=displayName eq ''Sales'''
```

```powershell
# Get members of the 'Sales' group: https://docs.microsoft.com/en-us/graph/api/group-list-members
Invoke-EasyGraphRequest -Resource "/groups/$($group.id)/members"
```

```powershell
# Create a user: https://docs.microsoft.com/en-us/graph/api/user-post-users
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

```powershell
# Update profile photo: https://docs.microsoft.com/en-us/graph/api/profilephoto-update
Invoke-EasyGraphRequest -Resource '/me/photo/$value' -Method Patch -InFile .\photo.jpg -ContentType 'image/jpeg'
```

```powershell
# Upload file to OneDrive: https://docs.microsoft.com/en-us/graph/api/driveitem-put-content
Invoke-EasyGraphRequest -Resource '/me/drive/root:/workbook.xlsx:/content' -Method Put -InFile .\workbook.xlsx -ContentType 'application/octet-stream'
```

```powershell
# Download file from OneDrive: https://docs.microsoft.com/en-us/graph/api/driveitem-get-content
Invoke-EasyGraphRequest -Resource '/me/drive/root:/workbook.xlsx:/content' -OutFile .\workbook.xlsx
```

### Disconnect session

```powershell
Disconnect-EasyGraph
```

## Issues, Requests, Bugs

Please submit via the [Issues](https://github.com/andlin03/EasyGraph/issues) link.

## Changelog

The change log is maintained in the [Releases](https://github.com/andlin03/EasyGraph/releases) section of GitHub.
