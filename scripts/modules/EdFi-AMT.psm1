# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

#Requires -version 5
$amtUninstallArgumentList = "-c `"{0}`" -e {1} -u"
$amtInstallArgumentList = "-c `"{0}`" -o {1} -e {2}"
$amtConsoleApp = "EdFi.AnalyticsMiddleTier.Console.exe"


function Install-AMT {
    <#
    .SYNOPSIS
        Installs the Ed-Fi Analytics-Middle-Tier.

    .DESCRIPTION
        Installs the Ed-Fi Analytics-Middle-Tier using the configuration
        values provided.
    .PARAMETER amtConfig
        Hashtable containing information about the AMT package and installation
            $amtConfig= @{
                amtDownloadPath         = "C:\\temp\\downloads",
                amtInstallerPath        = "C:\\temp\\tools",
                options                 = "EWS RLS Indexes Engage",
                install_selfContained   = $true,
                selfContainedOS         = "win10.x64",
                packageDetails = @{
                    packageName = "EdFi.AnalyticsMiddleTier",
                    packageURL  = "https=//github.com/Ed-Fi-Alliance-OSS/Ed-Fi-Analytics-Middle-Tier",
                    version     = "2.8.0"
                }
            }
    .PARAMETER databasesConfig
        Hashtable containing information about the databases and its server
            $databasesConfig= @{
                applicationCredentials= @{
                    databaseUser            = ""
                    databasePassword        = ""
                    useIntegratedSecurity   = $true
                }
                installCredentials= @{
                    databaseUser            = ""
                    databasePassword        = ""
                    useIntegratedSecurity   = $true
                }
                engine              = "SQLServer",
                databaseServer        = "localhost",
                databasePort          = "",
                adminDatabaseName     = "EdFi_Admin",
                odsDatabaseName       = "EdFi_Ods",
                securityDatabaseName  = "EdFi_Security"
                apiMode               = "sharedinstance"
            }
    #>
    [CmdletBinding()]
    param (
        # Hashtable containing information about the AMT package and installation
        [Parameter(Mandatory=$true)]
        [Hashtable]        
        $amtConfig,
        # 
        [Parameter(Mandatory=$true)]
        [Hashtable]        
        $databasesConfig
    )
    # Path for storing installation tools
    $amtInstallerPath=$amtConfig.amtInstallerPath
    $destinationName=Get-DestinationName $amtConfig
    $paths = @{
        amtPath = $amtInstallerPath
        downloadPath = $amtConfig.amtDownloadPath
        destinationName = $destinationName
        amtConfig = $amtConfig
    }

    try {
        $databaseEngine = if($databasesConfig.engine -ieq "SQLServer"){"mssql"}else{"postgres"}

        Request-amt-Files @paths

        Expand-amt-Files @paths

        $connectionString = New-amt-ConnectionString $databasesConfig
    
        $consoleInstaller = Join-Path (Join-Path $amtInstallerPath $destinationName) $amtConsoleApp
        
        Start-Process -NoNewWindow -FilePath $consoleInstaller -ArgumentList ($amtInstallArgumentList -f $connectionString, $amtConfig.options, $databaseEngine)
    }
    catch {
        Write-Host $_
        throw $_
    }
}

function Uninstall-AMT {
    <#
    .SYNOPSIS
        Uninstalls the Ed-Fi Analytics Middle Tier Views.

    .DESCRIPTION
        Uninstalls the Ed-Fi Analytics Middle Tier Views using the configuration
        values provided.

    .PARAMETER amtInstallerPath
        Path to the AMT installer.
    .PARAMETER amtConfig
        Hashtable containing information about the AMT package and installation
            $amtConfig= @{
                amtDownloadPath         = "C:\\temp\\downloads",
                amtInstallerPath        = "C:\\temp\\tools",
                options                 = "EWS RLS Indexes Engage",
                install_selfContained   = $true,
                selfContainedOS         = "win10.x64",
                packageDetails = @{
                    packageName = "EdFi.AnalyticsMiddleTier",
                    packageURL  = "https=//github.com/Ed-Fi-Alliance-OSS/Ed-Fi-Analytics-Middle-Tier",
                    version     = "2.8.0"
                }
            }
    .PARAMETER databasesConfig
        Hashtable containing information about the databases and its server
            $databasesConfig= @{
                applicationCredentials= @{
                    databaseUser            = ""
                    databasePassword        = ""
                    useIntegratedSecurity   = $true
                }
                installCredentials= @{
                    databaseUser            = ""
                    databasePassword        = ""
                    useIntegratedSecurity   = $true
                }
                engine              = "SQLServer",
                databaseServer        = "localhost",
                databasePort          = "",
                adminDatabaseName     = "EdFi_Admin",
                odsDatabaseName       = "EdFi_Ods",
                securityDatabaseName  = "EdFi_Security"
                apiMode               = "sharedinstance"
            }
    .EXAMPLE
        Installs the Analytics-Middle-Tier

        PS c:\> $amtConfig= @{
            amtInstallerPath        = "C:\\temp\\tools"
            amtDownloadPath         = "C:\\temp\\downloads"
            options                 = "EWS RLS Indexes Engage"
            install_selfContained   = $true
            selfContainedOS         = "win10.x64"
            packageDetails = @{
                packageName = "EdFi.AnalyticsMiddleTier"
                packageURL  = "https=//github.com/Ed-Fi-Alliance-OSS/Ed-Fi-Analytics-Middle-Tier"
                version     = "2.8.0"
            }
        }
        PS c:\> $databasesConfig = $databasesConfig= @{
                applicationCredentials= @{
                    databaseUser            = ""
                    databasePassword        = ""
                    useIntegratedSecurity   = $true
                }
                installCredentials= @{
                    databaseUser            = ""
                    databasePassword        = ""
                    useIntegratedSecurity   = $true
                }
                engine              = "SQLServer",
                databaseServer        = "localhost",
                databasePort          = "",
                adminDatabaseName     = "EdFi_Admin",
                odsDatabaseName       = "EdFi_Ods",
                securityDatabaseName  = "EdFi_Security"
                apiMode               = "sharedinstance"
            }
    #>
    [CmdletBinding()]
    param (
        # Hashtable containing information about the databases and its server
        [Parameter(Mandatory=$true)]
        [Hashtable]        
        $databasesConfig,
        [Parameter(Mandatory=$true)]
        [Hashtable]
        $amtConfig
    )
    $amtInstallerPath=$amtConfig.amtInstallerPath
    $destinationName=Get-DestinationName $amtConfig
    $paths = @{
        amtPath = $amtInstallerPath
        downloadPath = $amtConfig.amtDownloadPath
        destinationName = $destinationName
        amtConfig = $amtConfig
    }
    try{
        $databaseEngine = if($databasesConfig.engine -ieq "SQLServer"){"mssql"}else{"postgres"}
        
        Request-amt-Files @packageDetails @paths

        Expand-amt-Files @packageDetails @paths

        $connectionString = New-amt-ConnectionString $databasesConfig
    
        $consoleInstaller = Join-Path (Join-Path $amtInstallerPath $destinationName) $amtConsoleApp
        
        Start-Process -NoNewWindow -Wait -FilePath $consoleInstaller -ArgumentList ($amtUninstallArgumentList -f $connectionString, $databaseEngine)
    }
    catch {
        Write-Host $_
        throw $_
    }    
}
function Request-amt-Files{
    param (
        [string]$amtPath = "C:\temp\",
        [string]$downloadPath = "C:\temp\downloads\",
        [string]$destinationName,
        [Hashtable]$amtConfig
    )
    
	$Url = "$($amtConfig.packageDetails.packageURL)/releases/download/$($amtConfig.packageDetails.version)/$($destinationName).zip"
    
	if( -Not (Test-Path -Path $amtPath ) )
	{
        # Create the installer directory if it does not exist.
		New-Item -ItemType directory -Path $amtPath
	}
	if( -Not (Test-Path -Path $downloadPath ) )
	{
        # Create the download directory if it does not exist.
		New-Item -ItemType directory -Path $downloadPath
	}
		
	$ZipFile = Join-Path $downloadPath "$($destinationName).zip"
	
	Invoke-WebRequest -Uri $Url -OutFile $ZipFile 
	
    if ($LASTEXITCODE) {
        throw "Failed to download package $($amtConfig.packageDetails.packageName) $($amtConfig.packageDetails.version)"
    }

    return Resolve-Path $amtPath
}
function Expand-amt-Files {
    param (
        [string]$amtPath = "C:\temp\",
        [string]$downloadPath = "C:\temp\downloads\",
        [string]$destinationName,
        [Hashtable]$amtConfig
    )
    
    $amtVersionDestination = (Join-Path $amtPath $destinationName)

    $ZipFile = Join-Path $downloadPath "$($destinationName).zip"
    
    Expand-Archive -Path $ZipFile -DestinationPath $amtVersionDestination -Force
    
    if ($LASTEXITCODE) {
        throw "Failed to extract package $($amtConfig.packageDetails.packageName) $($amtConfig.packageDetails.version)"
    }
}

function New-amt-ConnectionString{
<#
.SYNOPSIS
    Creates a new connection string based on database configuration.
#>
    param (
        $databaseInfo
    )
    $postgresqlConnectionString="host={0};Database={1};user id={2};Password={3};port={4}" 
    $mssqlConnectionStringIntegrated="Server={0};Database={1};Integrated Security=SSPI;"
    $mssqlConnectionString="Server={0};Database={1};user id={2};Password={3};"
    if($databaseInfo.engine -ieq "SQLServer"){
        if($databaseInfo.installCredentials.UseIntegratedSecurity){
            return $mssqlConnectionStringIntegrated -f $databaseInfo.databaseServer,$databaseInfo.odsDatabaseName
        }
        else{
            return $mssqlConnectionString -f $databaseInfo.databaseServer,$databaseInfo.odsDatabaseName, $databaseInfo.installCredentials.databaseUser,$databaseInfo.installCredentials.databasePassword
        }
    }
    else{
        return $postgresqlConnectionString -f $databaseInfo.databaseServer,$databaseInfo.odsDatabaseName, $databaseInfo.applicationCredentials.databaseUser,$databaseInfo.applicationCredentials.databasePassword,$databaseInfo.applicationCredentials.databasePort
    }
}
function Get-DestinationName{
<#
.SYNOPSIS
    Function to get the destination folder for the AMT files.

.DESCRIPTION
    Returns a destination folder to extract the AMT files.
#>
    param(
        [Hashtable]
        [Parameter(Mandatory=$true)]
        $amtConfig
    )
    If ($amtConfig.install_selfContained) {
        return "$($amtConfig.packageDetails.packageName)-$($amtConfig.selfContainedOS)-$($amtConfig.packageDetails.version)"
    }
    Else {
        return "$($amtConfig.packageDetails.packageName)-$($amtConfig.packageDetails.version)"
    } 
}

Export-ModuleMember Install-AMT, Uninstall-AMT
