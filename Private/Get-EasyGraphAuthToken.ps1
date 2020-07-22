function Get-EasyGraphAuthToken {
    param()

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
        Default {
            throw "You must call Connect-EasyGraph first"
        }
    }

}