# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

#Requires -Version 5
# Requires -RunAsAdministrator
$ErrorActionPreference = "Stop"

Import-Module "$PSScriptRoot\nuget-helper.psm1"
Import-Module "$PSScriptRoot\Tool-Helpers.psm1"

<#
.SYNOPSIS
    Installs the Ed-Fi Swagger.
.DESCRIPTION
    Installs the Ed-Fi Swagger.
.PARAMETER webSiteName
    IIS web site name    
.PARAMETER toolsPath
    Path for storing installation tools.
.PARAMETER downloadPath
    Path for storing downloaded packages.
.PARAMETER swaggerUIConfig
	Hashtable containing SwaggerUI settings and the installation directory
    $swaggerui= @{
        WebApplicationName= "SwaggerUI"
        installationDirectory= "C:\\inetpub\\wwwroot\\Ed-Fi\\SwaggerUI"
        packageDetails= @{
            packageName= "EdFi.Suite3.Ods.SwaggerUI"
            version= "5.3"
        }
        packageInstallerDetails= @{
            packageName= "EdFi.Suite3.Installer.SwaggerUI"
            version= "5.3"
        }
    }
.PARAMETER ApiUrl
    Ed-Fi ODS Web API Web URL.
.PARAMETER edfiSource
    Ed-Fi nuget package feed source.
#>
function Install-EdFiSwagger(){
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

        # Hashtable containing SwaggerUI settings and the installation directory
        [Hashtable]
        [Parameter(Mandatory=$true)]
        $swaggerUIConfig,

        # Ed-Fi ODS Web API Web URL.
        [string]
        [Parameter(Mandatory=$true)]
        $ApiUrl,

        # Ed-Fi nuget package feed source.
        [string]
        $edfiSource = "https://pkgs.dev.azure.com/ed-fi-alliance/Ed-Fi-Alliance-OSS/_packaging/EdFi%40Release/nuget/v3/index.json"
    )
    
    $paths = @{
        toolsPath       = $toolsPath
        downloadPath    = $downloadPath
        edfiSource      = $edfiSource
    }

    Write-Host "---" -ForegroundColor Magenta
    Write-Host "Ed-Fi Swagger module process starting..." -ForegroundColor Magenta

    $packageDetails = @{
        packageName = "$($swaggerUIConfig.packageInstallerDetails.packageName)"
        version     = "$($swaggerUIConfig.packageInstallerDetails.version)"
    }
    $newParam = @{
        swaggerUIConfig = $swaggerUIConfig
        ApiUrl          = $ApiUrl
        toolsPath       = $toolsPath
        downloadPath    = $downloadPath
        webSiteName     = $webSiteName
        edfiSource      = $edfiSource
    }
    $packagePath = nuget-helper\Install-EdFiPackage @packageDetails @paths
    Write-Host "Creating parameter array..." -ForegroundColor Cyan
    
    $parameters = New-SwaggerUIParameters @newParam
    
    $parameters.WebSiteName         = $webSiteName 
    
    Write-Host "Importing module Install-EdFiOdsSwaggerUI..." -ForegroundColor Cyan
    Import-Module -Force "$packagePath\Install-EdFiOdsSwaggerUI.psm1"
    try{
        Write-Host "Starting installation SwaggerUI..." -ForegroundColor Cyan
        Install-EdFiOdsSwaggerUI @parameters
    }
    catch{
        write-host "Installation failed (SwaggerUI)..."
        Test-ExitCode
    }
}

function New-SwaggerUIParameters {
    param (
        [Hashtable] $swaggerUIConfig,
        [string] $ApiUrl,
        [string] $toolsPath,
        [string] $downloadPath,
        [string] $webSiteName,
        [string] $edfiSource
    )
    Write-Host "New param..."
    $nugetPackageVersionParam=@{
        PackageName     = "$($swaggerUIConfig.packageDetails.packageName)"
        PackageVersion  = "$($swaggerUIConfig.packageDetails.version)"
        ToolsPath       = "$toolsPath"
        edfiSource      = "$($edfiSource)"
    }
    Write-Host "Get Swagger Version..."
    $swaggerUINugetVersion = Get-NuGetPackageVersion @nugetPackageVersionParam
    Write-Host "Return New param..."
    return @{
        PackageName         = "$($swaggerUIConfig.packageDetails.packageName)"
        PackageVersion      = "$($swaggerUINugetVersion)"
        PackageSource       = "$($edfiSource)"
        ToolsPath           = $toolsPath
        DownloadPath        = $downloadPath
        WebApplicationName  = "$($swaggerUIConfig.WebApplicationName)"
        WebApiVersionUrl    = "$($ApiUrl)"
        DisablePrepopulatedCredentials = $True
    }
}

Export-ModuleMember Install-EdFiSwagger