# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

#Requires -Version 5
# Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

Import-Module -Force "$PSScriptRoot\nuget-helper.psm1"
Import-Module -Force "$PSScriptRoot\Tool-Helpers.psm1"

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
        [Hashtable] $webApiConfig,
        [Hashtable] $databasesConfig,
        [String] $toolsPath,
        [String] $downloadPath,
        [Parameter(Mandatory=$True)]
        [string]
        $edfiSource
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
        ExcludedExtensionSources = $webApiConfig.webApiAppSettings.excludedExtensionSources
        FeatureIsEnabled=@{
            profiles = $webApiConfig.webApiAppSettings.profiles
            extensions = $webApiConfig.webApiAppSettings.extensions
        }
    }
    $nugetPackageVersionParam=@{
        PackageName="$($webApiConfig.packageDetails.packageName)"
        PackageVersion="$($webApiConfig.packageDetails.version)"
        ToolsPath="$toolsPath"
        edfiSource="$($edfiSource)"
    }
    $webApiLatestVersion = Get-NuGetPackageVersion @nugetPackageVersionParam

    return @{
        ToolsPath = $toolsPath
        DownloadPath = $downloadPath
        PackageName = "$($webApiConfig.packageDetails.packageName)"
        PackageVersion = "$webApiLatestVersion"
        PackageSource = "$($edfiSource)"
        WebApplicationPath = $webApiConfig.installationDirectory
        WebApplicationName = $webApiConfig.webApplicationName
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
        $webApiConfig,

        # Hashtable containing information about the databases and its server
        [Hashtable]
        [Parameter(Mandatory=$true)]
        $databasesConfig,
        [Parameter(Mandatory=$true)]
        $edfiSource
	)
    $packageDetails = @{
        packageName = "$($webApiConfig.packageInstallerDetails.packageName)"
        version = "$($webApiConfig.packageInstallerDetails.version)"
        toolsPath    = $toolsPath
        downloadPath = $downloadPath
        edfiSource   = $edfiSource
    }
    Write-Host "---" -ForegroundColor Magenta
    Write-Host "Ed-Fi Web API module process starting..." -ForegroundColor Magenta

	# Temporary fix for solving the path-resolver.psm1 missing module error. Can be reworked once #ODS-4535 resolved.
	$pathResolverModule = "path-resolver"
	if ((Get-Module | Where-Object -Property Name -eq $pathResolverModule))
	{
		Remove-Module $pathResolverModule
	}
    Write-Host "EdFi Package ($($webApiConfig.packageInstallerDetails.packageName))-$($webApiConfig.packageInstallerDetails.version)..." -ForegroundColor Cyan
	$packagePath = Install-EdFiPackage @packageDetails

	Write-Host "Starting installation..." -ForegroundColor Cyan

    $parameters = New-WebApiParameters $webApiConfig $databasesConfig $toolsPath $downloadPath $edfiSource

    $parameters.WebSiteName = $webSiteName

    Import-Module -Force "$packagePath\Install-EdFiOdsWebApi.psm1"
write-host "****edfiods install"
    Install-EdFiOdsWebApi @parameters
    # IIS-Components.psm1 must be imported after the IIS-WebServerManagementTools
    # windows feature has been enabled. This feature is enabled during Install-WebApi
    # by the AppCommon library.
    try{
        Write-Host "********$installerPath****** $dirx*"
        Import-Module -Force Join-Path "$packagePath\AppCommon\IIS\IIS-Components.psm1"
        $portNumber = IIS-Components\Get-PortNumber $WebRoot

        $expectedWebApiBaseUri = "https://$($env:computername):$($portNumber)/$($webApiConfig.webApplicationName)"
        Write-Host "Setting API URL..."
        Set-ApiUrl $expectedWebApiBaseUri
        Write-Host "Setting API URL Continue..."
    }catch{
        Write-Host "Skipped $webApiAppCommon"
    }
    return $packagePath
}

Export-ModuleMember Install-EdFiAPI
