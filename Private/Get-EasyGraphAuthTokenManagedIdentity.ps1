function Get-EasyGraphAuthTokenManagedIdentity {
    param()

    $AuthURI = "$($env:IDENTITY_ENDPOINT)?resource=https://graph.microsoft.com/"
    $Headers = @{
        'X-IDENTITY-HEADER' = "$env:IDENTITY_HEADER"
        'Metadata'          = 'True'
    }

    $TokenResponse = Invoke-RestMethod -Method Get -Uri $AuthURI -Headers $Headers

    $GraphConnection.AccessToken = $TokenResponse.access_token
    $GraphConnection.Expires = ([DateTime]"1970-01-01 00:00:00Z").AddSeconds($TokenResponse.expires_on)
}