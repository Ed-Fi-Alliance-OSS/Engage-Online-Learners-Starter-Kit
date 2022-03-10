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

    .PARAMETER InstallPath
    Root directory for the application installation

    .PARAMETER webRootFolder
    Root directory for web applications.

    .PARAMETER WebRoot
    Root Site for web application.

    [string]
    .PARAMETER downloadPath
    Path for storing downloaded packages

    .PARAMETER EdFiNuGetFeed
    NuGet Feed for Ed-Fi packages

    .PARAMETER databasesConfig
    Hashtable containing information about the databases and its server.
    $databasesConfig= @{
        installDatabases        = $true
        applicationCredentials  = @{
            databaseUser            = ""
            databasePassword        = ""
            useIntegratedSecurity   = $true
        }
        installCredentials= @{
            databaseUser            = ""
            databasePassword        = ""
            useIntegratedSecurity   = $true
        }
        engine                  = "SQLServer"
        databaseServer          = "localhost"
        databasePort            = ""
        adminDatabaseName       = "EdFi_Admin"
        odsDatabaseName         = "EdFi_Ods"
        securityDatabaseName    = "EdFi_Security"
        useTemplates            = $false
        noDuration              = $false
        dropDatabases           = $true
        apiMode                 = "sharedinstance"
        odsDatabaseTemplateName = "populated"
        minimalTemplateSuffix   = "EdFiMinimalTemplate"
        populatedTemplateSuffix = "Ods"
        populatedTemplateScript = "GrandBend"
        addAdminUser            = $false
        dbAdminUser             = "edfi"
        dbAdminUserPassword     = "edfi"
        packageDetails          = @{
            packageName = "EdFi.Suite3.RestApi.Databases"
            version     = "5.3"
        }
    }

    .PARAMETER adminAppConfig
    Hashtable containing Admin App settings and the installation directory.
    $adminAppConfig= @{
        installAdminApp         = $true
        appStartUp              = "OnPrem"
        odsApi  = @{
            apiUrl  = ""
        }
        packageDetails          = @{
          packageName   = "EdFi.Suite3.ODS.AdminApp.Web"
          version       = "2.3"
        }
        packageInstallerDetails = @{
            packageName = "EdFi.Suite3.Installer.AdminApp"
            version     = "2.3"
        }
      }

    .PARAMETER webApiConfig
    Hashtable containing Web API settings and the installation directory.
    $webApiConfig       = @{
        installWebApi           = $true
        webApplicationName      = "WebApi"
        webApiAppSettings       = @{
            excludedExtensionSources    = "Sample,Homograph"
            extensions                  = "true"
            profiles                    = "false"
            openApiMetadata             = "true"
            aggregateDependencies       = "true"
            tokenInfo                   = "true"
            composites                  = "true"
            changeQueries               = "true"
            identityManagement          = "false"
            ownershipBasedAuthorization = "false"
            uniqueIdValidation          = "false"
        }
        packageDetails          = @{
            packageName = "EdFi.Suite3.Ods.WebApi"
            version     = "5.3"
        }
        packageInstallerDetails= @{
            packageName = "EdFi.Suite3.Installer.WebApi"
            version     = "5.3"
        }
    }

    .PARAMETER swaggerUIConfig
    Hashtable containing SwaggerUI settings and the installation directory.
    $swaggerUIConfig        =@{
        installSwaggerUI        = $true
        WebApplicationName      = "SwaggerUI"
        swaggerAppSettings      = @{
            apiMetadataUrl  = ""
            apiVersionUrl   = ""
        }
        packageDetails          = @{
            packageName     = "EdFi.Suite3.Ods.SwaggerUI"
            version         = "5.3"
        }
        packageInstallerDetails = @{
            packageName     = "EdFi.Suite3.Installer.SwaggerUI"
            version         = "5.3"
        }
    }

    .PARAMETER amtConfig
    Hashtable containing AMT settings and installation directory.
    $amtConfig  =@{
        installAMT              = $true
        amtDownloadPath         = "C:\\temp\\downloads"
        amtInstallerPath        = "C:\\temp\\tools"
        options                 = "EWS RLS Indexes Engage"
        install_selfContained   = "true"
        selfContainedOS         = "win10.x64"
        packageDetails          = @{
            packageName = "EdFi.AnalyticsMiddleTier"
            packageURL  = "https://github.com/Ed-Fi-Alliance-OSS/Ed-Fi-Analytics-Middle-Tier"
            version     = "2.8.0"
        }
    }

    .PARAMETER bulkLoadClientConfig
    Hashtable containing Bulk Load Client settings and installation directory.
    $bulkLoadClientConfig   = @{
        installBulkLoadClient   = $true
        installationDirectory   = "C:\\Ed-Fi\\Bulk-Load-Client"
        packageDetails  = @{
            packageName     = "EdFi.Suite3.BulkLoadClient.Console"
            version         = "5.3"
        }
        packageODSSchema52Details = @{
            packageURL  = "https://raw.githubusercontent.com/Ed-Fi-Alliance-OSS/Ed-Fi-ODS/"
            version     = "5.2"
        }
    }

    .PARAMETER lmsToolkitConfig
    Hashtable containing LMS Toolkit settings and installation directory.
    $lmsToolkitConfig   = @{
        installLMSToolkit       = $true
        installationDirectory   = "C:\\Ed-Fi\\"
        webRootFolder           = "c:\\inetpub\\Ed-Fi"
        pathToWorkingDir        = "C:\\Ed-Fi\\QuickStarts\\LMS-Toolkit"
        packageDetails  = @{
            packageURL      = "https://github.com/Ed-Fi-Alliance-OSS/LMS-Toolkit"
            version         = "main"
        }     
        sampleData      = @{
            key             = "dfghjkl34567"
            secret          = "4eryftgjh-pok%^K```$E%RTYG"
        }
    }

    .EXAMPLE
    PS> .\Install-EdFiTechnologySuite.ps1
    Installs with all default parameters from the json config file.

    .EXAMPLE
    PS> .\Install-EdFiTechnologySuite.ps1 -configPath c:/temp/config.json
    Attempts to run the install with a complete configuration json file
    with all the parameters.

    .EXAMPLE
    PS> .\Install-EdFiTechnologySuite.ps1 -databasesConfig $databasesConfig `
        -adminAppConfig $configuration.adminAppConfig `
        -webApiConfig $configuration.webApiConfig `
        -swaggerUIConfig $configuration.swaggerUIConfig `
        -amtConfig $configuration.amtConfig `
        -bulkLoadClientConfig $configuration.bulkLoadClientConfig `
        -lmsToolkitConfig $configuration.lmsToolkitConfig `
    Attempts to run the install with all the components configuration.
#>
param (
    # Root directory for the application installation.
    [string]
    $InstallPath    = "c:/Ed-Fi",
    # Root directory for web applications.
    [string]
    $webRootFolder  = "c:\inetpub\Ed-Fi",
    # Root directory for web application installs.
    [string]
    $WebRoot        = "Ed-Fi",   
    # Path for storing downloaded packages
    [string]
    $downloadPath   = "C:\\temp",
    # NuGet Feed for Ed-Fi packages
    [string]
    $EdFiNuGetFeed  = "https://pkgs.dev.azure.com/ed-fi-alliance/Ed-Fi-Alliance-OSS/_packaging/EdFi%40Release/nuget/v3/index.json",
    # Hashtable containing information about the databases and its server.
    [hashtable]
    $databasesConfig= @{
        installDatabases        = $true
        applicationCredentials  = @{
            databaseUser            = ""
            databasePassword        = ""
            useIntegratedSecurity   = $true
        }
        installCredentials= @{
            databaseUser            = ""
            databasePassword        = ""
            useIntegratedSecurity   = $true
        }
        engine                  = "SQLServer"
        databaseServer          = "localhost"
        databasePort            = ""
        adminDatabaseName       = "EdFi_Admin"
        odsDatabaseName         = "EdFi_Ods"
        securityDatabaseName    = "EdFi_Security"
        useTemplates            = $false
        noDuration              = $false
        dropDatabases           = $true
        apiMode                 = "sharedinstance"
        odsDatabaseTemplateName = "populated"
        minimalTemplateSuffix   = "EdFiMinimalTemplate"
        populatedTemplateSuffix = "Ods"
        populatedTemplateScript = "GrandBend"
        addAdminUser            = $false
        dbAdminUser             = "edfi"
        dbAdminUserPassword     = "edfi"
        packageDetails          = @{
            packageName = "EdFi.Suite3.RestApi.Databases"
            version     = "5.3"
        }
    },
    # Hashtable containing Admin App settings and the installation directory.
    [hashtable]
    $adminAppConfig= @{
        installAdminApp         = $true
        appStartUp              = "OnPrem"
        odsApi  = @{
            apiUrl  = ""
        }
        packageDetails          = @{
          packageName   = "EdFi.Suite3.ODS.AdminApp.Web"
          version       = "2.3"
        }
        packageInstallerDetails = @{
            packageName = "EdFi.Suite3.Installer.AdminApp"
            version     = "2.3"
        }
      },
    # Hashtable containing Web API settings and the installation directory.
    [hashtable]
    $webApiConfig       = @{
        installWebApi           = $true
        webApplicationName      = "WebApi"
        webApiAppSettings       = @{
            excludedExtensionSources    = "Sample,Homograph"
            extensions                  = "true"
            profiles                    = "false"
            openApiMetadata             = "true"
            aggregateDependencies       = "true"
            tokenInfo                   = "true"
            composites                  = "true"
            changeQueries               = "true"
            identityManagement          = "false"
            ownershipBasedAuthorization = "false"
            uniqueIdValidation          = "false"
        }
        packageDetails          = @{
            packageName = "EdFi.Suite3.Ods.WebApi"
            version     = "5.3"
        }
        packageInstallerDetails= @{
            packageName = "EdFi.Suite3.Installer.WebApi"
            version     = "5.3"
        }
    },
    # Hashtable containing SwaggerUI settings and the installation directory.
    [hashtable]
    $swaggerUIConfig        =@{
        installSwaggerUI        = $true
        WebApplicationName      = "SwaggerUI"
        swaggerAppSettings      = @{
            apiMetadataUrl  = ""
            apiVersionUrl   = ""
        }
        packageDetails          = @{
            packageName     = "EdFi.Suite3.Ods.SwaggerUI"
            version         = "5.3"
        }
        packageInstallerDetails = @{
            packageName     = "EdFi.Suite3.Installer.SwaggerUI"
            version         = "5.3"
        }
    },
    # Hashtable containing AMT settings and installation directory.
    [hashtable]
    $amtConfig  =@{
        installAMT              = $true
        amtDownloadPath         = "C:\\temp\\downloads"
        amtInstallerPath        = "C:\\temp\\tools"
        options                 = "EWS RLS Indexes Engage"
        install_selfContained   = "true"
        selfContainedOS         = "win10.x64"
        packageDetails          = @{
            packageName = "EdFi.AnalyticsMiddleTier"
            packageURL  = "https://github.com/Ed-Fi-Alliance-OSS/Ed-Fi-Analytics-Middle-Tier"
            version     = "2.8.0"
        }
    },
    # Hashtable containing Bulk Load Client settings and installation directory.
    [hashtable]
    $bulkLoadClientConfig   = @{
        installBulkLoadClient   = $true
        installationDirectory   = "C:\\Ed-Fi\\Bulk-Load-Client"
        packageDetails  = @{
            packageName     = "EdFi.Suite3.BulkLoadClient.Console"
            version         = "5.3"
        }
        packageODSSchema52Details = @{
            packageURL  = "https://raw.githubusercontent.com/Ed-Fi-Alliance-OSS/Ed-Fi-ODS/"
            version     = "5.2"
        }
    },
    # Hashtable containing LMS Toolkit settings and installation directory.
    [hashtable]
    $lmsToolkitConfig   = @{
        installLMSToolkit       = $true
        installationDirectory   = "C:\\Ed-Fi\\"
        webRootFolder           = "c:\\inetpub\\Ed-Fi"
        pathToWorkingDir        = "C:\\Ed-Fi\\QuickStarts\\LMS-Toolkit"
        packageDetails  = @{
            packageURL      = "https://github.com/Ed-Fi-Alliance-OSS/LMS-Toolkit"
            version         = "main"
        }     
        sampleData      = @{
            key             = "dfghjkl34567"
            secret          = "4eryftgjh-pok%^K```$E%RTYG"
        }
    }
)
$global:ErrorActionPreference = "Stop"
# Disabling the progress report from `Invoke-WebRequest`, which substantially
# slows the download time.
$global:ProgressPreference = "SilentlyContinue"
Write-Host "Installing EdFi Suite..."
# Import all needed modules
# Create a few directories
New-Item -Path $InstallPath -ItemType Directory -Force | Out-Null
New-Item -Path $webRootFolder -ItemType Directory -Force | Out-Null

Import-Module -Name "$PSScriptRoot/modules/Configure-Windows.psm1" -Force 
#--- IMPORT MODULES FOR EdFiSuite individual modules ---
Import-Module -Force "$PSScriptRoot/modules/EdFi-Admin.psm1"
Import-Module -Force "$PSScriptRoot/modules/EdFi-DBs.psm1"
Import-Module -Force "$PSScriptRoot/modules/EdFi-Swagger.psm1"
Import-Module -Force "$PSScriptRoot/modules/EdFi-WebAPI.psm1"
Import-Module -Force "$PSScriptRoot/modules/EdFi-AMT.psm1"
Import-Module -Force "$PSScriptRoot/modules/BulkLoadClient.psm1"
Import-Module -Name  "$PSScriptRoot/modules/Install-LMSToolkit.psm1"
# Import additional modules
Import-Module -Force "$PSScriptRoot/modules/nuget-helper.psm1"
Import-Module -Force "$PSScriptRoot/modules/multi-instance-helper.psm1"
Import-Module -Name  "$PSScriptRoot/modules/Tool-Helpers.psm1"

# Setup Windows, required tools, frameworks, and user applications
$downloadPath = "$($downloadPath)\downloads"
$toolsPath = "$($downloadPath)\tools"

Invoke-RefreshPath
Enable-LongFileNames

Write-Host "Installing NugetCli..."
Install-NugetCli $toolsPath

Write-Host "Installing SqlServerModule..."
Install-SqlServerModule

#--- Start EdFi modules installation if required
# Install Databases
if ($databasesConfig.installDatabases){
    Write-host "Installing Databases..." -ForegroundColor Cyan
    
    #Create a database Admin user
    if($databasesConfig.addAdminUser){
        Write-host "Creating database user ($($databasesConfig.dbAdminUser))..." -ForegroundColor Cyan
        try { 
            $Pass       = ConvertTo-SecureString -String "$($databasesConfig.dbAdminUserPassword)" -AsPlainText -Force
            $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "$($databasesConfig.dbAdminUser)", $Pass
            Add-SqlLogin -ServerInstance $databasesConfig.databaseServer -LoginName "$($databasesConfig.dbAdminUser)" -LoginType "SqlLogin" -DefaultDatabase "master" -GrantConnectSql -Enable -LoginPSCredential $Credential
            $server     = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $databasesConfig.databaseServer
            $serverRole = $server.Roles | Where-Object {$_.Name -eq 'sysadmin'}
            $serverRole.AddMember("$($databasesConfig.dbAdminUser)")
        }
        catch { 
            Write-Host "User not added to the database" 
        }
    }

    $db_parameters = @{
        toolsPath           = $toolsPath
        downloadPath        = $downloadPath
        databasesConfig     = $databasesConfig
        timeTravelScriptPath= "$PSScriptRoot/time-travel.sql"
        edfiSource          = $EdFiNuGetFeed
    }
    
    Install-EdFiDbs @db_parameters
}

# Install Web API
if ($webApiConfig.installWebApi){
    Write-host "Installing Web API..." -ForegroundColor Cyan
    
    $api_parameters = @{
        webSiteName     = $WebRoot
        toolsPath       = $toolsPath
        downloadPath    = $downloadPath
        webApiConfig    = $webApiConfig
        databasesConfig = $databasesConfig
        edfiSource      = $EdFiNuGetFeed
    }
    
    $apiPackagePath = Install-EdFiAPI @api_parameters
     # IIS-Components.psm1 must be imported after the IIS-WebServerManagementTools
    # windows feature has been enabled. This feature is enabled during Install-WebApi
    # by the AppCommon library.
    try{        
        Import-Module -Force "$apiPackagePath\AppCommon\IIS\IIS-Components.psm1"
        $portNumber = IIS-Components\Get-PortNumber $WebRoot

        $expectedWebApiBaseUri = "https://$($env:computername):$($portNumber)/$($webApiConfig.webApplicationName)"
        Write-Host "Setting API URL..."
        Set-ApiUrl $expectedWebApiBaseUri
        Write-Host "Setting API URL Finished..."
    }catch{
        Write-Host "Skipped Setting API URL"
    }
}

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
    # Web API Url
    $ApiUrl="https://$($env:computername)/$($webApiConfig.webApplicationName)"
    
    $swaggerUIConfig.swaggerAppSettings.apiVersionUrl=$ApiUrl
    
    if($swaggerUIConfig.swaggerAppSettings.apiVersionUrl){
        Test-ApiUrl $swaggerUIConfig.swaggerAppSettings.apiVersionUrl
    }
    else{
        Write-host "Swagger apiUrl is Emtpy." -ForegroundColor Cyan
    }    

    $swagger_parameters = @{
        webSiteName     = $WebRoot
        toolsPath       = $toolsPath
        downloadPath    = $downloadPath
        swaggerUIConfig = $swaggerUIConfig
        ApiUrl          = "https://$($env:computername)/$($webApiConfig.webApplicationName)"
        edfiSource      = $EdFiNuGetFeed
    }
    
    Install-EdFiSwagger @swagger_parameters
}

# Installing AdminApp
if ($adminAppConfig.installAdminApp){
    write-host "Installing AdminApp..." -ForegroundColor Cyan
    
    $admin_parameters = @{
        webSiteName     = $WebRoot
        toolsPath       = $toolsPath
        downloadPath    = $downloadPath
        adminAppConfig  = $adminAppConfig
        databasesConfig = $databasesConfig
        ApiUrl          = "https://$($env:computername)/$($webApiConfig.webApplicationName)"
        edfiSource      = $EdFiNuGetFeed
    }
    
    Install-EdFiAdmin @admin_parameters
}

# Install BulkLoadClient"
if($bulkLoadClientConfig.installBulkLoadClient) {
    Write-Host "Installing Bulk Load Client..." -ForegroundColor Cyan
    
    $bulkClientParam=@{
        PackageName     = "$($bulkLoadClientConfig.packageDetails.packageName)"
        PackageVersion  = "$($bulkLoadClientConfig.packageDetails.version)"
        InstallDir      = "$($bulkLoadClientConfig.installationDirectory)"
        ToolsPath       = $toolsPath
        edfiSource      = $EdFiNuGetFeed
    }
    
    Install-ClientBulkLoader @bulkClientParam
}

# Install LMSToolkit"
if($lmsToolkitConfig.installLMSToolkit){
    # Now install the LMS Toolkit.
    write-host "Installing LMS Toolkit..." -ForegroundColor Cyan
    
    $params = @{
        DownloadPath        = $downloadPath
        InstallDir          = "$($lmsToolkitConfig.installationDirectory)"
        lmsToolkitConfig    = $lmsToolkitConfig
        databasesConfig     = $databasesConfig
    }
    
    Install-LMSToolkit @params
}

# Install AMT
if ($amtConfig.installAMT){
    Write-Host "Installing AMT..." -ForegroundColor Cyan
    
    $parameters = @{
        amtConfig        = $amtConfig
        databasesConfig  = $databasesConfig
    }

    Install-amt @parameters

    Write-Host "AMT has been installed" -ForegroundColor Cyan
}
