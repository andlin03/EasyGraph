function Invoke-EasyGraphRequest {
<#
.SYNOPSIS
    Invokes a query to Microsoft Graph

.DESCRIPTION
    Invokes a query to Microsoft Graph using the Access Token previously retrieved with Connect-EasyGraph.
    Returns the response from Microsoft Graph, with automatic paging and throttling handling.

.EXAMPLE
    # Lists first page of all user resources
    Invoke-EasyGraphRequest -Resource '/users'

.EXAMPLE
    # Lists all user resources
    Invoke-EasyGraphRequest -Resource '/users' -All

.EXAMPLE
    # Lists all user resources from the 'beta' endpoint
    Invoke-EasyGraphRequest -Resource '/users' -APIVersion beta -All

.EXAMPLE
    # Create a user
    $body = @{
        accountEnabled= $true
        displayName= 'displayName-value'
        mailNickname = 'mailNickname-value'
        userPrincipalName = 'upn-value@tenant-value.onmicrosoft.com'
        passwordProfile = @{
            forceChangePasswordNextSignIn = $true
            password = 'password-value'
        }
    }
    Invoke-EasyGraphRequest -Resource '/users' -Method POST -Body $body

.PARAMETER Resource
    Specifies the resource you want to access

.PARAMETER Method
    Specifies the HTTP Method for the request. If no method is specified, a GET request will be sent

.PARAMETER APIVersion
    Specified the version of the Microsoft Graph API you are using. Default is '1.0'.

.PARAMETER Body
    Specifies the Body that will be sent in your request. Only required for POST, PATCH and PUT Methods.

.PARAMETER All
    Overrides the page size settings, and returns all matching results.

.OUTPUTS
    The data that you requested or the result of the operation. The response message can be empty for some operations.
#>
    Param
        (
            [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
            [string]$Resource,

            [Parameter(ValueFromPipelineByPropertyName=$true)]
            [ValidateSet('GET','POST','PATCH','PUT','DELETE')]
            [string]$Method = 'GET',

            [Parameter(ValueFromPipelineByPropertyName=$true)]
            [ValidateSet('v1.0','beta')]
            [string]$APIVersion = 'v1.0',

            [Parameter(ValueFromPipelineByPropertyName=$true)]
            [object]$Body,

            [Parameter(ValueFromPipelineByPropertyName=$true)]
            [switch]$All

        )
    begin {
        if (-not $GraphConnection.AccessToken) {
            throw "You must call Connect-ALGraph first"

        if (($GraphConnection.Expires - [DateTime]::UtcNow).TotalSeconds -lt 300 -or -not $GraphConnection.AccessToken) {
            Get-EasyGraphAuthToken
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