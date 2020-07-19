function Get-EasyGraphAuthTokenCert {

    param()

    $Certificate = Get-ChildItem -Path "cert:\*\My\$($GraphConnection.CertificateThumbprint)" -Recurse | Select-Object -First 1
    $UTCNow = [int]([DateTime]::UtcNow - (New-Object DateTime 1970,1,1,0,0,0,([DateTimeKind]::Utc))).TotalSeconds

    $JWTHeader = @{
        alg = 'RS256'
        typ = 'JWT'
        x5t = [System.Convert]::ToBase64String($Certificate.GetCertHash()) -replace '\+','-' -replace '/','_' -replace '='
    }

    $JWTPayLoad = @{
        aud = "https://login.microsoftonline.com/$($GraphConnection.TenantName)/oauth2/token"
        exp = $UTCNow+120
        iss = $GraphConnection.AppId
        jti = [guid]::NewGuid()
        nbf = $UTCNow
        sub = $GraphConnection.AppId
    }

    $EncodedHeader = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(($JWTHeader | ConvertTo-Json)))
    $EncodedPayload = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(($JWTPayload | ConvertTo-Json)))

    $JWT = $EncodedHeader + '.' + $EncodedPayload

    $RSAPadding = [Security.Cryptography.RSASignaturePadding]::Pkcs1
    $HashAlgorithm = [Security.Cryptography.HashAlgorithmName]::SHA256

    if (-not $Certificate) {
        throw "Certificate with thumbprint $($GraphConnection.CertificateThumbprint) not found"
    }

    if ($Certificate.HasPrivateKey -and -not $Certificate.PrivateKey) {
        throw "Could not access the certificate private key"
    }

    $Signature = [Convert]::ToBase64String(
        $Certificate.PrivateKey.SignData([System.Text.Encoding]::UTF8.GetBytes($JWT),$HashAlgorithm,$RSAPadding)
    ) -replace '\+','-' -replace '/','_' -replace '='

    $JWT = $JWT + "." + $Signature

    $PostSplat = @{
        ContentType = 'application/x-www-form-urlencoded'
        Method = 'POST'
        Body = @{
            client_id = $GraphConnection.AppId
            client_assertion = $JWT
            client_assertion_type = 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer'
            scope = 'https://graph.microsoft.com/.default'
            grant_type = 'client_credentials'
        }
        Uri = "https://login.microsoftonline.com/$($GraphConnection.TenantName)/oauth2/v2.0/token"
        Headers = @{Authorization = "Bearer $JWT"}
    }

    $Request = Invoke-RestMethod @PostSplat

    $GraphConnection.AccessToken = $Request.access_token
    $GraphConnection.Expires = ([DateTime]::UtcNow).AddSeconds($Request.expires_in)
}