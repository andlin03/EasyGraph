function Get-EasyGraphAuthTokenClientSecret {
    param()

    $AuthURI         = "https://login.microsoftonline.com/$($GraphConnection.TenantName)/oauth2/v2.0/token"

    $TokenRequestBody = @{
        client_id     = $GraphConnection.AppId
        client_secret = $GraphConnection.ClientSecret
        scope         = "https://graph.microsoft.com/.default"
        grant_type    = "client_credentials"
    }

    $tokenRequest = Invoke-RestMethod -Method Post -Uri $AuthURI -ContentType 'application/x-www-form-urlencoded' -Body $TokenRequestBody

    $GraphConnection.AccessToken = $tokenRequest.access_token
    $GraphConnection.Expires = ([DateTime]::UtcNow).AddSeconds($tokenRequest.expires_in)
}