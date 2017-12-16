$addresses = '192.168.40.50','192.168.40.51'
[int]$port = 9999 # Should not need to change this as it is hard set

#Commands From https://github.com/softScheck/tplink-smartplug/blob/master/tplink-smarthome-commands.txt

# Get sysinfo, specifically relay state
$Body =  '{"system":{"get_sysinfo":null}}'


# Let's build the Encryption routine for TP-Link and return the byte array
function Encode-ForTPlink {

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

# Lets decrypt the message using the reverse method
function Decode-ForTPlink {

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


function Run-TPLinkCommand {

    param (
    [string]$Body,
    [switch]$Status
    )
    $Tcpclient = New-Object System.Net.Sockets.TcpClient($IP, $port)
    $Stream = $Tcpclient.GetStream()


        
    $ByteReturn = $(Encode-ForTPlink -Body $Body)
    $Stream.write($ByteReturn,0,$ByteReturn.Length)
    $Stream.Flush()

    If($tcpClient.Available -lt 7){
        # As crazy as this sounds, we need to wait for a reply from the switch before responding, otherwise the script terminates before the switch has time to respond
        start-sleep 1
    }

    # Use the below to see if there is any data in the buffer
    $tcpClient.Available
    
    # Lets cretae a variable to get the response back from the plug    
    $bindResponseBuffer = New-Object Byte[] -ArgumentList $tcpClient.Available
    
    

    # Loop through the buffer till we get the full JSON response    
    while ($TCPClient.Connected){
            $Read = $stream.Read($bindResponseBuffer, 0, $bindResponseBuffer.Length)
            if( $Read -eq 0){break}                  
            else{            
                [Array]$Bytesreceived += $bindResponseBuffer[0..($Read -1)]
                [Array]::Clear($bindResponseBuffer, 0, $Read)
            }
     }
    #Write-Output $Bytesreceived
    If( $null -eq $Bytesreceived){
        Write-output "No data received back from the plug"
    }else{
     
        # Now lets store that Encrypted ByteArray so we can clean up the n stack
        
        $ReceivedMessage = $Bytesreceived 
        $Obj = ConvertFrom-Json (Decode-ForTPlink $ReceivedMessage) 
        if ($status) {
        return $Obj.system.get_sysinfo.relay_state
    }
        else {
        #Return $Obj | fl *
        }
    }
    # Clean up the network stack
       
    $Bytesreceived = $null
    $stream.flush()
    $Tcpclient.Dispose()
    $Tcpclient.Close()
    
   }

foreach ($ip in $addresses) {


[ipaddress]$ip = $ip

$status = Run-TPLinkCommand $body -Status
$status = $status[1]

switch ($status) {
0 {
#"true"
$Body = '{"system":{"set_relay_state":{"state":1}}}'
Run-TPLinkCommand $Body
}
1 {
#"False"
$Body = '{"system":{"set_relay_state":{"state":0}}}'
Run-TPLinkCommand $Body
}
}

}