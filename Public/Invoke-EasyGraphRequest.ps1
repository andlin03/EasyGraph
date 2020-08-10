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

.PARAMETER All
    Overrides the page size settings, and returns all matching results.

    This parameter is only valid for output to the pipeline, and cannot be used when the OutFile parameter is also used in the command. Consider increasing the page size with the $top parameter in the Request to return all results instead.

.PARAMETER APIVersion
    Specified the version of the Microsoft Graph API you are using. Default is 'v1.0'.

.PARAMETER Body
    Specifies the Body that will be sent in your request. Only required for Post, Patch and Put Methods.

.PARAMETER ContentType
    Specifies the content type of the request.

    If this parameter is omitted, "application/json" is used.

.PARAMETER Headers
    Specifies the headers of the web request.

.PARAMETER InFile
    Specifies a file with content that will be sent in the request body.

.PARAMETER Method
    Specifies the HTTP Method for the request. If no method is specified, a Get request will be sent

.PARAMETER OutFile
    Saves the response in the specified file. By default, Invoke-EasyGraphRequest returns the results to the pipeline. To send the results to a file and to the pipeline, use the Passthru parameter.

.PARAMETER PassThru
    Returns the results, in addition to writing them to a file. This parameter is valid only when the OutFile parameter is also used in the command.

.PARAMETER Resource
    Specifies the resource you want to access

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
            [hashtable]$Headers,

            [string]$InFile,
            [string]$OutFile,
            [switch]$PassThru,
            [switch]$All,
            [string]$ContentType = 'application/json'
        )
    begin {

        if (($GraphConnection.Expires - [DateTime]::UtcNow).TotalSeconds -lt 300 -or -not $GraphConnection.AccessToken) {
            if ($GraphConnection.AccessToken) {
                Write-Verbose 'Renewing Access Token'
            }
            Get-EasyGraphAuthToken
        }

        if ($ContentType -eq 'application/json') {
            $Body = $Body | ConvertTo-Json
        }

        $Request = @{
            Headers = @{
                Authorization = "Bearer $($GraphConnection.AccessToken)"
            }
            Uri = "https://graph.microsoft.com/$APIVersion$Resource"
            ContentType = $ContentType
            Method = $Method
            Body = $Body
        }

        if ($Headers) {
            $Request.Headers += $Headers
        }

        if ($InFile) {
            $Request.InFile = $InFile
        }

        if ($OutFile -and -not $All) {
            $Request.OutFile = $OutFile
            $Request.PassThru = $PassThru
        }

    } process {

        do {
            try {
                $Response = Invoke-WebRequest @Request -UseBasicParsing -ErrorAction Stop
                $ResponseStatus = $Response.StatusCode

                switch -Regex ($Response.Headers.'Content-Type') {
                    'application/json' {
                        $ResponseContent = $Response.Content | ConvertFrom-Json
                    }
                    default {
                        $ResponseContent = $Response.Content
                    }
                }

                if ($ResponseContent.'@odata.context' -and $ResponseContent.value -is [array]) {
                    Write-Output $ResponseContent.value
                } else {
                    Write-Output $ResponseContent
                }

                if ($All -and $ResponseContent.'@odata.nextLink') {
                    $Request.Uri = $ResponseContent.'@odata.nextLink'
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

        } while ($ResponseStatus -eq 429 -or ($All -and $ResponseContent.'@odata.nextLink'))

        if ($ResponseContent.'@odata.nextLink' -and -not $All) {
            Write-Warning 'More results available, use -All to see all results'
        }
    }
}