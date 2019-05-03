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


Function Test-Px {    
do
    {
        if($env:http_proxy.Length -gt 0)
        {        
            $env:px_server= $env:http_proxy.trimstart("http://")
            Write-Host "Default PROXY ($env:px_server)"
        }
else    {
            Write-Host "No SYSTEM PROXY SETTING detected"
            $env:px_server= Read-Host -Prompt "Enter Enterprise Proxy <IP:port>, <hostname:port> ?"
            Clear-Host        
        }
                                                              
    } while (-not (Connect-Px($env:px_server)))
    return $True
}

Function Get-Rootpw {    
    do
        {
            if($env:rootpw.Length -gt 0)
            {        
                Write-Host "Default root password ($env:rootpw)"
            }
    else    {
                Write-Host "error No root password is set, set it as rootpw in your environment."
                $env:rootpw= Read-Host -Prompt "Enter root password ?"
                Write-Output $env:rootpw | Out-File rootpw
                Write-Host 'Root Password'$env:rootpw
                Clear-Host        
            }
                                                                  
        } while (([string]::IsNullOrEmpty($env:rootpw)))
    }

Function Start-Px ($CHECK) {
    if ($CHECK){
    Clear-Host
    Write-Host "Starting Px Server $env:px_server"    
    $IF=$(Get-DnsClient -ConnectionSpecificSuffix $env:USERDNSDOMAIN).InterfaceIndex

    $env:px_listen=$(Get-NetIPAddress -InterfaceIndex $IF -AddressFamily IPv4).IPAddress

    $env:http_proxy='http://'+$env:px_listen+':3128'

    Write-Host 'Enterprise Proxy'$env:px_server

    Write-Host 'Px Proxy'$env:http_proxy

    $env:px_username=$env:USERDOMAIN+'\'+$env:USERNAME

    Write-Host 'Px username'$env:px_username
    Get-Rootpw
    Start-Process -Verb open -WorkingDirectory px cmd.exe -ArgumentList "/c", "px.exe", "--server=$env:px_server", "--listen=$env:px_listen", "--user=$env:px_username", "--foreground", "--debug"}
    else {Write-Host "Failed to start Px server $env:px_server :("}
}

Function Stop-Px {
    Start-Process -Verb open -WorkingDirectory px px.exe -ArgumentList "--quit"
}

Function BuildPacker {
    Write-Host 'Start Packer Build Tuleap VM'
    Get-Rootpw 
    $env:PACKER_LOG=1
    $env:PACKER_LOG_PATH="packerlog.txt"     
    packer build packerConfig.json
}

Function BuildTuleap {

    Param(
        [switch] $Proxy
    )

    if($Proxy.IsPresent) {
        Write-Host "Build Tuleap Using Proxy"
        Start-Px(Test-Px)
        BuildPacker
        Stop-Px
    } else {
        Write-Host "Proxy is NOT used"
        BuildPacker
    }

}

function Show-Menu
{
    param (
        [string]$Title = 'Tuleap Packer Build'
    )
    Clear-Host
    Write-Host "================ $Title ================"
    
    Write-Host "1: Press '1' Start Packer Build."
    Write-Host "2: Press '2' Start Packer Build Using NTLM Proxy."
    Write-Host "Q: Press 'Q' to quit."
}

do
 {
     Show-Menu
     $selection = Read-Host "Please make a selection"
     switch ($selection)
     {
         '1' {
            BuildTuleap
         } '2' {
            BuildTuleap -Proxy
         }
     }
     pause
 }
 until ($selection -eq 'q')

