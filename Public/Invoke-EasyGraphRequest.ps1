function Invoke-EasyGraphRequest {
    Param
        (
            [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
            [string]$Resource,

            [Parameter(ValueFromPipelineByPropertyName=$true)]
            [ValidateSet('GET','POST','PATCH','PUT','DELETE')]
            $Method = 'GET',

            [Parameter(ValueFromPipelineByPropertyName=$true)]
            [ValidateSet('v1.0','beta')]
            $APIVersion = 'v1.0',

            [Parameter(ValueFromPipelineByPropertyName=$true)]
            $Body,

            [Parameter(ValueFromPipelineByPropertyName=$true)]
            [switch]$All

        )
    begin {
        if (-not $GraphConnection.AccessToken) {
            throw "You must call Connect-ALGraph first"
        }

        if (($GraphConnection.Expires - [DateTime]::UtcNow).TotalSeconds -lt 300) {
            #Token about to expire, renew...
            Write-Verbose "Authentication Token expired, reconnecting..."
            switch ($GraphConnection.AuthType) {
                'Certificate' {
                    Get-EasyGraphAuthTokenCert
                }
                'ClientSecret' {
                    Get-EasyGraphAuthTokenClientSecret
                }
                'DeviceCode' {
                    Get-EasyGraphAuthTokenDeviceCode
                }
            }
        }
    } process {
        $Headers = @{
            Headers = @{
                Authorization = "Bearer $($GraphConnection.AccessToken)"
            }
            Uri = "https://graph.microsoft.com/$APIVersion$Resource"
            ContentType = 'application/json'
            Method = $Method
            Body = $Body | ConvertTo-Json
        }

        do {
            try {
                $res = Invoke-RestMethod @Headers -ErrorAction Stop
                $ResponseStatus = 200 # Assigned manually, since Invoke-RestMethod doesn't handle Response Codes. Anything else than 2xx will trigger try-catch

                if ($res -and ($res.'@odata.context' -and $res.value -or $res.'@odata.nextLink')) {
                    Write-Output $res.value
                } else {
                    Write-Output $res
                }

                if ($All -and $res.'@odata.nextLink') {
                    $Headers.Uri = $res.'@odata.nextLink'
                }

            } catch {
                $ResponseStatus = $_.Exception.Response.StatusCode.value__
                if ($ResponseStatus -eq 429) {
                    if( $_.Exception.Response.Headers -and $_.Exception.Response.Headers.Contains('Retry-After') ) {
                        $RetryInternval = $_.Exception.Response.Headers.GetValues('Retry-After')
                        if($RetryInternval -is [string[]]) {
                            $RetryInternval = [int]$RetryInternval[0]
                        }
                    } else {
                        $RetryInternval = 15
                    }
                    Write-Warning "Requests are throttled, waiting $RetryInternval seconds"
                    Start-Sleep -Seconds $RetryInternval
                } else {
                    throw $_
                }
            }

        } while ($ResponseStatus -eq 429 -or ($All -and $res.'@odata.nextLink'))

        if ($res.'@odata.nextLink' -and -not $All) {
                Write-Warning "More results available, use -All to see all results"
        }
    }
}