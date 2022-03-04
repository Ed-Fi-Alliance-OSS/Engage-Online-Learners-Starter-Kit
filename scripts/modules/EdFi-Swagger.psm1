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
$swaggerUIVersion = $configuration.packageDetails.version

Import-Module "$PSScriptRoot\nuget-helper.psm1" -ArgumentList $configuration

<#
.SYNOPSIS
    Installs the Ed-Fi Swagger.
.DESCRIPTION
    Installs the Ed-Fi Swagger.
.EXAMPLE
    PS c:\> Install-EdFiSwagger
#>
function Install-EdFiSwagger(){
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

        # Hashtable containing SwaggerUI settings and the installation directory
        [Hashtable]
        [Parameter(Mandatory=$true)]
        $swaggerUIConfig,
        [string]
        [Parameter(Mandatory=$true)]
        $webAPISite
    )

    $paths = @{
        toolsPath = $toolsPath
        downloadPath = $downloadPath
    }

    Write-Host "---" -ForegroundColor Magenta
    Write-Host "Ed-Fi Swagger module process starting..." -ForegroundColor Magenta

    $packageDetails = @{
        packageName = "$($configuration.swaggerUIConfig.packageInstallerDetails.packageName)"
        version = "$($configuration.swaggerUIConfig.packageInstallerDetails.version)"
    }

    $packagePath = nuget-helper\Install-EdFiPackage @packageDetails @paths

    $parameters = New-SwaggerUIParameters $swaggerUIConfig $toolsPath $downloadPath $webAPISite

    $parameters.WebSiteName = $webSiteName

    Import-Module -Force "$packagePath\Install-EdFiOdsSwaggerUI.psm1"

    Write-Host "Starting installation..." -ForegroundColor Cyan
    Install-EdFiOdsSwaggerUI @parameters
}

function New-SwaggerUIParameters {
    param (
        [Hashtable] $swaggerUIConfig,
        [String] $toolsPath,
        [String] $downloadPath,
        [string]
        [Parameter(Mandatory=$true)]
        $webAPISite
    )
    $nugetPackageVersionParam=@{
        PackageName="$($configuration.swaggerUIConfig.packageDetails.packageName)"
        PackageVersion="$($configuration.swaggerUIConfig.packageDetails.version)"
        ToolsPath="$toolsPath"
        edfiSource="$($configuration.EdFiNuGetFeed)"
    }
    $swaggerUINugetVersion = Get-NuGetPackageVersion @nugetPackageVersionParam
    return @{
        ToolsPath = $toolsPath
        DownloadPath = $downloadPath
        PackageName = "$($configuration.swaggerUIConfig.packageDetails.packageName)"
        PackageVersion = $swaggerUINugetVersion
        PackageSource = "$($configuration.EdFiNuGetFeed)"
        WebApplicationPath = $swaggerUIConfig.installationDirectory
        WebsiteName = "$($configuration.webSiteName)"
        WebApplicationName="$($configuration.swaggerUIConfig.WebApplicationName)"
        WebApiVersionUrl = "$($webAPISite)"
        DisablePrepopulatedCredentials = $True
    }
}

Export-ModuleMember Install-EdFiSwagger