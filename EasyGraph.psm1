$script:GraphConnection = @{}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Get-ChildItem -Force -Path $PSScriptRoot -Filter *.ps1 -Recurse | ForEach-Object {
    . $_.FullName
}

Get-ChildItem -Force -Path ([System.IO.Path]::Combine($PSScriptRoot,'public')) -Filter *.ps1 -Recurse | ForEach-Object {
    Export-ModuleMember -Function $_.BaseName
}

function ConvertFrom-SecureStringAsPlainText {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true)]
        [securestring]$SecureString
    )
    process {
        try {
            [IntPtr]$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
            Write-Output ([System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($BSTR))
        }
        finally {
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
        }
    }
}

function ConvertFrom-JWTtoken {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true)]
        [string]$Token
    )
    process {
        $TokenPayload = $Token.Split(".")[1].Replace('-', '+').Replace('_', '/')
        while ($TokenPayload.Length % 4) { $TokenPayload += "=" }
        [System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String($TokenPayload)) | ConvertFrom-Json
    }
}