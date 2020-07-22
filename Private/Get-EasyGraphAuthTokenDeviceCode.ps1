function Get-EasyGraphAuthTokenDeviceCode {

    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
    param()

    $DeviceCodeRequestParams = @{
        Method = 'POST'
        Uri    = "https://login.microsoftonline.com/$($GraphConnection.TenantId)/oauth2/devicecode"
        Body   = @{
            client_id = $GraphConnection.AppId
            resource  = 'https://graph.microsoft.com/'
        }
    }

    $DeviceCodeRequest = Invoke-RestMethod @DeviceCodeRequestParams
    $DeviceResponseTimeout = $DeviceCodeRequest.expires_in
    Write-Host $DeviceCodeRequest.message -ForegroundColor Yellow

    $TokenRequestParams = @{
        Method = 'POST'
        Uri    = "https://login.microsoftonline.com/$($GraphConnection.TenantId)/oauth2/token"
        Body   = @{
            grant_type = "urn:ietf:params:oauth:grant-type:device_code"
            code       = $DeviceCodeRequest.device_code
            client_id  = $GraphConnection.AppId
        }
    }
    do {
        Start-Sleep -Seconds $DeviceCodeRequest.interval
        $DeviceResponseTimeout -= $DeviceCodeRequest.interval
        try {
            $TokenResponse = Invoke-WebRequest @TokenRequestParams -ErrorAction Stop
            $TokenResponseStatus = $TokenResponse.StatusCode
        } catch {
            $TokenResponseStatus = $_.Exception.Response.StatusCode.value__
        }
    } while ($TokenResponseStatus -eq 400 -and $DeviceResponseTimeout -gt 0)

    if ($TokenResponseStatus -eq 200) {
        $GraphConnection.AccessToken = ($TokenResponse.Content | ConvertFrom-Json).access_token
        $GraphConnection.Expires = ([DateTime]::UtcNow).AddSeconds(($TokenResponse.Content | ConvertFrom-Json).expires_in)
    }
}
