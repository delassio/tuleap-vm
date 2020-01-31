# Import Px Proxy Server Function

# region Include required files
#
$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
try {
    . ("$ScriptDirectory\ProxyServer.ps1")
}
catch {
    Write-Host "Error while loading supporting PowerShell Scripts" 
}
#endregion

Function Set-Rootpw {
    param (
    [string]$ImageName 
)     
    do
        {
            Clear-Host
            Write-Host "========================= $ImageName ======================="
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
                    New-Template $ImageName
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
                                                    $env:rootpw = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 8 | ForEach-Object {[char]$_})
                                                } 
                                            }
            }   
                $rootpwFile = ".rootpw_${ImageName}"
                Write-Output "CentOS system user password (root): $env:rootpw"  | Out-File $rootpwFile
                if ($?) {
                    Write-Host " Adding credentials to $rootpwFile"}
                    Move-Item -path $rootpwFile -Destination $ImageName
                    Pause
                    Clear-Host    
        } while (([string]::IsNullOrEmpty($env:rootpw)))
    }

    Function New-MachineImage {
        param (
        [string]$MachineImage
    )     
        do
            {
                Clear-Host
                Write-Host "========================= New Machine Image Menu ======================="
                Write-Host "======New VM Directory================"
                    Write-Host " Press '1' Mannually: $MachineImage-<XXX>"
                    Write-Host " Press 'r' Return."
                    $selection = Read-Host " Default Generate:"
                            switch ($selection)
                                                {
                                                    '1' {
                                                        $env:rootpw= Read-Host -Prompt "Enter root password ?"
                                                    }
                                                    default {
                                                        Write-Host " Generate VM Name..."
                                                        Write-Host " Set Name for VM"
                                                        $Id = -join ((65..90) | Get-Random -Count 3 | ForEach-Object {[char]$_})
                                                        return "$MachineImage-$Id".ToUpperInvariant()
                                                    } 
                                                }  
                        Pause
                        Clear-Host    
            } while (-not ([string]::IsNullOrEmpty($selection)))
        }
function New-Template
{
    param (
        [string]$Title = 'Edit Packer Menu'
    )
    do
{
    Clear-Host
    Write-Host "================ $Title ================"
    
    Write-Host " Press '0' CentOS."
    Write-Host " Press '1' Tuleap."
    Write-Host " Press '2' Ldap."
    Write-Host " Press '3' Oracle Linux 7."
    Write-Host " Press 'r' Return."
    $selection = Read-Host " Press Any Key: Default Packer Build Template"
    If($selection -eq "r") 
    {
        Show-proxyMenu
        break
   }
            $InlineScriptPermission="chmod -R a+rx /tmp" 
            $InlineScriptProxy="/tmp/linux/yumConf.sh `"{{user ``proxy``}}`" "
            $InlineScriptUpdateOS="/tmp/linux/yumUpdateOS.sh"
            $InlineScriptHostname="/tmp/linux/setHostname.sh `"{{user ``hostname``}}`" `"{{user ``dnsuffix``}}`" "            
            $InlineScriptTuleap="/tmp/tuleap/yumInstallTuleap.sh"
            $InlineScriptTuleapLdap="/tmp/tuleap/ldapPlugin.sh"
            
            $ImageName=New-MachineImage "Image_VM"
            Write-Host "ImageName $ImageName "
            $TemplateJsonFile = "packer_templates\Template.json"
            $NewTemplateJsonFile = "${ImageName}.json"
            $Json = Get-Content $TemplateJsonFile | Out-String  | ConvertFrom-Json

    switch ($selection)
    {
        '0' {
            $Json.variables.Hostname="CentOS${ImageName}"
            $Json.provisioners[1].inline = "$InlineScriptPermission && $InlineScriptProxy && $InlineScriptHostname && $InlineScriptUpdateOS"
            $Json.provisioners[1] | Add-Member -Type NoteProperty -Name 'expect_disconnect' -Value 'true'
        }
        '1' {
            $Json.variables.Hostname="Tuleap${ImageName}"            
            $Json.provisioners += @{}
            $Json.provisioners += @{}
            $TempFile = New-TemporaryFile
            $Json | ConvertTo-Json -depth 32 | Set-Content $TempFile
            $Json = Get-Content $TempFile | Out-String  | ConvertFrom-Json
            
            $Json.provisioners[1].inline = "$InlineScriptPermission && $InlineScriptProxy && $InlineScriptHostname && $InlineScriptUpdateOS"
            $Json.provisioners[1] | Add-Member -Type NoteProperty -Name 'expect_disconnect' -Value 'true'

            $Json.provisioners[2] | Add-Member -Type NoteProperty -Name 'type' -Value 'shell'
            $Json.provisioners[2] | Add-Member -Type NoteProperty -Name 'pause_before' -Value '30s'
            $Json.provisioners[2] | Add-Member -Type NoteProperty -Name 'inline' -Value $InlineScriptTuleap
            
            $Json.provisioners[3] | Add-Member -Type NoteProperty -Name 'type' -Value 'file'
            $Json.provisioners[3] | Add-Member -Type NoteProperty -Name 'direction' -Value 'download'
            $Json.provisioners[3] | Add-Member -Type NoteProperty -Name 'source' -Value '/root/.tuleap_passwd'
            $Json.provisioners[3] | Add-Member -Type NoteProperty -Name 'destination' -Value '.tuleap_passwd'
        } 
        '2' {
            $Json.variables.Hostname="Tuleap_LDAP${ImageName}"
            $Json.provisioners += @{}
            $Json.provisioners += @{}
            $TempFile = New-TemporaryFile
            $Json | ConvertTo-Json -depth 32 | Set-Content $TempFile
            $Json = Get-Content $TempFile | Out-String  | ConvertFrom-Json
            
            $Json.provisioners[1].inline = "$InlineScriptPermission && $InlineScriptProxy && $InlineScriptHostname && $InlineScriptUpdateOS"
            $Json.provisioners[1] | Add-Member -Type NoteProperty -Name 'expect_disconnect' -Value 'true'

            $Json.provisioners[2] | Add-Member -Type NoteProperty -Name 'type' -Value 'shell'
            $Json.provisioners[2] | Add-Member -Type NoteProperty -Name 'pause_before' -Value '30s'
            $Json.provisioners[2] | Add-Member -Type NoteProperty -Name 'inline' -Value "$InlineScriptTuleap && $InlineScriptTuleapLdap"
            
            $Json.provisioners[3] | Add-Member -Type NoteProperty -Name 'type' -Value 'file'
            $Json.provisioners[3] | Add-Member -Type NoteProperty -Name 'direction' -Value 'download'
            $Json.provisioners[3] | Add-Member -Type NoteProperty -Name 'source' -Value '/root/.tuleap_passwd'
            $Json.provisioners[3] | Add-Member -Type NoteProperty -Name 'destination' -Value '.tuleap_passwd'
        }
        '3' {
            $Json.variables.Hostname="OracleLinux${ImageName}"
            $Json.provisioners[1].inline = "$InlineScriptPermission && $InlineScriptProxy && $InlineScriptHostname && $InlineScriptUpdateOS"
            $Json.provisioners[1] | Add-Member -Type NoteProperty -Name 'expect_disconnect' -Value 'true'
        } 
        default {        
        }  
    }
    $TempFile = New-TemporaryFile
    $Json | ConvertTo-Json -depth 32 | Set-Content $TempFile
    Move-Item $TempFile $NewTemplateJsonFile
    return @($ImageName,$NewTemplateJsonFile)

    if (([string]::IsNullOrEmpty($selection))) {break}
} until (-not ([string]::IsNullOrEmpty($selection)))
}

function CleanupPackage {

    param (
        [string]$ImageNameDirectory
    )
    
    $outputFolder = "output-vmware-iso"
    $newoutputFolder = "output-${ImageNameDirectory}"
    
    Clear-Host
    Write-Host "======================== Cleanup & Package ==========================="

	if (Test-Path $outputFolder) {
        Move-Item $outputFolder $newoutputFolder -Force
        Move-Item -path $newoutputFolder -Destination $ImageNameDirectory
    } 
}

function BuildPacker
{
param (
    [string]$Title = 'Packer Menu'
) 

     $Template=New-Template $Title
     $ImageName= $Template[0]
     $TemplateJsonFile = $Template[1]
     New-Item -Name $ImageName -ItemType Directory
     Move-Item -path $TemplateJsonFile -Destination $ImageName
     $env:PACKER_LOG=1
     $env:PACKER_LOG_PATH="packerlog.txt"
     $host.ui.RawUI.WindowTitle = "Packer Build Template ($ImageName)" 
     Set-Rootpw $ImageName
     Write-Host "Creating $ImageName VM Image > packer build $ImageName/$TemplateJsonFile"
     invoke-expression  "packer build $ImageName/$TemplateJsonFile"
     Read-Host ' Press Enter to re-package artifacts into new Directory...'
     CleanupPackage $ImageName
     Pause
 }


Function BuildProxy {

    Param(
        [switch] $proxy=$false
    )
    if($proxy) {
        if (Add-PXCredential) {Start-Px(Test-Px)}
        BuildPacker "Packer Build Image Using Px Proxy"
        Stop-Px
    } elseif (-not $proxy) {
        BuildPacker "Packer Build Image Using Direct Internet"
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
    
    Write-Host " Press 'y' Proxy (default http_proxy=$env:http_proxy)"
    Write-Host " Press 'x' Exit."

    $selection = Read-Host " Press Any Key: Default No Proxy."
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

function BuildMachineImage
{
param (
    [string]$Title = 'Build Machine Image'
) 

$host.ui.RawUI.WindowTitle=$Title
Show-proxyMenu "Network Proxy Settings"

}

BuildMachineImage
