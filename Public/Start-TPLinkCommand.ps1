function Start-TPLinkCommand {

    param (
    [string]$Body,
    [switch]$Status
    )
    $Tcpclient = New-Object System.Net.Sockets.TcpClient($IP, $port)
    $Stream = $Tcpclient.GetStream()


        
    $ByteReturn = $(Start-TPlinkEncode -Body $Body)
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
        $Obj = ConvertFrom-Json (Start-TPlinkDecode $ReceivedMessage) 
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