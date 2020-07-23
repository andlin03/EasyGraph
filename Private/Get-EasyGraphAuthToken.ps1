function Get-EasyGraphAuthToken {
    param()

    switch ($GraphConnection.AuthType) {
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
        Default {
            throw "You must call Connect-EasyGraph first"
        }
    }

}