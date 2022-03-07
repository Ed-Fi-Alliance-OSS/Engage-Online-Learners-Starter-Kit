# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

#Requires -Version 5
# Requires -RunAsAdministrator
$ErrorActionPreference = "Stop"

Import-Module "$PSScriptRoot\nuget-helper.psm1"
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
		$ApiUrl,
        [Parameter(Mandatory=$True)]
        [string]
        $edfiSource
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

Export-ModuleMember Install-EdFiAdmin