function Get-EasyGraphAuthTokenManagedIdentity {
    param()

    if (!$env:AZUREPS_HOST_ENVIRONMENT) {
        throw 'The selected authentication method is not available on this platform'
    }

    $AuthURI = "$($env:IDENTITY_ENDPOINT)?resource=https://graph.microsoft.com/"
    $Headers = @{
        'X-IDENTITY-HEADER' = "$env:IDENTITY_HEADER"
        'Metadata'          = 'True'
    }

    if ($GraphConnection.AppId) {
        $Headers += @{
            'client_id' = $GraphConnection.AppId
        }
    }

    $TokenResponse = Invoke-RestMethod -Method Get -Uri $AuthURI -Headers $Headers

    $GraphConnection.AccessToken = $TokenResponse.access_token
    $GraphConnection.Expires = ([DateTime]"1970-01-01 00:00:00Z").AddSeconds($TokenResponse.expires_on)
}