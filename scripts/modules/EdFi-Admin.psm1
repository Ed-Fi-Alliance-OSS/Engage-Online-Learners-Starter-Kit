# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

#Requires -Version 5
$ErrorActionPreference = "Stop"

Import-Module "$PSScriptRoot\nuget-helper.psm1"
<#
.SYNOPSIS
    Installs the Ed-Fi Admin App.
.DESCRIPTION
    Installs the Ed-Fi Admin App.
.PARAMETER webSiteName
    IIS web site name.
.PARAMETER toolsPath
    Path for storing installation tools
.PARAMETER downloadPath
	Path for storing downloaded packages
.PARAMETER adminAppConfig
    Hashtable containing Admin App settings and the installation directory
	$adminAppConfig= @{
        installationDirectory = "C:\\inetpub\\wwwroot\\Ed-Fi\\AdminApp"
        packageDetails  = @{
            packageName = "EdFi.Suite3.ODS.AdminApp.Web"
            version     = "2.3"
        }
        packageInstallerDetails = @{
            packageName         = "EdFi.Suite3.Installer.AdminApp"
            version             = "2.3"
        }
    }
.PARAMETER databasesConfig
    Hashtable containing information about the databases and its server.
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
        engine                = "SQLServer"
        databaseServer        = "localhost"
        databasePort          = ""
        adminDatabaseName     = "EdFi_Admin"
        odsDatabaseName       = "EdFi_Ods"
        securityDatabaseName  = "EdFi_Security"
        apiMode               = "sharedinstance"
    }	
.PARAMETER ApiUrl
    Ed-Fi ODS Web API Web URL.
.PARAMETER edfiSource
    Ed-Fi nuget package feed source.
#>
function Install-EdFiAdmin(){
	[CmdletBinding()]
	param (
		# IIS web site name
		[string]
		$webSiteName="Ed-Fi",
		
        # Path for storing installation tools
		[string]
		$toolsPath="C:\\temp\\tools",
		
        # Path for storing downloaded packages
		[string]
		$downloadPath="C:\\temp\\downloads",
		
        # Hashtable containing Admin App settings and the installation directory
		[Hashtable]
		[Parameter(Mandatory=$true)]
		$adminAppConfig,
		
        # Hashtable containing information about the databases and its server
		[Hashtable]
		[Parameter(Mandatory=$true)]
		$databasesConfig,
        
        # Web API URL.
        [string]
		[Parameter(Mandatory=$true)]
		$ApiUrl,
        
        # Ed-Fi nuget package feed source..
        [string]
        $edfiSource="https://pkgs.dev.azure.com/ed-fi-alliance/Ed-Fi-Alliance-OSS/_packaging/EdFi%40Release/nuget/v3/index.json"
	)
    Write-Host "---" -ForegroundColor Magenta
    Write-Host "Ed-Fi Admin App process starting..." -ForegroundColor Magenta

    $paths = @{
        toolsPath = $toolsPath
        downloadPath = $downloadPath
        edfiSource = $edfiSource
    }
    $packageDetails = @{
        packageName = "$($adminAppConfig.packageInstallerDetails.packageName)"
        version = "$($adminAppConfig.packageInstallerDetails.version)"
    }
    $packagePath = nuget-helper\Install-EdFiPackage @packageDetails @paths

	Write-Host "Start installation..." -ForegroundColor Cyan
       
    $adminAppParams = @{
        adminAppConfig = $adminAppConfig
        databasesConfig = $databasesConfig
        toolsPath = $toolsPath
        downloadPath = $downloadPath
        ApiUrl = $ApiUrl
        edfiSource = $edfiSource
    }
    $parameters = New-AdminAppParameters @adminAppParams

    $parameters.WebSiteName = $webSiteName

    Import-Module -Force "$packagePath\Install-EdFiOdsAdminApp.psm1"
    Install-EdFiOdsAdminApp @parameters
}

function New-AdminAppParameters {
    param (
        [Hashtable] $adminAppConfig,
        [Hashtable] $databasesConfig,
        [String] $toolsPath,
        [String] $downloadPath,
        [String] $ApiUrl,
        [string] $edfiSource
    )

    $dbConnectionInfo = @{
        Server = $databasesConfig.databaseServer
        Port = $databasesConfig.databasePort
        UseIntegratedSecurity = $databasesConfig.applicationCredentials.useIntegratedSecurity
        Username = $databasesConfig.applicationCredentials.databaseUser
        Password = $databasesConfig.applicationCredentials.databasePassword
        Engine = $databasesConfig.engine
    }

    $adminAppFeatures = @{
        ApiMode = $databasesConfig.apiMode
    }
    $nugetPackageVersionParam=@{
        PackageName="$($adminAppConfig.packageDetails.packageName)"
        PackageVersion="$($adminAppConfig.packageDetails.version)"
        ToolsPath="$toolsPath"
        edfiSource="$($edfiSource)"
    }
    $adminAppNugetVersion = Get-NuGetPackageVersion @nugetPackageVersionParam
    return @{
        ToolsPath = $toolsPath
        DownloadPath = $downloadPath
        PackageName = "$($adminAppConfig.packageDetails.packageName)"
        PackageSource="$($edfiSource)"
        PackageVersion = "$($adminAppNugetVersion)"
        OdsApiUrl = $ApiUrl
        InstallCredentialsUser = $databasesConfig.installCredentials.databaseUser
        InstallCredentialsPassword = $databasesConfig.installCredentials.databasePassword
        InstallCredentialsUseIntegratedSecurity = $databasesConfig.installCredentials.useIntegratedSecurity
        AdminDatabaseName = $databasesConfig.adminDatabaseName
        OdsDatabaseName = $databasesConfig.odsDatabaseName
        SecurityDatabaseName = $databasesConfig.securityDatabaseName
        AdminAppFeatures = $adminAppFeatures
        DbConnectionInfo = $dbConnectionInfo        
    }
}

Export-ModuleMember Install-EdFiAdmin