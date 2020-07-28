function Get-EasyGraphAuthTokenUserAuth {

    if ($IsLinux -or $IsMacOS) {
        throw 'The selected authentication method is not available on this platform'
    }

    if (-not $GraphConnection.TenantId) {
        $GraphConnection.TenantId = 'common'
    }

    $Resource = 'https://graph.microsoft.com/'
    $RedirectUri = 'https://login.microsoftonline.com/common/oauth2/nativeclient'

    Add-Type -AssemblyName System.Web
    $Query = [System.Web.HttpUtility]::ParseQueryString([string]::Empty)
    $Query.Add('response_type', 'code')
    $Query.Add('client_id', $GraphConnection.AppId)
    $Query.Add('login_hint', $GraphConnection.UserName)
    $Query.Add('redirect_uri', $RedirectUri)
    $Query.Add('resource', $Resource)

    $Url = "https://login.microsoftonline.com/$($GraphConnection.TenantId)/oauth2/authorize?$($Query.ToString())"

    Add-Type -AssemblyName System.Windows.Forms
    $FormProperties = @{
        FormBorderStyle         = [System.Windows.Forms.FormBorderStyle]::FixedDialog
        Width                   = 568
        Height                  = 760
        MinimizeBox             = $false
        MaximizeBox             = $false
        TopMost                 = $true
    }
    $Form = New-Object -TypeName System.Windows.Forms.Form -Property $FormProperties
    $WebBrowserProperties = @{
        Dock                    = [System.Windows.Forms.DockStyle]::Fill
        Url                     = $Url
        ScriptErrorsSuppressed  = $true
    }
    $WebBrowser = New-Object -TypeName System.Windows.Forms.WebBrowser -Property $WebBrowserProperties
    $WebBrowser.Add_DocumentCompleted({$Form.Text=$WebBrowser.Document.Title; if ($WebBrowser.Url.AbsoluteUri -match 'error=[^&]*|code=[^&]*') {$Form.Close()}})
    $Form.Controls.Add($WebBrowser)
    $Form.Add_Shown({$Form.Activate()})
    $Form.ShowDialog() | Out-Null

    $AuthorizationCode = [System.Web.HttpUtility]::ParseQueryString($WebBrowser.Url.Query)['code']

    $WebBrowser.Dispose()
    $Form.Dispose()

    if ($AuthorizationCode) {
        $TokenRequest = @{
            Uri             = "https://login.microsoftonline.com/$($GraphConnection.TenantId)/oauth2/token"
            Method          = 'Post'
            ContentType     = 'application/x-www-form-urlencoded'
            Body = @{
                grant_type      = 'authorization_code'
                redirect_uri    = $RedirectUri
                client_id       = $GraphConnection.AppId
                code            = $AuthorizationCode
                resource        = $Resource
            }
        }

        $TokenResponse = Invoke-RestMethod @TokenRequest

        $GraphConnection.AccessToken = $TokenResponse.access_token
        $GraphConnection.RefreshToken = $TokenResponse.refresh_token
        $GraphConnection.Expires = ([DateTime]::UtcNow).AddSeconds($TokenResponse.expires_in)

        $IdToken = $TokenResponse.id_token | ConvertFrom-JWTtoken
        $GraphConnection.TenantId = $IdToken.tid
        $GraphConnection.UserName = $IdToken.upn

    } else {
        throw 'Authentication canceled'
    }
}