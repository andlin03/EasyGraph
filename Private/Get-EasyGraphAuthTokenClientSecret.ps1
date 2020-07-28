function Get-EasyGraphAuthTokenClientSecret {
    param()

    $AuthURI         = "https://login.microsoftonline.com/$($GraphConnection.TenantId)/oauth2/v2.0/token"

    $TokenRequest = @{
        client_id     = $GraphConnection.AppId
        client_secret = $GraphConnection.ClientSecret | ConvertFrom-SecureStringAsPlainText
        scope         = 'https://graph.microsoft.com/.default'
        grant_type    = 'client_credentials'
    }

    $TokenResponse = Invoke-RestMethod -Method Post -Uri $AuthURI -ContentType 'application/x-www-form-urlencoded' -Body $TokenRequest

    $GraphConnection.AccessToken = $TokenResponse.access_token
    $GraphConnection.Expires = ([DateTime]::UtcNow).AddSeconds($TokenResponse.expires_in)
}