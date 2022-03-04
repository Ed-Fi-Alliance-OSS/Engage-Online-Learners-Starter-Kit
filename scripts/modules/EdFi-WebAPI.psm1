# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

#Requires -Version 5
#Requires -RunAsAdministrator
param(
    [parameter(Position=0,Mandatory=$true)][Hashtable]$configuration
)

$packageDetails = @{
    packageName = "$($configuration.webApiConfig.packageInstallerDetails.packageName)"
    version = "$($configuration.webApiConfig.packageInstallerDetails.version)"
}

$webApplicationName = $configuration.webApiConfig.webApplicationName
$webApiVersion = $configuration.webApiConfig.packageDetails.version
$ErrorActionPreference = "Stop"

Import-Module -Force "$PSScriptRoot\nuget-helper.psm1" -ArgumentList $configuration

<#
.SYNOPSIS
    Installs the Ed-Fi Web API.
.DESCRIPTION
    Installs the Ed-Fi web API.
.EXAMPLE
    PS c:\> Install-EdFiAPI
#>

function New-WebApiParameters {
    param (
        [Hashtable] $webapiConfig,
        [Hashtable] $databasesConfig,
        [String] $toolsPath,
        [String] $downloadPath
    )

    $dbConnectionInfo = @{
        Server = $databasesConfig.databaseServer
        Port = $databasesConfig.databasePort
        UseIntegratedSecurity = $databasesConfig.applicationCredentials.useIntegratedSecurity
        Username = $databasesConfig.applicationCredentials.databaseUser
        Password = $databasesConfig.applicationCredentials.databasePassword
        Engine = $databasesConfig.engine
    }

    $webApiFeatures = @{
        ExcludedExtensionSources = $webapiConfig.webApiAppSettings.excludedExtensionSources
        FeatureIsEnabled=@{
            profiles = $webapiConfig.webApiAppSettings.profiles
            extensions = $webapiConfig.webApiAppSettings.extensions
        }
    }
    $nugetPackageVersionParam=@{
        PackageName="$($webapiConfig.packageDetails.packageName)"
        PackageVersion="$($webApiVersion)"
        ToolsPath="$toolsPath"
        edfiSource="$($configuration.EdFiNuGetFeed)"
    }
    $webApiLatestVersion = Get-NuGetPackageVersion @nugetPackageVersionParam

    return @{
        ToolsPath = $toolsPath
        DownloadPath = $downloadPath
        PackageName = "$($webapiConfig.packageDetails.packageName)"
        PackageVersion = "$webApiLatestVersion"
        PackageSource = "$($configuration.EdFiNuGetFeed)"
        WebApplicationPath = $webapiConfig.installationDirectory
        WebApplicationName = $webApplicationName
        InstallType = $databasesConfig.apiMode
        AdminDatabaseName = $databasesConfig.adminDatabaseName
        OdsDatabaseName = $databasesConfig.odsDatabaseName
        SecurityDatabaseName = $databasesConfig.securityDatabaseName
        DbConnectionInfo = $dbConnectionInfo
        WebApiFeatures = $webApiFeatures
    }
}

function Install-EdFiAPI(){
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

        # Hashtable containing Web API settings and the installation directory
        [Hashtable]
        [Parameter(Mandatory=$true)]
        $webapiConfig,

        # Hashtable containing information about the databases and its server
        [Hashtable]
        [Parameter(Mandatory=$true)]
        $databasesConfig
	)

    Write-Host "---" -ForegroundColor Magenta
    Write-Host "Ed-Fi Web API module process starting..." -ForegroundColor Magenta

	# Temporary fix for solving the path-resolver.psm1 missing module error. Can be reworked once #ODS-4535 resolved.
	$pathResolverModule = "path-resolver"
	if ((Get-Module | Where-Object -Property Name -eq $pathResolverModule))
	{
		Remove-Module $pathResolverModule
	}

	$packagePath = Install-EdFiPackage @packageDetails

	Write-Host "Starting installation..." -ForegroundColor Cyan

    $parameters = New-WebApiParameters $webapiConfig $databasesConfig $toolsPath $downloadPath

    $parameters.WebSiteName = $webSiteName

    Import-Module -Force "$packagePath\Install-EdFiOdsWebApi.psm1"

    Install-EdFiOdsWebApi @parameters
    
    return $packagePath
}

Export-ModuleMember Install-EdFiAPI
