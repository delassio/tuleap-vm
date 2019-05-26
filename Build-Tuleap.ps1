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
            Clear-Host
            Write-Host "======== No SYSTEM PROXY SETTING detected ========"
            $env:px_server= Read-Host -Prompt "Enter Enterprise Proxy <IP:port>, <hostname:port> ?"
            Clear-Host        
        }
                                                              
    } while (-not (Connect-Px($env:px_server)))
    return $True
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

    Start-Process -Verb open -WorkingDirectory px cmd.exe -ArgumentList "/c", "px.exe", "--server=$env:px_server", "--listen=$env:px_listen", "--user=$env:px_username", "--foreground", "--debug"}
    else {Write-Host "Failed to start Px server $env:px_server :("}
}

Function Stop-Px {
    Start-Process -Verb open -WorkingDirectory px px.exe -ArgumentList "--quit"
}

Function Set-Rootpw {
    param (
    [string]$Title = 'Password Menu'
)     
    do
        {
            Clear-Host
            Write-Host "========================= $Title ======================="
            Write-Host "======Set Password as rootpw Environment Variable======="
            if($env:rootpw.Length -gt 0)
            {        
            Write-Host "===Default `$env:rootpw ($env:rootpw)==="
            } elseif ([string]::IsNullOrEmpty($env:rootpw)) {
                Write-Host " Press '1' Set Mannually Password."
                Write-Host " Press 'r' Return."
                $selection = Read-Host " No password exist as `$env:rootpw, Default Generate"
                If($selection -eq "r") 
                {
                    Show-packerMenu $Title
                    break
               }
                        switch ($selection)
                                            {
                                                '1' {
                                                    $env:rootpw= Read-Host -Prompt "Enter root password ?"
                                                }
                                                default {
                                                    Write-Host " Generate CentOS password..."
                                                    Write-Host " Set CentOS password for root"
                                                    $password = "!@#$%^&*0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz".tochararray()
                                                    $env:rootpw = ($password | Get-Random -count 8) -join ''
                                                } 
                                            }
            }   
                $centosFile = ".centos_passwd"
                Write-Output "CentOS system user password (root): $env:rootpw"  | Out-File $centosFile
                if ($?) {
                    Write-Host " Adding credentials to $centosFile"}
                    Pause
                    Clear-Host    
        } while (([string]::IsNullOrEmpty($env:rootpw)))
    }
function Show-packerMenu
{
    param (
        [string]$Title = 'Packer Menu'
    )
    do
{
    Clear-Host
    Write-Host "================ $Title ================"
    
    Write-Host " Press '0' CentOS."
    Write-Host " Press '1' Tuleap."
    Write-Host " Press '2' Ldap."
    Write-Host " Press 'r' Return."
    $selection = Read-Host " Press Any Key: Default Packer Build Template"
    If($selection -eq "r") 
    {
        Show-proxyMenu
        break
   }
    switch ($selection)
    {
        '0' {
            #centos
            $TemplateJsonFile="packerConfigCentos.json"
            if (Test-Path $TemplateJsonFile) { Remove-Item $TemplateJsonFile -Force }
            $Json = Get-Content 'packerConfig.json' | Out-String  | ConvertFrom-Json
            
            $Json.provisioners[1].inline = 'chmod -R a+rx /tmp/scripts && /tmp/scripts/yumConf.sh && /tmp/scripts/setHostname.sh && /tmp/scripts/yumUpdateOS.sh'
            $Json.provisioners[1] | Add-Member -Type NoteProperty -Name 'expect_disconnect' -Value 'true'
            
            $TempFile = New-TemporaryFile
            $Json | ConvertTo-Json -depth 32 | Set-Content $TempFile
            Move-Item $TempFile $TemplateJsonFile
            return $TemplateJsonFile
        }
        '1' {
            #tuleap
            $TemplateJsonFile="packerConfigTuleap.json"
            if (Test-Path $TemplateJsonFile) { Remove-Item $TemplateJsonFile -Force }
            $Json = Get-Content 'packerConfig.json' | Out-String  | ConvertFrom-Json
            
            $Json.provisioners += @{}
            $Json.provisioners += @{}
            $TempFile = New-TemporaryFile
            $Json | ConvertTo-Json -depth 32 | Set-Content $TempFile
            $Json = Get-Content $TempFile | Out-String  | ConvertFrom-Json
            
            $Json.provisioners[1].inline = 'chmod -R a+rx /tmp/scripts && /tmp/scripts/yumConf.sh && /tmp/scripts/setHostname.sh && /tmp/scripts/yumUpdateOS.sh'
            $Json.provisioners[1] | Add-Member -Type NoteProperty -Name 'expect_disconnect' -Value 'true'

            $Json.provisioners[2] | Add-Member -Type NoteProperty -Name 'type' -Value 'shell'
            $Json.provisioners[2] | Add-Member -Type NoteProperty -Name 'pause_before' -Value '30s'
            $Json.provisioners[2] | Add-Member -Type NoteProperty -Name 'inline' -Value '/tmp/scripts/yumInstallTuleap.sh'
            
            $Json.provisioners[3] | Add-Member -Type NoteProperty -Name 'type' -Value 'file'
            $Json.provisioners[3] | Add-Member -Type NoteProperty -Name 'direction' -Value 'download'
            $Json.provisioners[3] | Add-Member -Type NoteProperty -Name 'source' -Value '/root/.tuleap_passwd'
            $Json.provisioners[3] | Add-Member -Type NoteProperty -Name 'destination' -Value '.tuleap_passwd'
            
            $Json | ConvertTo-Json -depth 32 | Set-Content $TempFile
            Move-Item $TempFile $TemplateJsonFile
            return $TemplateJsonFile
        } 
        '2' {
            #ldap
            $TemplateJsonFile="packerConfigLdap.json"
            if (Test-Path $TemplateJsonFile) { Remove-Item $TemplateJsonFile -Force }
            $Json = Get-Content 'packerConfig.json' | Out-String  | ConvertFrom-Json

            $Json.provisioners += @{}
            $Json.provisioners += @{}
            $TempFile = New-TemporaryFile
            $Json | ConvertTo-Json -depth 32 | Set-Content $TempFile
            $Json = Get-Content $TempFile | Out-String  | ConvertFrom-Json
            
            $Json.provisioners[1].inline = 'chmod -R a+rx /tmp/scripts && /tmp/scripts/yumConf.sh && /tmp/scripts/setHostname.sh && /tmp/scripts/yumUpdateOS.sh'
            $Json.provisioners[1] | Add-Member -Type NoteProperty -Name 'expect_disconnect' -Value 'true'

            $Json.provisioners[2] | Add-Member -Type NoteProperty -Name 'type' -Value 'shell'
            $Json.provisioners[2] | Add-Member -Type NoteProperty -Name 'pause_before' -Value '30s'
            $Json.provisioners[2] | Add-Member -Type NoteProperty -Name 'inline' -Value '/tmp/scripts/yumInstallTuleap.sh'
            
            $Json.provisioners[3] | Add-Member -Type NoteProperty -Name 'type' -Value 'file'
            $Json.provisioners[3] | Add-Member -Type NoteProperty -Name 'direction' -Value 'download'
            $Json.provisioners[3] | Add-Member -Type NoteProperty -Name 'source' -Value '/root/.tuleap_passwd'
            $Json.provisioners[3] | Add-Member -Type NoteProperty -Name 'destination' -Value '.tuleap_passwd'
            
            $Json | ConvertTo-Json -depth 32 | Set-Content $TempFile
            Move-Item $TempFile $TemplateJsonFile
            return $TemplateJsonFile
        } 
        default {
            return "packerConfig.json"
        }  
    }
    if (([string]::IsNullOrEmpty($selection))) {break}
} until (-not ([string]::IsNullOrEmpty($selection)))
}

function BuildPacker
{
param (
    [string]$Title = 'Packer Menu'
) 

     $Template=Show-packerMenu $Title 
     $env:PACKER_LOG=1
     $env:PACKER_LOG_PATH="packerlog.txt"
     $host.ui.RawUI.WindowTitle = "packer build $Template"
     Set-Rootpw $Title
     Write-Host "Building VMware image..."
     invoke-expression  "packer build $Template"
     Pause
 }


Function BuildProxy {

    Param(
        [switch] $proxy=$false
    )
    if($proxy) {
        Start-Px(Test-Px)
        BuildPacker "Packer Build Tuleap Using Px Proxy"
        Stop-Px
    } elseif (-not $proxy) {
        BuildPacker "Packer Build Tuleap Using Direct Internet"
    }

}

function Show-proxyMenu
{
    param (
        [string]$Title = 'Proxy Menu'
    )

    do
 {
    Clear-Host
    Write-Host "================ $Title ================"
    
    Write-Host " Press 'y' Proxy Internet."
    Write-Host " Press 'x' Exit."

    $selection = Read-Host " Press Any Key: Default Direct Internet."
    If($selection -eq "x") 
    {
        $selection=$null
        break
    }     
     switch ($selection)
     {
         'y' {
            $option = "-proxy"
         } 
     }
     $BuildProxyInvoke = "BuildProxy";
     invoke-expression  "$BuildProxyInvoke $option"
 }
 until (-not ([string]::IsNullOrEmpty($selection)))
}

function BuildTuleap
{
param (
    [string]$Title = 'Tuleap VM Image'
) 

$host.ui.RawUI.WindowTitle=$Title
Show-proxyMenu "Network Proxy Settings"

}

function Cleanup {

    $outputFolder = "output-vmware-iso"
    $tuleapFile = ".tuleap_passwd"
    $centosFile = ".centos_passwd"

	if (Test-Path $outputFolder) {
        if (Test-Path $tuleapFile) { Move-Item $tuleapFile output-vmware-iso }
        if (Test-Path $centosFile) { Move-Item $centosFile output-vmware-iso }
        Move-Item $outputFolder output-vmware-iso-last
    } else 

    {

    if (Test-Path $tuleapFile) {
        Remove-Item $tuleapFile -Force
    }

    if (Test-Path $centosFile) {
        Remove-Item $centosFile -Force
    }
    }
}

Cleanup
Write-Host " Cleanup Password and VM Output Directory."
Pause
BuildTuleap

