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

Function Show-rootpwMenu {
    param (
    [string]$Title= "VM SSH Root Password:" 
)     
            Write-Host "====== $Title [$env:rootpw] ======="
            Write-Host " [6] Enter root password ?"
            Write-Host " [7] Generate password ?"
    }


    Function Copy-rootpwDirectory {
        param (
        [string]$imageMachineDirectory 
    )     
                    $rootpwFile = ".rootpw_${imageMachine}"
                    Write-Output "SSH PASSWORD (root): $env:rootpw"  | Out-File $rootpwFile
                    if ($?) {
                    Write-Host " Adding credentials to $rootpwFile"}
                    Move-Item -path $rootpwFile -Destination $imageMachineDirectory
        }

    Function Show-directoryMenu {
        param (
        [string]$Title= "Output Directory:"
    )

                 if ([string]::IsNullOrEmpty($env:id_machine_image)) {
                    $env:id_machine_image = "vmware-iso"
                } 

                Write-Host "========================= $Title [ output-<VMNAME>-$env:id_machine_image ] ======================="

                Write-Host " [8] Enter output id ?"
                Write-Host " [9] Generate: ?" 
        }
function New-JsonTemplate
{
    param (
        [string]$machineImage
    )
            $InlineScriptPermission="chmod -R a+rx /tmp" 
            $InlineScriptProxy="/tmp/linux/yumConfigProxySSL.sh"
            $InlineScriptUpdateOS="/tmp/linux/yumUpdateOS.sh"
            $InlineScriptHostname="/tmp/linux/setHostname.sh"            
            $InlineScriptTuleap="/tmp/tuleap/yumInstallTuleap.sh"
            $InlineScriptTuleapLdap="/tmp/tuleap/ldapPlugin.sh"
            $InlineScriptDatabase="chmod -R a+rx /tmp/scripts/*.sh && /tmp/scripts/install.sh && /tmp/scripts/import.sh"

            $EnvVarsDatabase=@( "ORACLE_BASE=/opt/oracle",
                                "ORACLE_HOME=/opt/oracle/product/19c/dbhome",
                                "ORACLE_SID=${env:oracle_db_name}",
                                "ORACLE_CHARACTERSET=${env:oracle_db_characterSet}",
                                "ORACLE_EDITION=SE2",
                                "SYSTEM_TIMEZONE=${env:zoneinfo}")
            
            $TemplateJsonFile = "packer_templates\Template.json"

            $Json = Get-Content $TemplateJsonFile | Out-String  | ConvertFrom-Json

            $Json.builders[0] | Add-Member -Type NoteProperty -Name "output_directory" -Value ""
            
    switch ($machineImage)
    {
        'centos' {
            $Json.variables.guest_os_type="centos7-64"
            $Json.variables.floppy_files="kickstart/centos7/ks.cfg"
            $Json.variables.iso_url="put_files_here/CentOS-7-x86_64-Minimal-1908.iso"
            $Json.variables.iso_checksum="9a2c47d97b9975452f7d582264e9fc16d108ed8252ac6816239a3b58cef5c53d"
            $Json.provisioners[1].inline = "$InlineScriptPermission && $InlineScriptHostname"
            $Json.provisioners[1] | Add-Member -Type NoteProperty -Name 'expect_disconnect' -Value 'true'
        }
        'oraclelinux' {
            $Json.variables.guest_os_type="oraclelinux7-64"
            $Json.variables.floppy_files="kickstart/oraclelinux7/ks.cfg"
            $Json.variables.iso_url="put_files_here/V983339-01.iso"
            $Json.variables.iso_checksum="1D06CEF6A518C32C0E7ADCAD0A99A8EFBC7516066DE41118EBF49002C15EA84D"
            $Json.provisioners[1].inline = "$InlineScriptPermission && $InlineScriptHostname"
            $Json.provisioners[1] | Add-Member -Type NoteProperty -Name 'expect_disconnect' -Value 'true'
        }
        'oracledatabase' {
            $TemplateJsonFile = New-JsonTemplate "oraclelinux"
            $Json = Get-Content $TemplateJsonFile | Out-String  | ConvertFrom-Json
            Remove-Item $TemplateJsonFile

            $Json.provisioners += @{}
            $Json.provisioners += @{}
            $Json.provisioners += @{}       
            $TempFile = New-TemporaryFile
            $Json | ConvertTo-Json -depth 32 | Set-Content $TempFile
            $Json = Get-Content $TempFile | Out-String  | ConvertFrom-Json

            $Json.builders[0] | Add-Member -Type NoteProperty -Name 'cpus' -Value '2'
            $Json.builders[0] | Add-Member -Type NoteProperty -Name 'memory' -Value '4096'

            $Json.provisioners[2] | Add-Member -Type NoteProperty -Name 'type' -Value 'file'
            $Json.provisioners[2] | Add-Member -Type NoteProperty -Name 'source' -Value 'upload/oracledatabase/19c/'
            $Json.provisioners[2] | Add-Member -Type NoteProperty -Name 'destination' -Value '/tmp'

            $Json.provisioners[3] | Add-Member -Type NoteProperty -Name 'type' -Value 'file'
            $Json.provisioners[3] | Add-Member -Type NoteProperty -Name 'source' -Value 'put_files_here/LINUX.X64_193000_db_home.zip'
            $Json.provisioners[3] | Add-Member -Type NoteProperty -Name 'destination' -Value '/tmp/LINUX.X64_193000_db_home.zip'

            $Json.provisioners[4] | Add-Member -Type NoteProperty -Name 'type' -Value 'shell'
            $Json.provisioners[4] | Add-Member -Type NoteProperty -Name 'inline' -Value "$InlineScriptDatabase"
            $Json.provisioners[4] | Add-Member -Type NoteProperty -Name 'environment_vars' -Value $EnvVarsDatabase
            $Json.provisioners[4] | Add-Member -Type NoteProperty -Name 'expect_disconnect' -Value 'true'

        } 
        'tuleap' {
            $TemplateJsonFile = New-JsonTemplate "centos"
            $Json = Get-Content $TemplateJsonFile | Out-String  | ConvertFrom-Json
            Remove-Item $TemplateJsonFile

            $Json.provisioners += @{}
            $Json.provisioners += @{}       
            $TempFile = New-TemporaryFile
            $Json | ConvertTo-Json -depth 32 | Set-Content $TempFile
            $Json = Get-Content $TempFile | Out-String  | ConvertFrom-Json

            $Json.provisioners[2] | Add-Member -Type NoteProperty -Name 'type' -Value 'shell'
            $Json.provisioners[2] | Add-Member -Type NoteProperty -Name 'pause_before' -Value '30s'
            $Json.provisioners[2] | Add-Member -Type NoteProperty -Name 'inline' -Value $InlineScriptTuleap
            
            $Json.provisioners[3] | Add-Member -Type NoteProperty -Name 'type' -Value 'file'
            $Json.provisioners[3] | Add-Member -Type NoteProperty -Name 'direction' -Value 'download'
            $Json.provisioners[3] | Add-Member -Type NoteProperty -Name 'source' -Value '/root/.tuleap_passwd'
            $Json.provisioners[3] | Add-Member -Type NoteProperty -Name 'destination' -Value '.tuleap_passwd'
        } 
        'tuleapldap' {
            $TemplateJsonFile = New-JsonTemplate "centos"
            $Json = Get-Content $TemplateJsonFile | Out-String  | ConvertFrom-Json
            Remove-Item $TemplateJsonFile
            
            $Json.provisioners += @{}
            $Json.provisioners += @{}   
            $TempFile = New-TemporaryFile
            $Json | ConvertTo-Json -depth 32 | Set-Content $TempFile
            $Json = Get-Content $TempFile | Out-String  | ConvertFrom-Json

            $Json.provisioners[2] | Add-Member -Type NoteProperty -Name 'type' -Value 'shell'
            $Json.provisioners[2] | Add-Member -Type NoteProperty -Name 'pause_before' -Value '30s'
            $Json.provisioners[2] | Add-Member -Type NoteProperty -Name 'inline' -Value "$InlineScriptTuleap && $InlineScriptTuleapLdap"
            
            $Json.provisioners[3] | Add-Member -Type NoteProperty -Name 'type' -Value 'file'
            $Json.provisioners[3] | Add-Member -Type NoteProperty -Name 'direction' -Value 'download'
            $Json.provisioners[3] | Add-Member -Type NoteProperty -Name 'source' -Value '/root/.tuleap_passwd'
            $Json.provisioners[3] | Add-Member -Type NoteProperty -Name 'destination' -Value '.tuleap_passwd'
        }
        default {        
        }  
    }

    $VmId= "$machineImage-$env:id_machine_image"
            
    $Json.variables.Hostname="${VmId}"
    $Json.variables.ssh_password="${env:rootpw}"

    if ([string]::IsNullOrEmpty($env:http_proxy))
    {
        $Json.variables.proxy=""
    } else {
        $Json.variables.proxy="${env:http_proxy}" 
    }

    if ([string]::IsNullOrEmpty($env:USERDNSDOMAIN))
    {
        $Json.variables.dnsuffix=""
    } else {
        $Json.variables.dnsuffix="${env:USERDNSDOMAIN}" 
    }

    $Json.builders[0].output_directory="output-$VmId"

    $TempFile = New-TemporaryFile
    $Json | ConvertTo-Json -depth 32 | Set-Content $TempFile

    return $TempFile
}

function CleanupPackage {

    param (
        [string]$ImageNameDirectory
    )
    
    $outputFolder = "output-vmware-iso"
    $newoutputFolder = "output-${ImageNameDirectory}"

    Write-Host "======================== Cleanup & Package: ${ImageNameDirectory} ==========================="

	if (Test-Path $outputFolder) {
        Move-Item $outputFolder $newoutputFolder -Force
        Move-Item -path $newoutputFolder -Destination $ImageNameDirectory
    } 
}

function Show-packerMenu
{
param (
    [string]$Title = 'Generate VM Templates'
)

    Write-Host "================ $Title ================"
    
    Write-Host " [1] CentOS 7"
    Write-Host " [2] Oracle Linux 7"
    Write-Host " [3] Tuleap"
    Write-Host " [4] Tuleap LDAP"
    Write-Host " [5] Oracle Database 19c"
}


Function BuildPacker {

    Param(
        [string]$ImageDirectory
    )
    
    $env:PACKER_LOG=1
    $env:PACKER_LOG_PATH="$ImageDirectory/packerlog.txt"
    $host.ui.RawUI.WindowTitle = "Packer Build Template ($TemplateFileDirectory)" 
    Write-Host "Creating VM Image > packer build $ImageDirectory/$TemplateFile"
    invoke-expression  "packer build $ImageDirectory/$TemplateFile"
    Read-Host " Press Enter to re-package artifacts into new Directory: $ImageDirectory"
    CleanupPackage $ImageDirectory
    Pause

}

function Show-proxyMenu
{
    param (
        [string]$Title = 'Px Proxy'
    )

    Write-Host "================ $Title ================"
    if ([string]::IsNullOrEmpty($env:http_proxy))
    {
        $ProxyDefault = "No Proxy (Direct)"
    } else {
        $ProxyDefault = "System Proxy:$env:http_proxy"
    }
    Write-Host " [0] Configure Px Proxy [Current $ProxyDefault]"

}


function Show-oracleSidMenu
{
    param (
        [string]$Title = 'Oracle Database Configuration:'
    )

    Write-Host "================ $Title ================"

    Write-Host " [10] Configure Global database name (SID=$env:oracle_db_name)"
    Write-Host " [11] Configure Character set of the database ($env:oracle_db_characterSet)"

}

function Show-zoneinfoMenu
{
    param (
        [string]$Title = "Time Zone (TZ):"
    )

    Write-Host "================ $Title [$env:zoneinfo] ================"

    Write-Host " [12] Configure zoneinfo TZ"

}

function BuildMachineImage
{
param (
    [string]$Title = 'Build Machine Image'
) 
Clear-Host
$host.ui.RawUI.WindowTitle=$Title
do
{
Clear-Host
Show-proxyMenu
Show-packerMenu
Show-rootpwMenu
Show-directoryMenu
Show-oraclesidMenu
Show-zoneinfoMenu

$selection = (Read-Host '  Choose a menu option, or press x to Exit').ToLower()

switch ($selection)
{
    'x' {
       break
    }
    '0' {
        if (Add-PXCredential) {Start-Px(Test-Px)}
    }
    '1' {
        $JsonTemplate=New-JsonTemplate "centos"
        Move-Item $JsonTemplate packer_templates\"centos.json" -Force 
    }
    '2' {
        $JsonTemplate=New-JsonTemplate "oraclelinux"
        Move-Item $JsonTemplate packer_templates\"oraclelinux.json" -Force 
    } 
    '3' {
        $JsonTemplate=New-JsonTemplate "tuleap"
        Move-Item $JsonTemplate packer_templates\"tuleap.json" -Force 
    }
    '4' {
        $JsonTemplate=New-JsonTemplate "tuleapldap"
        Move-Item $JsonTemplate packer_templates\"tuleapldap.json" -Force 
    }
    '5' {
        $JsonTemplate=New-JsonTemplate "oracledatabase"
        Move-Item $JsonTemplate packer_templates\"oracledatabase.json" -Force 
    }
    '6' {
        $env:rootpw= Read-Host -Prompt "Enter root password ?"
    }
    '7' {
        $env:rootpw = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 8 | ForEach-Object {[char]$_})
    }
    '8' {
        $env:id_machine_image = Read-Host -Prompt "Enter Output ID: "
    } 
    '9' {
        $env:id_machine_image = -join ((65..90) | Get-Random -Count 6 | ForEach-Object {[char]$_})
    }
    '10' {
        $env:oracle_db_name = Read-Host -Prompt "Enter ORACLE SID Name: "
    }
    '11' {
        $env:oracle_db_characterSet= Read-Host -Prompt "Enter characterSet ?"
    }
    '12' {
        $env:zoneinfo = Read-Host -Prompt "Enter Time Zone ?"
    }     
}
}
until ( $selection -eq 'x')
}

$env:rootpw="server"
$env:oracle_db_name="NonCDB"
$env:oracle_db_characterSet="AL32UTF8"
$env:zoneinfo="UTC"
BuildMachineImage
Pause
Clear-Host
