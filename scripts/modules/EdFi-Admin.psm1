# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

#Requires -Version 5
#Requires -RunAsAdministrator
param(
    [parameter(Position=0,Mandatory=$true)][Hashtable]$configuration
)

$ErrorActionPreference = "Stop"
$adminAppVersion = $configuration.adminAppConfig.packageInstallerDetails.version

$packageDetails = @{
    packageName = "$($configuration.adminAppConfig.packageInstallerDetails.packageName)"
    version = "$($configuration.adminAppConfig.packageInstallerDetails.version)"
}

Import-Module "$PSScriptRoot\nuget-helper.psm1" -ArgumentList $configuration
<#
.SYNOPSIS
    Installs the Ed-Fi Admin App.
.DESCRIPTION
    Installs the Ed-Fi Admin App.
.EXAMPLE
    PS c:\> Install-EdFiAdmin
#>

function New-AdminAppParameters {
    param (
        [Hashtable] $adminAppConfig,
        [Hashtable] $databasesConfig,
        [String] $toolsPath,
        [String] $downloadPath,
        [String] $webAPISite
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
        PackageName="$($configuration.adminAppConfig.packageDetails.packageName)"
        PackageVersion="$($configuration.adminAppConfig.packageDetails.version)"
        ToolsPath="$toolsPath"
        edfiSource="$($configuration.EdFiNuGetFeed)"
    }
    $adminAppNugetVersion = Get-NuGetPackageVersion @nugetPackageVersionParam
    return @{
        ToolsPath = $toolsPath
        DownloadPath = $downloadPath
        PackageName = "$($configuration.adminAppConfig.packageDetails.packageName)"
        PackageSource="$($configuration.EdFiNuGetFeed)"
        PackageVersion = "$($adminAppNugetVersion)"
        OdsApiUrl = $webAPISite
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
function Install-EdFiAdmin(){
	[CmdletBinding()]
	param (
		# IIS web site name
		[string]
		[Parameter(Mandatory=$true)]
		$webSiteName,
		# Path for storing installation tools
		[string]
		[Parameter(Mandatory=$true)]
		$toolsPath,
		# Path for storing downloaded packages
		[string]
		[Parameter(Mandatory=$true)]
		$downloadPath,
		# Hashtable containing Admin App settings and the installation directory
		[Hashtable]
		[Parameter(Mandatory=$true)]
		$adminAppConfig,
		# Hashtable containing information about the databases and its server
		[Hashtable]
		[Parameter(Mandatory=$true)]
		$databasesConfig,
        [string]
		[Parameter(Mandatory=$true)]
		$webAPISite
	)

    Write-Host "---" -ForegroundColor Magenta
    Write-Host "Ed-Fi Admin App process starting..." -ForegroundColor Magenta

    $paths = @{
        toolsPath = $toolsPath
        downloadPath = $downloadPath
    }

    $packagePath = nuget-helper\Install-EdFiPackage @packageDetails @paths

	Write-Host "Start installation..." -ForegroundColor Cyan
   
    
    $adminAppParams = @{
        adminAppConfig = $adminAppConfig
        databasesConfig = $databasesConfig
        toolsPath = $toolsPath
        downloadPath = $downloadPath
        webAPISite = $webAPISite
    }
    $parameters = New-AdminAppParameters @adminAppParams

    $parameters.WebSiteName = $webSiteName

    Import-Module -Force "$packagePath\Install-EdFiOdsAdminApp.psm1"
    Install-EdFiOdsAdminApp @parameters
}

Export-ModuleMember Install-EdFiAdmin