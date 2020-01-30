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
    [string]$VmName 
)     
    do
        {
            Clear-Host
            Write-Host "========================= $VmName ======================="
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
                    Edit-Template $VmName
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
                $centosFile = ".${VmName}_rootpw"
                Write-Output "CentOS system user password (root): $env:rootpw"  | Out-File $centosFile
                if ($?) {
                    Write-Host " Adding credentials to $centosFile"}
                    Pause
                    Clear-Host    
        } while (([string]::IsNullOrEmpty($env:rootpw)))
    }

    Function Get-Hostname {
        param (
        [string]$Hostname
    )     
        do
            {
                Clear-Host
                Write-Host "========================= Hostname Menu ======================="
                Write-Host "======Get Hostname VM================"
                    Write-Host " Press '1' Mannually: $Hostname-<XXX>"
                    Write-Host " Press 'r' Return."
                    $selection = Read-Host " Default Generate:"
                            switch ($selection)
                                                {
                                                    '1' {
                                                        $env:rootpw= Read-Host -Prompt "Enter root password ?"
                                                    }
                                                    default {
                                                        Write-Host " Generate VM Hostname..."
                                                        Write-Host " Set Hostname for VM"
                                                        $Id = -join ((65..90) | Get-Random -Count 3 | ForEach-Object {[char]$_})
                                                        return "$Hostname-$Id".ToUpperInvariant()
                                                    } 
                                                }  
                        Pause
                        Clear-Host    
            } while (-not ([string]::IsNullOrEmpty($selection)))
        }
function Edit-Template
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
    Write-Host " Press 'r' Return."
    $selection = Read-Host " Press Any Key: Default Packer Build Template"
    If($selection -eq "r") 
    {
        Show-proxyMenu
        break
   }
            $InlineScriptPermission="chmod -R a+rx /tmp/scripts" 
            $InlineScriptProxy="/tmp/scripts/yumConf.sh `"{{user ``proxy``}}`" "
            $InlineScriptUpdateOS="/tmp/scripts/yumUpdateOS.sh"
            $InlineScriptHostname="/tmp/scripts/setHostname.sh `"{{user ``hostname``}}`" `"{{user ``dnsuffix``}}`" "            
            $InlineScriptTuleap="/tmp/scripts/yumInstallTuleap.sh"
            $InlineScriptLdap="/tmp/scripts/ldapPlugin.sh"
            

    switch ($selection)
    {
        '0' {
            $VmName=Get-Hostname "CentOS"
            Write-Host "VMName $VmName "
            $TemplateJsonFile = "packerConfig-${VmName}.json"
            $Json = Get-Content 'packerConfig.json' | Out-String  | ConvertFrom-Json

            $Json.variables.Hostname=$VmName
            $Json.provisioners[1].inline = "$InlineScriptPermission && $InlineScriptProxy && $InlineScriptHostname && $InlineScriptUpdateOS"
            $Json.provisioners[1] | Add-Member -Type NoteProperty -Name 'expect_disconnect' -Value 'true'
            
            $TempFile = New-TemporaryFile
            $Json | ConvertTo-Json -depth 32 | Set-Content $TempFile
            Move-Item $TempFile $TemplateJsonFile
            return @($VmName,$TemplateJsonFile)
        }
        '1' {
            $VmName=Get-Hostname "Tuleap"
            Write-Host "VMName $VmName "
            $TemplateJsonFile = "packerConfig-${VmName}.json"
            $Json = Get-Content 'packerConfig.json' | Out-String  | ConvertFrom-Json

            $Json.variables.Hostname=$VmName
            
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
            
            $Json | ConvertTo-Json -depth 32 | Set-Content $TempFile
            Move-Item $TempFile $TemplateJsonFile
            return @($VmName,$TemplateJsonFile)
        } 
        '2' {
            $VmName=Get-Hostname "Ldap"
            Write-Host "VMName $VmName "
            $TemplateJsonFile = "packerConfig-${VmName}.json"
            $Json = Get-Content 'packerConfig.json' | Out-String  | ConvertFrom-Json

            $Json.variables.Hostname=$VmName

            $Json.provisioners += @{}
            $Json.provisioners += @{}
            $TempFile = New-TemporaryFile
            $Json | ConvertTo-Json -depth 32 | Set-Content $TempFile
            $Json = Get-Content $TempFile | Out-String  | ConvertFrom-Json
            
            $Json.provisioners[1].inline = "$InlineScriptPermission && $InlineScriptProxy && $InlineScriptHostname && $InlineScriptUpdateOS"
            $Json.provisioners[1] | Add-Member -Type NoteProperty -Name 'expect_disconnect' -Value 'true'

            $Json.provisioners[2] | Add-Member -Type NoteProperty -Name 'type' -Value 'shell'
            $Json.provisioners[2] | Add-Member -Type NoteProperty -Name 'pause_before' -Value '30s'
            $Json.provisioners[2] | Add-Member -Type NoteProperty -Name 'inline' -Value "$InlineScriptTuleap && $InlineScriptLdap"
            
            $Json.provisioners[3] | Add-Member -Type NoteProperty -Name 'type' -Value 'file'
            $Json.provisioners[3] | Add-Member -Type NoteProperty -Name 'direction' -Value 'download'
            $Json.provisioners[3] | Add-Member -Type NoteProperty -Name 'source' -Value '/root/.tuleap_passwd'
            $Json.provisioners[3] | Add-Member -Type NoteProperty -Name 'destination' -Value '.tuleap_passwd'
            
            $Json | ConvertTo-Json -depth 32 | Set-Content $TempFile
            Move-Item $TempFile $TemplateJsonFile
            return @($VmName,$TemplateJsonFile)
        } 
        default {
            $VmName=Get-Hostname "Provisioners"
            Write-Host "VMName $VmName "
            $TemplateJsonFile = "packerConfig-${VmName}.json"
            $Json = Get-Content 'packerConfig.json' | Out-String  | ConvertFrom-Json

            $Json.variables.Hostname=$VmName
            
            $TempFile = New-TemporaryFile
            $Json | ConvertTo-Json -depth 32 | Set-Content $TempFile
            Move-Item $TempFile $TemplateJsonFile
            return @($VmName,$TemplateJsonFile)
        }  
    }
    if (([string]::IsNullOrEmpty($selection))) {break}
} until (-not ([string]::IsNullOrEmpty($selection)))
}

function CleanupPackage {

    param (
        [string]$VmName
    )
    
    $outputFolder = "output-vmware-iso"
    $outputFolderLast = "output-${VmName}"
    $TemplateJsonFile = "packerConfig-${VmName}.json"
    $tuleapFile = ".tuleap_passwd"
    $centosFile = ".${VmName}_rootpw"
    
    Clear-Host
    Write-Host "======================== Cleanup & Package ==========================="
    Write-Host "Copying $centosFile, $tuleapFile, $TemplateJsonFile into $outputFolderLast Directory"
    Write-Host "$VmName VM File will be removed from VMware Workstation Library"

	if (Test-Path $outputFolder) {
        if (Test-Path $tuleapFile) { Move-Item $tuleapFile $outputFolder }
        if (Test-Path $centosFile) { Move-Item $centosFile $outputFolder }
        if (Test-Path $TemplateJsonFile) { Move-Item $TemplateJsonFile $outputFolder }
        Move-Item $outputFolder $outputFolderLast -Force
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

function BuildPacker
{
param (
    [string]$Title = 'Packer Menu'
) 

     $Template=Edit-Template $Title
     $VmName= $Template[0]
     $TemplateJsonFile = $Template[1] 
     $env:PACKER_LOG=1
     $env:PACKER_LOG_PATH="packerlog.txt"
     $host.ui.RawUI.WindowTitle = "Packer Build Template ($VmName)" 
     Set-Rootpw $VmName
     Write-Host "Creating $VmName VM Image > packer build $TemplateJsonFile"
     invoke-expression  "packer build $TemplateJsonFile"
     Read-Host ' Press Enter to re-package artifacts into new Directory...'
     CleanupPackage $VmName
     Pause
 }


Function BuildProxy {

    Param(
        [switch] $proxy=$false
    )
    if($proxy) {
        if (Add-PXCredential) {Start-Px(Test-Px)}
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
