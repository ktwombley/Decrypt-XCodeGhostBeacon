#Copyright 2015 Mayo Foundation for Medical Education and Research
# License: TBD
# Author: Keith Twombley <Twombley.Keith@mayo.edu>

<#
.Synopsis
   Decode the payload of the HTTP POST XCodeGhost sends
.DESCRIPTION
   Get the bytes of the payload from the packet and either pipe it into this cmdlet or specify it as an argument.

   Some error checking is done to ensure you have the whole payload and it's really from XCodeGhost.
.EXAMPLE
   #Use wireshark to export the "HTML Form URL Encoded" portion of the beacon packet to a file named "beacon.raw"

   Get-Content beacon.raw -Encoding byte  | Decrypt-XCodeGhostBeacon
.EXAMPLE
   Decrypt-XCodeGhostBeacon -InputObject $payloadbytes
#>
function Decrypt-XCodeGhostBeacon
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # Cipher Text
        [Parameter(ValueFromPipeline=$true)]
        [byte[]]$InputObject
    )
        
        if($Input.Count -gt 1) {
            $InputObject = @($Input)
        }

        $ErrorActionPreference = "Stop"
        $DES = New-Object System.Security.Cryptography.DESCryptoServiceProvider
        $DES.Mode = "ECB"
        $DES.Key = ([System.Text.Encoding]::UTF8.GetBytes("stringWithFormat"))[0..7]
        $DES.IV = [byte[]] (1..8 | % { 0 } )

        $bodylen = $InputObject[0..3]
        [array]::Reverse($bodylen)
        $bodylen = [bitconverter]::ToInt32($bodylen,0)
        
        $cmdlen = $InputObject[4..5]
        [array]::Reverse($cmdlen)
        $cmdlen = [bitconverter]::ToInt16($cmdlen,0)
        $verlen = $InputObject[6..7]
        [array]::Reverse($verlen)
        $verlen = [bitconverter]::ToInt16($verlen,0)

        if($bodylen -ne $InputObject.Count) {
            throw "Body length $bodylen does not match size of input $($InputObject.Count)"
        }
        if($cmdlen -ne "101") {
            Write-Warning "Unknown cmdLen value $cmdlen. Should be 101."
        }
        if($verlen -ne "10") {
            Write-Warning "Unknown verLen value $verlen. Should be 10."
        }

        $ciphertext = $InputObject[8..$InputObject.Length]


        $decryptor = $DES.CreateDecryptor()
        $mem = New-Object -TypeName System.IO.MemoryStream
        $Streammode = [System.Security.Cryptography.CryptoStreamMode]::Write
        $CryptStream = New-Object -TypeName System.Security.Cryptography.CryptoStream -ArgumentList $mem,$decryptor,$Streammode
        $CryptStream.Write($ciphertext,0,$ciphertext.Length)
        $CryptStream.Dispose()

        [byte[]]$PlainBytes = $mem.ToArray()
        $mem.Dispose()

        $statusTag = [Text.Encoding]::ASCII.GetString($PlainBytes)


        $statusTag
    }


