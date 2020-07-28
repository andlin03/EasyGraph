function Get-EasyGraphAuthTokenDeviceCode {

    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
    param()

    $DeviceCodeRequest = @{
        Method = 'POST'
        Uri    = "https://login.microsoftonline.com/$($GraphConnection.TenantId)/oauth2/devicecode"
        Body   = @{
            client_id = $GraphConnection.AppId
            resource  = 'https://graph.microsoft.com/'
        }
    }

    $DeviceCodeResponse = Invoke-RestMethod @DeviceCodeRequest
    $DeviceCodeTimeout = $DeviceCodeResponse.expires_in
    Write-Host $DeviceCodeResponse.message -ForegroundColor Yellow

    $TokenRequest = @{
        Method = 'POST'
        Uri    = "https://login.microsoftonline.com/$($GraphConnection.TenantId)/oauth2/token"
        Body   = @{
            grant_type = 'urn:ietf:params:oauth:grant-type:device_code'
            code       = $DeviceCodeResponse.device_code
            client_id  = $GraphConnection.AppId
        }
    }
    do {
        Start-Sleep -Seconds $DeviceCodeResponse.interval
        $DeviceCodeTimeout -= $DeviceCodeResponse.interval
        try {
            $TokenResponseRaw = Invoke-WebRequest @TokenRequest -ErrorAction Stop
            $TokenResponseStatus = $TokenResponseRaw.StatusCode
        } catch {
            $TokenResponseStatus = $_.Exception.Response.StatusCode.value__
        }
    } while ($TokenResponseStatus -eq 400 -and $DeviceCodeTimeout -gt 0)

    if ($DeviceCodeTimeout -le 0) {
        throw 'Device Code authentication timed out'
    }

    if ($TokenResponseStatus -eq 200) {
        $TokenResponse = $TokenResponseRaw.Content | ConvertFrom-Json
        $GraphConnection.AccessToken = $TokenResponse.access_token
        $GraphConnection.RefreshToken = $TokenResponse.refresh_token
        $GraphConnection.Expires = ([DateTime]::UtcNow).AddSeconds($TokenResponse.expires_in)

        $IdToken = $TokenResponse.id_token | ConvertFrom-JWTtoken
        $GraphConnection.TenantId = $IdToken.tid
        $GraphConnection.UserName = $IdToken.upn

    } else {
        throw 'Unexpected authentication error'
    }
}
