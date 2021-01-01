# Import Px Proxy Server Function

# region Include required files
#
$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
try {
    . ("$ScriptDirectory\Px.ps1")
}
catch {
    Write-Host "Error while loading supporting PowerShell Scripts" 
}
#endregion

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

function New-JsonTemplate
{
    param (
        [string]$Template
    )

            $InlineScriptPermission="find /tmp -type f -iname '*.sh' -exec chmod +x {} \;"
            $InlineScriptEnvVars="/tmp/linux/setEnvironmentVariables.sh" 
            $InlineScriptNetworkManager="/tmp/linux/yumNetworkManager.sh"  
            $InlineScriptProxy="/tmp/linux/yumUpdateConfig.sh"
            $InlineScriptDns="/tmp/linux/setIpAddressHostname.sh"
            $InlineScriptTimezone="/tmp/linux/setTimezone.sh"
            $InlineScriptYum=$env:yumupdate            
            $InlineScriptTuleap="/tmp/tuleap/yumInstallTuleap.sh"
            $InlineScriptTuleapLdap="/tmp/tuleap/ldap/ldapPlugin.sh"
            $InlineScriptOracleInstall="/tmp/oracledatabase/scripts/install.sh"
            $InlineScriptOracleImport="if [ -e /home/oracle/dump/import.sh  ]; then /home/oracle/dump/import.sh; fi"
            $InlineScriptPercona="/tmp/percona/scripts/install.sh"

            $EnvVarsOracle=@( "ORACLE_BASE=/opt/oracle",
                                "ORACLE_HOME=/opt/oracle/product/19c/dbhome",
                                "ORACLE_SID=${env:oracle_db_name}",
                                "ORACLE_CHARACTERSET=${env:oracle_db_characterSet}",
                                "ORACLE_EDITION=SE2")
            
            $TemplateJsonFile = "packer_templates\Template.json"

            $Json = Get-Content $TemplateJsonFile | Out-String  | ConvertFrom-Json

            $Json.builders[0] | Add-Member -Type NoteProperty -Name "output_directory" -Value ""
            
    switch ($Template)
    {
        'centos6' {
            $Json.variables.guest_os_type="centos6-64"
            $Json.variables.floppy_files="kickstart/centos6/ks.cfg"
            $Json.variables.iso_url="put_files_here/CentOS-6.10-x86_64-minimal.iso"
            $Json.variables.iso_checksum="7c0dee2a0494dabd84809b72ddb4b761f9ef92b78a506aef709b531c54d30770"

            $Json.builders[0].boot_command='["<tab> text ks=hd:fd0:/ks.cfg <enter><wait>"]'

            $InlineScriptDns= "$InlineScriptNetworkManager && $InlineScriptDns"

            $Json.provisioners[1].inline = "$InlineScriptPermission && $InlineScriptEnvVars && $InlineScriptDns && $InlineScriptTimezone && $InlineScriptProxy && $InlineScriptYum"
            $Json.provisioners[1] | Add-Member -Type NoteProperty -Name 'expect_disconnect' -Value 'true'
        }
        'centos7' {
            $Json.variables.guest_os_type="centos7-64"
            $Json.variables.floppy_files="kickstart/centos7/ks.cfg"
            $Json.variables.iso_url="put_files_here/CentOS-7-x86_64-Minimal-2009.iso"
            $Json.variables.iso_checksum="07b94e6b1a0b0260b94c83d6bb76b26bf7a310dc78d7a9c7432809fb9bc6194a"
            $Json.provisioners[1].inline = "$InlineScriptPermission && $InlineScriptEnvVars && $InlineScriptDns && $InlineScriptTimezone && $InlineScriptProxy && $InlineScriptYum"
            $Json.provisioners[1] | Add-Member -Type NoteProperty -Name 'expect_disconnect' -Value 'true'
        }
        'oraclelinux' {
            $Json.variables.guest_os_type="oraclelinux7-64"
            $Json.variables.floppy_files="kickstart/oraclelinux7/ks.cfg"
            $Json.variables.iso_url="put_files_here/OracleLinux-R7-U9-Server-x86_64-dvd.iso"
            $Json.variables.iso_checksum="dc2782bfd92b4c060cf8006fbc6e18036c27f599eebf3584a1a2ac54f008bf2f"
            $Json.builders[0].cpus="2"
            $Json.builders[0].memory="2048"
            $Json.provisioners[1].inline = "$InlineScriptPermission && $InlineScriptEnvVars && $InlineScriptDns && $InlineScriptTimezone && $InlineScriptProxy && $InlineScriptYum"
            $Json.provisioners[1] | Add-Member -Type NoteProperty -Name 'expect_disconnect' -Value 'true'
        }
        'perconamysql' {
            $TemplateJsonFile = New-JsonTemplate "centos7"
            $Json = Get-Content $TemplateJsonFile | Out-String  | ConvertFrom-Json
            Remove-Item $TemplateJsonFile
            
            $Json.provisioners += @{}
            $Json.provisioners += @{}  
            $TempFile = New-TemporaryFile
            $Json | ConvertTo-Json -depth 32 | Set-Content $TempFile
            $Json = Get-Content $TempFile | Out-String  | ConvertFrom-Json

            $Json.builders[0].cpus="2"
            $Json.builders[0].memory="4096"

            $Json.provisioners[2] | Add-Member -Type NoteProperty -Name 'type' -Value 'file'
            $Json.provisioners[2] | Add-Member -Type NoteProperty -Name 'source' -Value 'upload/percona'
            $Json.provisioners[2] | Add-Member -Type NoteProperty -Name 'destination' -Value '/tmp'

            $Json.provisioners[3] | Add-Member -Type NoteProperty -Name 'type' -Value 'shell'
            $Json.provisioners[3] | Add-Member -Type NoteProperty -Name 'inline' -Value "$InlineScriptPermission && $InlineScriptPercona"
            $Json.provisioners[3] | Add-Member -Type NoteProperty -Name 'expect_disconnect' -Value 'true'

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

            $Json.builders[0].cpus="2"
            $Json.builders[0].memory="4096"

            $Json.provisioners[2] | Add-Member -Type NoteProperty -Name 'type' -Value 'file'
            $Json.provisioners[2] | Add-Member -Type NoteProperty -Name 'source' -Value 'upload/oracledatabase'
            $Json.provisioners[2] | Add-Member -Type NoteProperty -Name 'destination' -Value '/tmp'

            $Json.provisioners[3] | Add-Member -Type NoteProperty -Name 'type' -Value 'file'
            $Json.provisioners[3] | Add-Member -Type NoteProperty -Name 'source' -Value 'put_files_here/LINUX.X64_193000_db_home.zip'
            $Json.provisioners[3] | Add-Member -Type NoteProperty -Name 'destination' -Value '/tmp/LINUX.X64_193000_db_home.zip'

            $provisionersshell=$Json.provisioners[1]
            $provisionersfile=$Json.provisioners[3]
            
            $Json.provisioners[1]=$provisionersfile
            $Json.provisioners[3]=$provisionersshell

            $Json.provisioners[4] | Add-Member -Type NoteProperty -Name 'type' -Value 'shell'
            $Json.provisioners[4] | Add-Member -Type NoteProperty -Name 'inline' -Value "$InlineScriptPermission && $InlineScriptOracleInstall && $InlineScriptOracleImport"
            $Json.provisioners[4] | Add-Member -Type NoteProperty -Name 'environment_vars' -Value $EnvVarsOracle
            $Json.provisioners[4] | Add-Member -Type NoteProperty -Name 'expect_disconnect' -Value 'true'

        } 
        'tuleap' {
            $TemplateJsonFile = New-JsonTemplate "centos7"
            $Json = Get-Content $TemplateJsonFile | Out-String  | ConvertFrom-Json
            Remove-Item $TemplateJsonFile

            $Json.provisioners += @{}
            $Json.provisioners += @{}  
            $Json.provisioners += @{}       
            $TempFile = New-TemporaryFile
            $Json | ConvertTo-Json -depth 32 | Set-Content $TempFile
            $Json = Get-Content $TempFile | Out-String  | ConvertFrom-Json

            $Json.provisioners[2] | Add-Member -Type NoteProperty -Name 'type' -Value 'file'
            $Json.provisioners[2] | Add-Member -Type NoteProperty -Name 'source' -Value 'upload/tuleap'
            $Json.provisioners[2] | Add-Member -Type NoteProperty -Name 'destination' -Value '/tmp'

            $Json.provisioners[3] | Add-Member -Type NoteProperty -Name 'type' -Value 'shell'
            $Json.provisioners[3] | Add-Member -Type NoteProperty -Name 'pause_before' -Value '30s'
            $Json.provisioners[3] | Add-Member -Type NoteProperty -Name 'inline' -Value "$InlineScriptPermission && $InlineScriptTuleap"
            
            $Json.provisioners[4] | Add-Member -Type NoteProperty -Name 'type' -Value 'file'
            $Json.provisioners[4] | Add-Member -Type NoteProperty -Name 'direction' -Value 'download'
            $Json.provisioners[4] | Add-Member -Type NoteProperty -Name 'source' -Value '/root/.tuleap_passwd'
            $Json.provisioners[4] | Add-Member -Type NoteProperty -Name 'destination' -Value '.tuleap_passwd'
        } 
        'tuleapldap' {
            $TemplateJsonFile = New-JsonTemplate "tuleap"
            $Json = Get-Content $TemplateJsonFile | Out-String  | ConvertFrom-Json
            Remove-Item $TemplateJsonFile
            
            $Json.provisioners[3].inline = "$InlineScriptPermission && $InlineScriptTuleap && $InlineScriptTuleapLdap"
        }
        default {        
        }  
    }
            
    $Json.variables.Hostname="${env:vm_name}"
    $Json.variables.ssh_password="${env:rootpw}"
    $Json.variables.tzoneinfo="${env:tzoneinfo}"

    if ([string]::IsNullOrEmpty($env:noproxy) -and ($env:ProxyDetected -eq $noproxymenu) )
    {
        $Json.variables.proxy=""
    } else {
        $Json.variables.proxy="${env:ProxyDetected}"
    }

    if ([string]::IsNullOrEmpty($env:USERDNSDOMAIN))
    {
        $Json.variables.dnsuffix=""
    } else {
        $Json.variables.dnsuffix="${env:USERDNSDOMAIN}" 
    }

    $Json.builders[0].output_directory="${env:vm_directory}"

    $TempFile = New-TemporaryFile
    $Json | ConvertTo-Json -depth 32 | Set-Content $TempFile

    $env:GeneratedTemplate=$Template
    return $TempFile
}


function Show-TemplateMenu
{
param (
    [string]$Title = 'Generate VM Templates'
)

    Write-Host "================ $Title ================"
    
    Write-Host " [1] CentOS 6.10, 7 (2009)"
    Write-Host " [2] Oracle Linux 7.9"
    Write-Host " [3] Tuleap (LDAP Options)"
    Write-Host " [4] Database (Oracle 19c, Percona MySQL)"
}


    Function Show-vmSettingsMenu {
        param (
        [string]$Title= "Virtual Machine Settings"
    )

                Write-Host "========================= $Title ======================="
                Write-Host " [10] Change Time Zone [$env:tzoneinfo]"
                Write-Host " [11] Change SSH Root Password [$env:rootpw]"
                Write-Host " [12] Change Virtual Machine Name [$env:vm_name] "
                Write-Host " [13] Change Virtual Machine Directory [$env:vm_directory]"
                Write-Host " [14] Configure Yum Update (ALL PACKAGES, ONLY SECURITY, NO UPDATES)" -NoNewline; Write-Host  $env:yumupdatemenu -ForegroundColor Green
                Show-proxyMenu 
        }

        function Show-oracleParametersMenu
        {
            param (
                [string]$Title = 'Oracle Database Parameters'
            )
        
            Write-Host "================ $Title ================"
        
            Write-Host " [20] Configure SID: $env:oracle_db_name"
            Write-Host " [21] Configure NLS: $env:oracle_db_characterSet"
        
        }

        function Show-buildMenu
        {
            param (
                [string]$Title = "BAMIP FOR VMWARE WORKSTATION"
            )
            
            Write-Host "================ $Title ================"
            Write-Host " ${env:GeneratedTemplateMenu} "
            Write-Host "`n"
        }

Function BuildPacker {
    $env:PACKER_LOG=1
    $env:PACKER_LOG_PATH="packerlog_${env:vm_name}_$env:vm_directory.txt"
    invoke-expression  "cmd /c start packer build packer_templates\${env:GeneratedTemplate}.json"
}

Function Clear-JsonTemplate {
    Get-ChildItem packer_templates -Recurse -Include *.json -Exclude Template.json | Remove-Item -Recurse -Force
    $env:GeneratedTemplate = ""
    $env:GeneratedTemplateMenu = "Generate Templates (CentOS, OL7, Tuleap, Database) ?"
}

function Build-MachineImage
{
do
{
Clear-Host

Show-buildMenu

Show-TemplateMenu

Show-vmSettingsMenu

Show-oracleParametersMenu

Write-Host "`n"
$selection = (Read-Host '  Choose a menu option, or press 0 to Exit').ToUpper()

switch ($selection)
{
    '0' {
       Clear-JsonTemplate
       break
    }
    '1' {
        $x = (Read-Host -Prompt "CentOS (6, Default = 7) ?").ToUpper()
        switch ($x) {
            { '6' -contains $_ } { $JsonTemplate=New-JsonTemplate "centos6"
                        Move-Item $JsonTemplate packer_templates\"${env:GeneratedTemplate}.json" -Force
                        $env:GeneratedTemplateMenu = "[B] Build Image CentOS 6" }
            Default {
                $JsonTemplate=New-JsonTemplate "centos7"
                Move-Item $JsonTemplate packer_templates\"${env:GeneratedTemplate}.json" -Force
                $env:GeneratedTemplateMenu = "[B] Build Image CentOS 7"
            }
        }
    }
    '2' {
        $x = (Read-Host -Prompt "Oracle LINUX (Default = 7) ?").ToUpper()
        switch ($x) {
            Default {
                $JsonTemplate=New-JsonTemplate "oraclelinux"
                Move-Item $JsonTemplate packer_templates\"${env:GeneratedTemplate}.json" -Force
                $env:GeneratedTemplateMenu = "[B] Build Image Oracle Linux 7"
            }
        }
    }
    '3' {
        $x = (Read-Host -Prompt "TULEAP (LDAP, Default = TULEAP) ?").ToUpper()
        switch ($x) {
            { 'ldap' -contains $_ } { $JsonTemplate=New-JsonTemplate "tuleapldap"
                                      Move-Item $JsonTemplate packer_templates\"${env:GeneratedTemplate}.json" -Force
                                      $env:GeneratedTemplateMenu = "[B] Build Image Tuleap LDAP" }
            Default {
                $JsonTemplate=New-JsonTemplate "tuleap"
                Move-Item $JsonTemplate packer_templates\"${env:GeneratedTemplate}.json" -Force
                $env:GeneratedTemplateMenu = "[B] Build Image Tuleap"
            }
        }
    } 
    '4' {
        $x = (Read-Host -Prompt "DATABASE (Percona, Default = 19c) ?").ToUpper()
        switch ($x) {
            { 'percona' -contains $_ } {$JsonTemplate=New-JsonTemplate "perconamysql"
                                        Move-Item $JsonTemplate packer_templates\"${env:GeneratedTemplate}.json" -Force
                                        $env:GeneratedTemplateMenu = "Percona Server for MySQL" }
            Default {
                $JsonTemplate=New-JsonTemplate "oracledatabase"
                Move-Item $JsonTemplate packer_templates\"${env:GeneratedTemplate}.json" -Force
                $env:GeneratedTemplateMenu = "[B] Build Image Oracle Database 19c" 
            }
    }
    }
    '10' {
        $env:tzoneinfo = Read-Host -Prompt "Enter Time Zone ?"
        Clear-JsonTemplate
    }
    '11' {
        $x = (Read-Host -Prompt "root password ([G]enerate, Default = Tape) ?").ToUpper()
        switch ($x) {
            { 'generate', 'g'  -contains $_ } { $env:rootpw = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 8 | ForEach-Object {[char]$_})  }
            Default {$env:rootpw= Read-Host -Prompt "Enter root password ?"}
        }
        Clear-JsonTemplate
    }
    '12' {
        $x = (Read-Host -Prompt "Virtual Machine Name ([G]enerate, Default = Tape) ?").ToUpper()
        switch ($x) {
            { 'generate', 'g'  -contains $_ } { $env:vm_name= -join ((65..90) | Get-Random -Count 6 | ForEach-Object {[char]$_}) }
            Default {$env:vm_name = Read-Host -Prompt "Enter VM Name: "}
        }
        Clear-JsonTemplate
    } 
    '13' {
        $x = (Read-Host -Prompt "Virtual Machine Directory ([G]enerate, Default = Tape) ?").ToUpper()
        switch ($x) {
            { 'generate', 'g'  -contains $_ } { $env:vm_directory = "output-" + -join ((65..90) | Get-Random -Count 6 | ForEach-Object {[char]$_}) }
            Default {$env:vm_directory = Read-Host -Prompt "Enter VM Directory: "}
        }
        Clear-JsonTemplate
    }
    '14' {
        $env:yumupdate = (Read-Host -Prompt "Do you want to install the updates? ([N]o, [S]ecurity, Default = Yes) ?").ToUpper()
        switch ($env:yumupdate) {
            { 'no', 'n'  -contains $_ } { $env:yumupdate="/tmp/linux/yumUpdateLess.sh"
            $env:yumupdatemenu="[NO UPDATES]" }
            { 'security', 's' -contains $_ } { $env:yumupdate="/tmp/linux/yumUpdateSecurity.sh" 
            $env:yumupdatemenu="[ONLY SECURITY]"}
            Default { $env:yumupdate="/tmp/linux/yumUpgrade.sh" 
            $env:yumupdatemenu="[ALL PACKAGES]"}
        }
        Clear-JsonTemplate
    }
    '15' {
        $x = (Read-Host -Prompt "Proxy Settings ([N]o Proxy,[S]ystem settings ,[M]anual, Default = Px NTLM) ?").ToUpper()
        switch ($x) {
            { 'n' -contains $_ } {
                    $env:noproxy=$null
                    $env:ProxyDetected = $noproxymenu
            } 

            { 'system', 's' -contains $_ } {
                
                if ([string]::IsNullOrEmpty($env:http_proxy) )
                {
                    $env:noproxy=$null
                    $env:ProxyDetected = $noproxymenu
                } else {
                    $env:ProxyDetected= $env:http_proxy
                }
                
            }         
            
            { 'm' -contains $_ }  {
                $ProxyManual= Read-Host -Prompt "Manual Proxy <IP:port>, <hostname:port> ?"
                $env:ProxyDetected='http://'+$ProxyManual
            }

            Default { if (Add-PXCredential) {Start-Px(Find-Px)} }
        }
    }



    '20' {
        $env:oracle_db_name = (Read-Host -Prompt "Enter ORACLE SID Name: ").ToUpper()
        Clear-JsonTemplate
    }
    '21' {
        $env:oracle_db_characterSet= Read-Host -Prompt "Enter characterSet: "
        Clear-JsonTemplate
    }
    'B' {
        if ([string]::IsNullOrEmpty($env:GeneratedTemplate))
        {
            Clear-Host
            Write-Host " Please Generate Template File !!!"
            Show-TemplateMenu
            Pause
        } else {
            BuildPacker
        }
    }    
}
}
until ( $selection -eq '0')
}

function Show-proxyMenu
{

    if ([string]::IsNullOrEmpty($env:ProxyDetected))
    {
        $env:noproxy=$null
        [string]$env:ProxyDetected = $noproxymenu
    } 
    Write-Host " [15] Configure Proxy (Manual, Px NTLM) [$env:ProxyDetected]"

}


function ChangeendLine

{
    Get-ChildItem -Recurse -Filter '*.sh' | ForEach-Object { ./set-eol -lineEnding unix -file $_.FullName }

}


Set-Variable -Name "noproxymenu" -Value "Direct access (no proxy server)."

$env:tzoneinfo="UTC"
$env:rootpw="server"
$env:oracle_db_name="NONCDB"
$env:oracle_db_characterSet="AL32UTF8"
Clear-JsonTemplate
$env:yumupdate="/tmp/linux/yumUpgrade.sh"
$env:yumupdatemenu="[ALL PACKAGES]"
$env:ProxyDetected=""

Build-MachineImage

Pause

Clear-Host