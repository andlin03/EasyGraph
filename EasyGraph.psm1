$script:GraphConnection = @{
    TenantId = $null
    AppId = $null
    CertificateThumbprint = $null
    ClientSecret = $null
    AccessToken = $null
    Expires = [DateTime]::UtcNow
    AuthType = $null
    PfxFilePath = $null
    PfxPassword = $null
}

Get-ChildItem -Force -Path $PSScriptRoot -Filter *.ps1 -Recurse | ForEach-Object {
    . $_.FullName
}

Get-ChildItem -Force -Path "$PSScriptRoot\public" -Filter *.ps1 -Recurse | ForEach-Object {
    Export-ModuleMember -Function $_.BaseName
}
