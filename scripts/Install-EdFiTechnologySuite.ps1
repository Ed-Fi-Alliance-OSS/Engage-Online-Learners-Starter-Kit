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
    [string] $configPath = "$PSScriptRoot\configuration.json"
)
$global:ErrorActionPreference = "Stop"

# Disabling the progress report from `Invoke-WebRequest`, which substantially
# slows the download time.
$global:ProgressPreference = "SilentlyContinue"
# Import all needed modules
Import-Module -Force "$PSScriptRoot\confighelper.psm1"
$configuration = Format-ConfigurationFileToHashTable $configPath

$InstallPath = $configuration.installDirectory
$WebRoot = $configuration.lmsToolkitConfig.webRootFolder

# Create a few directories
New-Item -Path $InstallPath -ItemType Directory -Force | Out-Null
New-Item -Path $WebRoot -ItemType Directory -Force | Out-Null

#Import-Module -Name "$PSScriptRoot/modules/Configure-Windows.psm1" -Force 
#--- IMPORT MODULES FOR EdFiSuite individual modules ---
Import-Module -Force "$PSScriptRoot/modules/EdFi-Admin.psm1" -ArgumentList $configuration
Import-Module -Force "$PSScriptRoot/modules/EdFi-DBs.psm1" -ArgumentList $configuration
Import-Module -Force "$PSScriptRoot/modules/EdFi-Swagger.psm1" -ArgumentList $configuration
Import-Module -Force "$PSScriptRoot/modules/EdFi-WebAPI.psm1" -ArgumentList $configuration
Import-Module -Force "$PSScriptRoot/modules/EdFi-AMT.psm1" -ArgumentList $configuration
Import-Module -Force "$PSScriptRoot/modules/BulkLoadClient.psm1" -ArgumentList $configuration
Import-Module -Name "$PSScriptRoot/modules/Install-LMSToolkit.psm1" -ArgumentList $configuration
Import-Module -Force "$PSScriptRoot/modules/nuget-helper.psm1" -ArgumentList $configuration
Import-Module -Force "$PSScriptRoot/modules/multi-instance-helper.psm1"
Import-Module -Name "$PSScriptRoot/modules/Tool-Helpers.psm1" -ArgumentList $configuration 

# Setup Windows, required tools, frameworks, and user applications
$downloadPath = "$($configuration.downloadDirectory)\downloads"
$toolsPath = "$($configuration.downloadDirectory)\tools"

Invoke-RefreshPath
#Enable-LongFileNames

Install-NugetCli $toolsPath

Install-SqlServerModule
#Create a database Admin user
if($configuration.databasesConfig.addAdminUser){
    Write-host "Creating database user ($($configuration.databasesConfig.dbAdminUser))..." -ForegroundColor Cyan
    try { 
        $Pass = ConvertTo-SecureString -String "$($configuration.databasesConfig.dbAdminUserPassword)" -AsPlainText -Force
        $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "$($configuration.databasesConfig.dbAdminUser)", $Pass
        Add-SqlLogin -ServerInstance $configuration.databasesConfig.databaseServer -LoginName "$($configuration.databasesConfig.dbAdminUser)" -LoginType "SqlLogin" -DefaultDatabase "master" -GrantConnectSql -Enable -LoginPSCredential $Credential
        $server = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $configuration.databasesConfig.databaseServer
        $serverRole = $server.Roles | Where-Object {$_.Name -eq 'sysadmin'}
        $serverRole.AddMember("$($configuration.databasesConfig.dbAdminUser)")
    }
    catch { 
        Write-Host "User not added to the database" 
    }
}
#--- Start EdFi modules installation if required
# Install Databases
if ($configuration.installDatabases){
    Write-host "Installing Databases..." -ForegroundColor Cyan
    $db_parameters = @{
        toolsPath = $toolsPath
        downloadPath = $downloadPath
        databasesConfig = $configuration.databasesConfig
        timeTravelScriptPath= "$PSScriptRoot/time-travel.sql"
    }
    Install-EdFiDbs @db_parameters
}

# Install Web API
if ($configuration.installWebApi){
    Write-host "Installing Web API..." -ForegroundColor Cyan
    $api_parameters = @{
        webSiteName = $configuration.webSiteName
        toolsPath = $toolsPath
        downloadPath = $downloadPath
        webapiConfig = $configuration.webApiConfig
        databasesConfig = $configuration.databasesConfig
    }
    Install-EdFiAPI @api_parameters

    $installerPath =  Install-EdFiAPI @api_parameters

    # IIS-Components.psm1 must be imported after the IIS-WebServerManagementTools
    # windows feature has been enabled. This feature is enabled during Install-WebApi
    # by the AppCommon library.
    try{
        $webApiAppCommon = Join-Path "$($installerPath)" "AppCommon\IIS\IIS-Components.psm1"
        Import-Module -Force $webApiAppCommon

        $portNumber = IIS-Components\Get-PortNumber $configuration.webSiteName

        $expectedWebApiBaseUri = "https://$($env:computername):$($portNumber)/$($configuration.webApiConfig.webApplicationName)"

        Set-ApiUrl $expectedWebApiBaseUri
    }catch{
        Write-Host "$webApiAppCommon"
    }
}
# Install SwaggerUI
if ($configuration.installSwaggerUI){
    Write-host "Installing Swagger..." -ForegroundColor Cyan
    if($configuration.swaggerUIConfig.swaggerAppSettings.apiMetadataUrl){
        Test-ApiUrl $configuration.swaggerUIConfig.swaggerAppSettings.apiMetadataUrl
        if((Test-YearSpecificMode $configuration.databasesConfig.apiMode)) {
            $configuration.swaggerUIConfig.swaggerAppSettings.apiMetadataUrl += "{0}/" -f (Get-Date).Year
        }
    }
    else{
        Write-host "Swagger apiMetadataUrl is Emtpy." -ForegroundColor Cyan
    }
    if($configuration.swaggerUIConfig.swaggerAppSettings.apiVersionUrl){
        Test-ApiUrl $configuration.swaggerUIConfig.swaggerAppSettings.apiVersionUrl
        
    }
    else{
        Write-host "Swagger apiMetadataUrl is Emtpy." -ForegroundColor Cyan
    }    

    $swagger_parameters = @{
        webSiteName = $configuration.webSiteName
        toolsPath = $toolsPath
        downloadPath = $downloadPath
        swaggerUIConfig = $configuration.swaggerUIConfig
        webAPISite="https://$($env:computername)/$($configuration.webApiConfig.webApplicationName)"
    }
    Install-EdFiSwagger @swagger_parameters
}
# Installing AdminApp
if ($configuration.installAdminApp){
    write-host "Installing AdminApp..." -ForegroundColor Cyan
    $admin_parameters = @{
        webSiteName = $configuration.webSiteName
        toolsPath = $toolsPath
        downloadPath = $downloadPath
        adminAppConfig = $configuration.adminAppConfig
        databasesConfig = $configuration.databasesConfig
        webAPISite="https://$($env:computername)/$($configuration.webApiConfig.webApplicationName)"
    }
    Install-EdFiAdmin @admin_parameters
}
# Install BulkLoadClient"
if($configuration.installBulkLoadClient) {
    Write-Host "Installing Bulk Load Client..." -ForegroundColor Cyan
    $bulkClientParam=@{
        PackageName = "$($configuration.bulkLoadClientConfig.packageDetails.packageName)"
        PackageVersion= "$($configuration.bulkLoadClientConfig.packageDetails.version)"
        InstallDir="$($configuration.bulkLoadClientConfig.installationDirectory)"
        ToolsPath=$toolsPath
    }
    Install-ClientBulkLoader @bulkClientParam
}
# Install LMSToolkit"
if($configuration.installLMSToolkit){
    # Now install the LMS Toolkit.
    write-host "Installing LMS Toolkit..." -ForegroundColor Cyan
    $params = @{
        DownloadPath = $downloadPath
        InstallDir = "$($configuration.lmsToolkitConfig.installationDirectory)"
    }
    Install-LMSToolkit @params
}
# Install AMT
if ($configuration.installAMT){

    Write-Host "Installing AMT..." -ForegroundColor Cyan

    $parameters = @{
        databasesConfig          = $configuration.databasesConfig
        amtDownloadPath          = $configuration.amtConfig.amtDownloadPath
        amtInstallerPath         = $configuration.amtConfig.amtInstallerPath
        amtOptions               = $configuration.amtConfig.options
    }

    Install-amt @parameters

    Write-Host "AMT has been installed" -ForegroundColor Cyan
}