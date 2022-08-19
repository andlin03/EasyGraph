function Get-EasyGraphConnectionInfo {
    <#
    .SYNOPSIS
        Returns EasyGraph connection information for diagnostic purposes.

    .DESCRIPTION
        Returns EasyGraph connection information for diagnostic purposes.

    .EXAMPLE
        Get-EasyGraphConnectionInfo

    .INPUTS
        None

    .OUTPUTS
        Returns an object with EasyGraph connection information.
    #>

    if ($GraphConnection.AccessToken) {

        [pscustomobject]@{
            AuthType        = $GraphConnection.AuthType
            TenantId        = $GraphConnection.TenantId
            AppId           = $GraphConnection.AppId
            TokenExpiration = $GraphConnection.Expires.ToLocalTime()
            HasRefreshToken = [bool]$GraphConnection.RefreshToken
        }
    }

}