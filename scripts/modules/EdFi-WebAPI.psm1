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
.PARAMETER webSiteName
    IIS web site name
.PARAMETER toolsPath
    Path for storing installation tools
.PARAMETER downloadPath
    Path for storing downloaded packages
.PARAMETER webApiConfig
    Hashtable containing Web API settings and the installation directory
    webApiConfig= @{
        webApplicationName= "WebApi"
        installationDirectory= "C:\\inetpub\\wwwroot\\Ed-Fi\\WebApi"
        webApiAppSettings= @{
            excludedExtensionSources= "Sample,Homograph"
            extensions= "true"
            profiles= "false"
            openApiMetadata= "true"
            aggregateDependencies= "true"
            tokenInfo= "true"
            composites= "true"
            changeQueries= "true"
            identityManagement= "false"
            ownershipBasedAuthorization= "false"
            uniqueIdValidation= "false"
        }
        packageDetails= @{
            packageName= "EdFi.Suite3.Ods.WebApi"
            version= "5.3"
        }
        packageInstallerDetails= @{
            packageName= "EdFi.Suite3.Installer.WebApi"
            version= "5.3"
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
        engine                = "SQLServer"
        databaseServer        = "localhost"
        databasePort          = ""
        adminDatabaseName     = "EdFi_Admin"
        odsDatabaseName       = "EdFi_Ods"
        securityDatabaseName  = "EdFi_Security"
        apiMode               = "sharedinstance"
    }
.PARAMETER edfiSource
    Ed-Fi nuget package feed source.
#>
function Install-EdFiAPI(){
	[CmdletBinding()]
	param (
        # IIS web site name
        [string]
        $webSiteName = "Ed-Fi",

        # Path for storing installation tools
        [string]
        $toolsPath = "C:\\temp\\tools",

        # Path for storing downloaded packages
        [string]
        $downloadPath = "C:\\temp\\downloads",

        # Hashtable containing Web API settings and the installation directory
        [Hashtable]
        [Parameter(Mandatory=$true)]
        $webApiConfig,

        # Hashtable containing information about the databases and its server
        [Hashtable]
        [Parameter(Mandatory=$true)]
        $databasesConfig,

        # Ed-Fi nuget package feed source..
        [string]
        $edfiSource="https://pkgs.dev.azure.com/ed-fi-alliance/Ed-Fi-Alliance-OSS/_packaging/EdFi%40Release/nuget/v3/index.json"
	)
    $packageDetails = @{
        packageName = "$($webApiConfig.packageInstallerDetails.packageName)"
        version     = "$($webApiConfig.packageInstallerDetails.version)"
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

    Install-EdFiOdsWebApi @parameters
    # IIS-Components.psm1 must be imported after the IIS-WebServerManagementTools
    # windows feature has been enabled. This feature is enabled during Install-WebApi
    # by the AppCommon library.
    try{        
        Import-Module -Force "$packagePath\AppCommon\IIS\IIS-Components.psm1"
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

Export-ModuleMember Install-EdFiAPI
