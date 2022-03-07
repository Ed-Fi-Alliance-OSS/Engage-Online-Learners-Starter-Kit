# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.
#Requires -Version 5
#Requires -RunAsAdministrator
<#
    .SYNOPSIS
    Prepare a single-server environment for running the Engage Online Learners
    Starter Kit by installing the Ed-Fi Technology Suite 3.

    .DESCRIPTION
    This script fully prepares a stand-alone system to run the software listed
    below. It is not recommended for production installations, which typically
    would span across several servers instead of consolidating on a single one
    (for example, separate web and database servers). However, it may be a
    useful model for setting up a set of custom deployment scripts for
    production: for example, it could be duplicated for each server, and the
    irrelevant installs for that server could be removed. This script is being
    developed and tested for Windows Server 2019, and should also work in
    Windows 10 - though not as thoroughly tested there.

    Windows configuration

    * Enables TLS 1.2 support
    * Enables long file names at the OS level
    * Installs IIS and all of its feature components that are required for
      hosting .NET Core web applications

    Ed-Fi software:

    * Ed-Fi ODS/API for Suite 3, version 5.3
    * Ed-Fi Client Side Bulk Loader for Suite 3, version 5.3
    * Ed-Fi SwaggerUI for Suite 3, version 5.3
    * Ed-Fi ODS Admin App for Suite 3, version 2.3
    * Ed-Fi Analytics Middle Tier, latest development work (`main` branch)
    * Ed-Fi LMS Toolkit, latest development work (`main` branch).

    Note: the Analytics Middle Tier and LMS Toolkit are installed from the
    `main` branch by default because these are the primary two systems that are
    under development to support this Starter Kit. Experimentally, you can
    change the versions to any tag from those code repositories and the install
    process will alternately download that tag instead of `main`.

    .EXAMPLE
    PS> .\Install-EdFiTechnologySuite.ps1
    Installs with all default parameters

    .EXAMPLE
    PS> .\Install-EdFiTechnologySuite.ps1 -PlatformVersion 5.1
    Attempts to run the install with the Ed-Fi ODS/API Platform for Suite 3,
    version 5.1 (which is not formally supported at this time, but might work).

    .EXAMPLE
    PS> .\Install-EdFiTechnologySuite.ps1  -LMSToolkitVersion "1.1"
    Use the version tag "1.1" instead of installing from the `main` branch of
    the LMS Toolkit.
#>
param (
    # Root directory for web application installs.
    [string]
    $InstallPath = "c:/Ed-Fi",
    # Root directory for web application installs.
    [string]
    $WebRoot = "c:/inetpub/Ed-Fi",
   
    [string]
    $downloadPath ="C:\\temp",
    # NuGet Feed for Ed-Fi packages
    [string]
    $EdFiNuGetFeed = "https://pkgs.dev.azure.com/ed-fi-alliance/Ed-Fi-Alliance-OSS/_packaging/EdFi%40Release/nuget/v3/index.json",
    
    [hashtable]
    $databasesConfig,
    [hashtable]
    $adminAppConfig,
    [hashtable]
    $webApiConfig,
    [hashtable]
    $swaggerUIConfig,
    [hashtable]
    $amtConfig,
    [hashtable]
    $bulkLoadClientConfig,
    [hashtable]
    $lmsToolkitConfig
)

$global:ErrorActionPreference = "Stop"
# Disabling the progress report from `Invoke-WebRequest`, which substantially
# slows the download time.
$global:ProgressPreference = "SilentlyContinue"
Write-Host "Installing EdFi Suite..."
# Import all needed modules
# Create a few directories
New-Item -Path $InstallPath -ItemType Directory -Force | Out-Null
New-Item -Path $WebRoot -ItemType Directory -Force | Out-Null

Import-Module -Name "$PSScriptRoot/modules/Configure-Windows.psm1" -Force 
#--- IMPORT MODULES FOR EdFiSuite individual modules ---
Import-Module -Force "$PSScriptRoot/modules/EdFi-Admin.psm1"
Import-Module -Force "$PSScriptRoot/modules/EdFi-DBs.psm1"
Import-Module -Force "$PSScriptRoot/modules/EdFi-Swagger.psm1"
Import-Module -Force "$PSScriptRoot/modules/EdFi-WebAPI.psm1"
Import-Module -Force "$PSScriptRoot/modules/EdFi-AMT.psm1"
Import-Module -Force "$PSScriptRoot/modules/BulkLoadClient.psm1"
Import-Module -Name "$PSScriptRoot/modules/Install-LMSToolkit.psm1"
Import-Module -Force "$PSScriptRoot/modules/nuget-helper.psm1"
Import-Module -Force "$PSScriptRoot/modules/multi-instance-helper.psm1"
Import-Module -Name "$PSScriptRoot/modules/Tool-Helpers.psm1"

# Setup Windows, required tools, frameworks, and user applications
$downloadPath = "$($downloadPath)\downloads"
$toolsPath = "$($downloadPath)\tools"

Invoke-RefreshPath

Enable-LongFileNames

Write-Host "Installing NugetCli..."
Install-NugetCli $toolsPath

Write-Host "Installing SqlServerModule..."
Install-SqlServerModule
Write-Host "SqlServerModule installed"

#--- Start EdFi modules installation if required
# Install Databases
if ($databasesConfig.installDatabases){
    Write-host "Installing Databases..." -ForegroundColor Cyan
    #Create a database Admin user
    if($databasesConfig.addAdminUser){
        Write-host "Creating database user ($($databasesConfig.dbAdminUser))..." -ForegroundColor Cyan
        try { 
            $Pass = ConvertTo-SecureString -String "$($databasesConfig.dbAdminUserPassword)" -AsPlainText -Force
            $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "$($databasesConfig.dbAdminUser)", $Pass
            Add-SqlLogin -ServerInstance $databasesConfig.databaseServer -LoginName "$($databasesConfig.dbAdminUser)" -LoginType "SqlLogin" -DefaultDatabase "master" -GrantConnectSql -Enable -LoginPSCredential $Credential
            $server = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $databasesConfig.databaseServer
            $serverRole = $server.Roles | Where-Object {$_.Name -eq 'sysadmin'}
            $serverRole.AddMember("$($databasesConfig.dbAdminUser)")
        }
        catch { 
            Write-Host "User not added to the database" 
        }
    }

    $db_parameters = @{
        toolsPath = $toolsPath
        downloadPath = $downloadPath
        databasesConfig = $databasesConfig
        timeTravelScriptPath= "$PSScriptRoot/time-travel.sql"
        edfiSource=$EdFiNuGetFeed
    }
    Install-EdFiDbs @db_parameters
}

# Install Web API
if ($webApiConfig.installWebApi){
    Write-host "Installing Web API..." -ForegroundColor Cyan
    $api_parameters = @{
        webSiteName = $WebRoot
        toolsPath = $toolsPath
        downloadPath = $downloadPath
        webApiConfig = $webApiConfig
        databasesConfig = $databasesConfig
        edfiSource=$EdFiNuGetFeed
    }
    Install-EdFiAPI @api_parameters

    #$installerPathResult =  Install-EdFiAPI @api_parameters

    
}
Write-host "Swagger Section..."
# Install SwaggerUI
if ($swaggerUIConfig.installSwaggerUI){
    Write-host "Installing Swagger..." -ForegroundColor Cyan
    if($swaggerUIConfig.swaggerAppSettings.apiMetadataUrl){
        Test-ApiUrl $swaggerUIConfig.swaggerAppSettings.apiMetadataUrl
        if((Test-YearSpecificMode $databasesConfig.apiMode)) {
            $swaggerUIConfig.swaggerAppSettings.apiMetadataUrl += "{0}/" -f (Get-Date).Year
        }
    }
    else{
        Write-host "Swagger apiMetadataUrl is Emtpy." -ForegroundColor Cyan
    }
    $ApiUrl="https://$($env:computername)/$($webApiConfig.webApplicationName)"
    $swaggerUIConfig.swaggerAppSettings.apiVersionUrl=$ApiUrl
    if($swaggerUIConfig.swaggerAppSettings.apiVersionUrl){
        Test-ApiUrl $swaggerUIConfig.swaggerAppSettings.apiVersionUrl
    }
    else{
        Write-host "Swagger apiUrl is Emtpy." -ForegroundColor Cyan
    }    

    $swagger_parameters = @{
        toolsPath = $toolsPath
        downloadPath = $downloadPath
        swaggerUIConfig = $swaggerUIConfig
        ApiUrl="https://$($env:computername)/$($webApiConfig.webApplicationName)"
        edfiSource=$EdFiNuGetFeed
    }
    Install-EdFiSwagger @swagger_parameters
}
Write-host "AdminApp Section..."
# Installing AdminApp
if ($adminAppConfig.installAdminApp){
    write-host "Installing AdminApp..." -ForegroundColor Cyan
    $admin_parameters = @{
        webSiteName = $WebRoot
        toolsPath = $toolsPath
        downloadPath = $downloadPath
        adminAppConfig = $adminAppConfig
        databasesConfig = $databasesConfig
        ApiUrl="https://$($env:computername)/$($webApiConfig.webApplicationName)"
        edfiSource=$EdFiNuGetFeed
    }
    Install-EdFiAdmin @admin_parameters
}
Write-host "BulkLoadClient Section..."
# Install BulkLoadClient"
if($bulkLoadClientConfig.installBulkLoadClient) {
    Write-Host "Installing Bulk Load Client..." -ForegroundColor Cyan
    $bulkClientParam=@{
        PackageName = "$($bulkLoadClientConfig.packageDetails.packageName)"
        PackageVersion= "$($bulkLoadClientConfig.packageDetails.version)"
        InstallDir="$($bulkLoadClientConfig.installationDirectory)"
        ToolsPath=$toolsPath
        edfiSource=$EdFiNuGetFeed
    }
    Install-ClientBulkLoader @bulkClientParam
}
# Install LMSToolkit"
Write-host "LMSToolkit Section..."
if($lmsToolkitConfig.installLMSToolkit){
    # Now install the LMS Toolkit.
    write-host "Installing LMS Toolkit..." -ForegroundColor Cyan
    $params = @{
        DownloadPath = $downloadPath
        InstallDir = "$($lmsToolkitConfig.installationDirectory)"
        lmsToolkitConfig = $lmsToolkitConfig
        databasesConfig=$databasesConfig
    }
    Install-LMSToolkit @params
}
# Install AMT
if ($amtConfig.installAMT){

    Write-Host "Installing AMT..." -ForegroundColor Cyan

    $parameters = @{
        amtInstallerPath         = $amtConfig.amtInstallerPath
        amtConfig                = $amtConfig
        databasesConfig  = $databasesConfig
    }

    Install-amt @parameters

    Write-Host "AMT has been installed" -ForegroundColor Cyan
}
