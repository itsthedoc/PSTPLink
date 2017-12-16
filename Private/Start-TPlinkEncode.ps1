# Encryption routine for TP-Link and return the byte array

function Start-TPlinkEncode {

[CmdletBinding()]
param (
    # Get the string we need to byte Encode.
    [Parameter(
        Mandatory = $true,
        HelpMessage = 'Body to Encode'
    )]
    [String]$Body
    )

        
    $enc = [system.Text.Encoding]::UTF8
    # Now lets use the encoding method to return the un-encrypted byte array
    $bytes = $enc.GetBytes($Body) 
    # Tplink uses a dummy first 4 bytes so we just pass four 0's back
    for($i = 0; $i -lt 4;$i++){
        write-output 0
    }
    #The first encryption key for the bxor method is 171
    [byte]$key = 171
    # Loop through the byte array then use the next character byte value as the key
    for($i=0; $i -lt $bytes.count ; $i++)
    {
        $a = $key -bxor $bytes[$i]
        $key = $a
        # Return the 'encrypted' byte
        write-output $a
    }
    
}
