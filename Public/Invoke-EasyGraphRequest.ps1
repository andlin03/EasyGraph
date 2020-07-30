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
    Invoke-EasyGraphRequest -Resource '/users' -Method Post -Body $body

.PARAMETER Resource
    Specifies the resource you want to access

.PARAMETER Method
    Specifies the HTTP Method for the request. If no method is specified, a Get request will be sent

.PARAMETER APIVersion
    Specified the version of the Microsoft Graph API you are using. Default is 'v1.0'.

.PARAMETER Body
    Specifies the Body that will be sent in your request. Only required for Post, Patch and Put Methods.

.PARAMETER All
    Overrides the page size settings, and returns all matching results.

.INPUTS
    None

.OUTPUTS
    The data that you requested or the result of the request. The response message can be empty for some requests.
#>
    Param
        (
            [Parameter(Mandatory=$true)]
            [string]$Resource,

            [ValidateSet('Get','Post','Patch','Put','Delete')]
            [string]$Method = 'Get',

            [ValidateSet('v1.0','beta')]
            [string]$APIVersion = 'v1.0',

            [object]$Body,

            [switch]$All
        )
    begin {

        if (($GraphConnection.Expires - [DateTime]::UtcNow).TotalSeconds -lt 300 -or -not $GraphConnection.AccessToken) {
            if ($GraphConnection.AccessToken) {
                Write-Verbose 'Renewing Access Token'
            }
            Get-EasyGraphAuthToken
        }

    } process {
        $Request = @{
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
                $Response = Invoke-RestMethod @Request -ErrorAction Stop
                $ResponseStatus = 200 # Assigned manually, since Invoke-RestMethod doesn't return Response Codes. Anything else than 2xx will trigger try-catch

                if ($Response -and ($Response.'@odata.context' -and $Response.value -or $Response.'@odata.nextLink')) {
                    Write-Output $Response.value
                } else {
                    Write-Output $Response
                }

                if ($All -and $Response.'@odata.nextLink') {
                    $Headers.Uri = $Response.'@odata.nextLink'
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

        } while ($ResponseStatus -eq 429 -or ($All -and $Response.'@odata.nextLink'))

        if ($Response.'@odata.nextLink' -and -not $All) {
            Write-Warning 'More results available, use -All to see all results'
        }
    }
}