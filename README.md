# EasyGraph
EasyGraph is a PowerShell module that simplifies working with [Microsoft Graph](https://docs.microsoft.com/en-us/graph/) from PowerShell. The module manages authentication, paging and throttling without having to fiddle with JSON requests and responses. 

## Get Started!

### Install the module
The EasyGraph module is installed from [PowerShell Gallery](https://www.powershellgallery.com/packages/EasyGraph).
```powershell
Install-Module EasyGraph
```
### Register your App
To use the module you first have to [register your app](https://docs.microsoft.com/en-us/graph/auth-register-app-v2) and [delegate permissions and consents](https://docs.microsoft.com/en-us/azure/active-directory/develop/v2-permissions-and-consent) for the type of requests your script will use. 

For Certificate and Client Secret authentication your app need Application permissions, and for Device Code authentication your app need Delegated permissions.

Device Code authentication also requires that your app has a Redirect URI specified (for example http://localhost or https://login.microsoftonline.com/common/oauth2/nativeclient), and that your App is configured to be treated as a Public Client. 

You can find mor information about [App Registrations in the Microsoft documentation](https://docs.microsoft.com/en-us/azure/active-directory/develop/scenario-desktop-app-registration). 

### Create a certificate
If you plan to use Certificate Authentication you can create a certificate with just a few lines of PowerShell code
```powershell
$CertName = $env:computername
$NotAfter = (Get-Date).AddYears(2) #Create a certificate with two years validity
New-SelfSignedCertificate -DnsName $CertName -CertStoreLocation Cert:\LocalMachine\My -NotAfter $NotAfter
```
After the certificate is created you must export the public key and [upload it to your App](https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal#upload-a-certificate-or-create-a-secret-for-signing-in). 

## Examples
### Connect to Microsoft Graph with DeviceCode
```powershell
Connect-EasyGraph -AppId $AppId -TenantId $TenantId -DeviceCode
```
### Connect with Azure Automation
If you are using Azure Automation for your scripts you can easily use the [Azure Run As Account](https://docs.microsoft.com/en-us/azure/automation/manage-runas-account) to access Microsoft Graph
```powershell
$AzureRunAsConnection = Get-AutomationConnection -Name 'AzureRunAsConnection'
Connect-EasyGraph @AzureRunAsConnection
```
### Get users
https://docs.microsoft.com/en-us/graph/api/user-list
```powershell
Invoke-EasyGraphRequest -Resource '/users'
```
### Get users from the 'beta' endpoint
```powershell
Invoke-EasyGraphRequest -Resource '/users' -APIVersion beta
```
### Get all users with automatic paging
```powershell
Invoke-EasyGraphRequest -Resource '/users' -All
```
### Get the 'Sales' group
https://docs.microsoft.com/en-us/graph/query-parameters
```powershell
$group = Invoke-EasyGraphRequest -Resource '/groups?$filter=displayname eq ''Sales'''
```
### Get members of the 'Sales' group
https://docs.microsoft.com/en-us/graph/api/group-list-members
```powershell
Invoke-EasyGraphRequest -Resource "/groups/$($group.id)/members"
```
### Create a user 
https://docs.microsoft.com/en-us/graph/api/user-post-users
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
Invoke-EasyGraphRequest -Resource '/users' -Method POST -Body $body
```
