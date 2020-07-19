function Disconnect-EasyGraph {
    $GraphConnection.TenantName = $null
    $GraphConnection.AppId = $null
    $GraphConnection.CertificateThumbprint = $null

    $GraphConnection.AccessToken = $null
    $GraphConnection.Expires = [DateTime]::UtcNow
}