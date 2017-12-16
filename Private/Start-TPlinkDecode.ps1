# Decrypt TPLink message using the reverse method
function Start-TPlinkDecode {

[CmdletBinding()]
param (
    [Parameter(
        Mandatory = $true,
        HelpMessage = 'Body to Decode'
    )]
    [byte[]]$Body,
    # Include Bytes is really used for debug to show the unencrypted message and the encrypted byte array together.
    [switch]$IncludeBytes = $false
    )
    [byte]$key = 171
    for($i=4; $i -lt $body.count ; $i++)
    {
        $a = $key -bxor $Body[$i]
        $key = $body[$i]
        [string]$origret += "$([string]$a),"
        $return += $([char]$a)
        
    }
  
    Write-Output $return
    if($includeBytes){Write-Output $origret}

}