function Get-EasyGraphAuthTokenRefreshToken {
    param()

    $AuthURI = "https://login.microsoftonline.com/$($GraphConnection.TenantId)/oauth2/v2.0/token"

    $TokenRequest = @{
        client_id     = $GraphConnection.AppId
        refresh_token = $GraphConnection.RefreshToken
        grant_type    = 'refresh_token'
    }

    try {
        $TokenResponse = Invoke-RestMethod -Method Post -Uri $AuthURI -ContentType 'application/x-www-form-urlencoded' -Body $TokenRequest

        $GraphConnection.AccessToken = $TokenResponse.access_token
        $GraphConnection.RefreshToken = $TokenResponse.refresh_token
        $GraphConnection.Expires = ([DateTime]::UtcNow).AddSeconds($TokenResponse.expires_in)

    } catch {
        Write-Verbose 'Could not acquire access token using refresh token'
        $GraphConnection.RefreshToken = $null
        Get-EasyGraphAuthToken
    }
}