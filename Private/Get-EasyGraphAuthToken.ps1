function Get-EasyGraphAuthToken {
    param()

    if ($GraphConnection.RefreshToken) {

        Write-Verbose 'Acquiring access token using refresh token'
        Get-EasyGraphAuthTokenRefreshToken

    } else {

        switch ($GraphConnection.AuthType) {
            'UserAuth' {
                Get-EasyGraphAuthTokenUserAuth
            }
            'Thumbprint' {
                Get-EasyGraphAuthTokenCert -CertStore
            }
            'Pfx' {
                Get-EasyGraphAuthTokenCert -Pfx
            }
            'ClientSecret' {
                Get-EasyGraphAuthTokenClientSecret
            }
            'DeviceCode' {
                Get-EasyGraphAuthTokenDeviceCode
            }
            'ManagedIdentity' {
                Get-EasyGraphAuthTokenManagedIdentity
            }
            Default {
                throw 'You must call Connect-EasyGraph first'
            }
        }
    }
}