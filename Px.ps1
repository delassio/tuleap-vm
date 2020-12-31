Function Connect-Px($SERVER) {
    if($SERVER.Length -eq 0)
    {
        Write-Host "No input detected"
        return $False
    } 
    elseif ($SERVER.Length -gt 0 )
    { 
                Write-Host "Connecting to $Server ..."
                $HOSTIP, $PORT= $SERVER.split(":")
                if ([string]::IsNullOrEmpty($PORT)) {$PORT="80"}
                if (Test-NetConnection -ComputerName $HOSTIP -Port $PORT -InformationLevel Quiet)
                            {
                                Write-Host "Successfully connected into Enterprise proxy $SERVER... :)"
                                return $True
                            }
                            else 
                            {
                                Write-Host "Failed to connect into $SERVER :("
                                return $False   
                            }
    }
}


Function Find-Px {

    do
    {


    if (Test-Path -path px/px.exe) {
                Test-Px              } 
    else    {
                Write-Host "Please download and copy  Px for Windows into px directory"
                Pause
            }

        } while (-not (Connect-Px($env:px_server)))
        return $True
}


Function Test-Px {    

        if($env:http_proxy.Length -gt 0)
        {        
            $protocol, $server, $port= $env:http_proxy.split(":")
            $env:px_server= $server.trimstart("//")
            Write-Host "Default PROXY ($env:px_server)"
        }
else    {
            Clear-Host
            Write-Host "======== No SYSTEM PROXY SETTING detected ========"
            $env:px_server= Read-Host -Prompt "Enter Proxy server(s) to connect through <IP:port>, <hostname:port> ?"
            Clear-Host        
        }
}

Function Start-Px ($CHECK) {
    Clear-Host
    if ($CHECK){
        
    Write-Host "Starting Px Server $env:px_server"    
    
    $IF=$(Get-NetRoute | ? DestinationPrefix -eq '0.0.0.0/0' | Get-NetIPInterface | Where ConnectionState -eq 'Connected').ifIndex

    $env:px_listen=$(Get-NetIPAddress -InterfaceIndex $IF -AddressFamily IPv4).IPAddress

    $env:ProxyDetected='http://'+$env:px_listen+':3128'

    Write-Host 'Enterprise Proxy'$env:px_server

    Write-Host 'Px Proxy'$env:ProxyDetected

    $env:px_username=$env:USERDOMAIN+'\'+$env:USERNAME

    Write-Host 'Px username'$env:px_username

    Start-Process -Verb open -WorkingDirectory px cmd.exe -ArgumentList "/c", "px.exe", "--server=$env:px_server", "--listen=$env:px_listen", "--user=$env:px_username", "--foreground", "--debug"}
    else {Write-Host "Failed to start Px server $env:px_server :("}
    Pause
    Clear-Host
}

Function Stop-Px {
    Start-Process -Verb open -WorkingDirectory px px.exe -ArgumentList "--quit"
}


Function Add-PXCredential
{
    [string]$result = cmdkey /list:Px
    If($result -match "NONE")
    {
        $userName = $env:USERDOMAIN+'\'+$env:USERNAME
        $userName = $userName.ToLower()
        $Password = Read-Host "Px Password for $userName" -AsSecureString
        If($userName)
        {
            If($Password)
            {
                [string]$result = cmdkey /generic:Px /user:$userName /pass:$Password
            }
            Else
            {
                [string]$result = cmdkey /generic:Px /user:$userName 
            }
            If($result -match "The command line parameters are incorrect")
            {
                Write-Error "Failed to add Windows Credential to Windows vault."
            }
            ElseIf($result -match "CMDKEY: Credential added successfully")
            {
                Write-Host "Credential added successfully."
                return $true
            }
        }
        Else
        {
            Write-Error "username can not be empty,please try again."
            Add-PXCredential
        }
    }
    Else
    {
        Write-Host "Px Generic name already exist."
        return $true
    }

	
}