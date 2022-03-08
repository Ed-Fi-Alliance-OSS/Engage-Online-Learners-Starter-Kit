# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

#Requires -Version 5
#Requires -RunAsAdministrator

<#
    .SYNOPSIS
    Performs complete setup of a virtual machine for the Engage Online Learners
    Starter Kit.

    .DESCRIPTION
    Performs complete setup of a virtual machine for the Engage Online Learners
    Starter Kit, appropriate for use on any Windows 2019 Server whether
    on-premises or running in a cloud provider (tested in desktop Hyper-V and on
    AWS EC2).

    This script enables TLS 1.2 support and sets the execution policy to enable
    running additional scripts. Then it calls the following:

    1. Install-ThirdPartyApplications.ps1
    2. Install-EdFiTechnologySuite.ps1
    3. Install-StarterKit.ps1

    Please review the script files above for more information on the actions
    they take.

.PARAMETER configPath
    Parameters configuration file.

    .PARAMETER InstallPath
    Root directory for the application installation

    .PARAMETER WebRoot
    Root directory for web application installs.

    [string]
    .PARAMETER downloadPath
    Path for storing downloaded packages

    .PARAMETER EdFiNuGetFeed
    NuGet Feed for Ed-Fi packages

    .PARAMETER databasesConfig
    Hashtable containing information about the databases and its server.
    $databasesConfig = @{
        installDatabases= $true,
        applicationCredentials= @{
            databaseUser= ""
            databasePassword= ""
            useIntegratedSecurity= $true
        }
        installCredentials= @{
            databaseUser= ""
            databasePassword= ""
            useIntegratedSecurity= $true
        }
        engine= "SQLServer"
        databaseServer= "localhost"
        databasePort= ""
        adminDatabaseName= "EdFi_Admin"
        odsDatabaseName= "EdFi_Ods"
        securityDatabaseName= "EdFi_Security"
        useTemplates= $false,
        noDuration= $false,
        dropDatabases= $true,
        apiMode= "sharedinstance"
        odsTokens= [],
        odsDatabaseTemplateName= "populated"
        useIntegratedSecurity= $true,
        minimalTemplateSuffix="Ods_Minimal_Template"
        populatedTemplateSuffix="Ods"
        populatedTemplateScript= "GrandBend"
        addAdminUser= $false,
        dbAdminUser= "edfi"
        dbAdminUserPassword= "edfi"
        packageDetails= @{
            packageName= "EdFi.Suite3.RestApi.Databases"
            version= "5.3"
        }
    }

    .PARAMETER adminAppConfig
    Hashtable containing Admin App settings and the installation directory.
    $adminAppConfig = @{
      installAdminApp= $true,
      installationDirectory= "C:\\inetpub\\wwwroot\\Ed-Fi\\AdminApp"
      appStartUp= "OnPrem"
      odsApi= @{
          apiUrl= ""
      }
      packageDetails= @{
        packageName= "EdFi.Suite3.ODS.AdminApp.Web"
        version= "2.3"
      }
      packageInstallerDetails= @{
          packageName= "EdFi.Suite3.Installer.AdminApp"
          version= "2.3"
      }
    }
    .PARAMETER webApiConfig
    Hashtable containing Web API settings and the installation directory.
    $webApiConfig= @{
      installWebApi= $true,
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

    .PARAMETER swaggerUIConfig
    Hashtable containing SwaggerUI settings and the installation directory.
    $swaggerUIConfig= @{
      installSwaggerUI= $true,
      WebApplicationName= "SwaggerUI"
      installationDirectory= "C:\\inetpub\\wwwroot\\Ed-Fi\\SwaggerUI"
      swaggerAppSettings= @{
          apiMetadataUrl= ""
          apiVersionUrl= ""
      }
      packageDetails= @{
          packageName= "EdFi.Suite3.Ods.SwaggerUI"
          version= "5.3"
      }
      packageInstallerDetails= @{
          packageName= "EdFi.Suite3.Installer.SwaggerUI"
          version= "5.3"
      }
    }

    .PARAMETER amtConfig
    Hashtable containing AMT settings and installation directory.
    $amtConfig= @{
      installAMT= $true,
      amtDownloadPath= "C:\\temp\\downloads"
      amtInstallerPath= "C:\\temp\\tools"
      options= "EWS RLS Indexes Engage"
      install_selfContained= "true"
      selfContainedOS= "win10.x64"
      packageDetails= @{
          packageName= "EdFi.AnalyticsMiddleTier"
          packageURL= "https://github.com/Ed-Fi-Alliance-OSS/Ed-Fi-Analytics-Middle-Tier"
          version= "2.8.0"
      }
    }
    .PARAMETER bulkLoadClientConfig
    Hashtable containing Bulk Load Client settings and installation directory.
    $bulkLoadClientConfig= @{
        installBulkLoadClient= $true,
        installationDirectory= "C:\\Ed-Fi\\Bulk-Load-Client"
        packageDetails= @{
            packageName= "EdFi.Suite3.BulkLoadClient.Console"
            version= "5.3"
        }
        packageODSSchema52Details={
            packageURL= "https://raw.githubusercontent.com/Ed-Fi-Alliance-OSS/Ed-Fi-ODS/"
            version= "5.2"
        }
    }

    .PARAMETER lmsToolkitConfig
    Hashtable containing LMS Toolkit settings and installation directory.
    $lmsToolkitConfig= @{
        installLMSToolkit= $true,
        installationDirectory= "C:\\Ed-Fi\\"
        webRootFolder= "c:\\inetpub\\Ed-Fi"
        pathToWorkingDir= "C:\\Ed-Fi\\QuickStarts\\LMS-Toolkit"
        packageDetails= @{
            packageURL= "https://github.com/Ed-Fi-Alliance-OSS/LMS-Toolkit"
            version= "main"
        }     
        sampleData= @{
            key= "dfghjkl34567"
            secret= "4eryftgjh-pok%^K`$E%RTYG"
        }
    }
#>
param (
    [string]
    $configPath = "$PSScriptRoot\configuration.json",
    # Root directory for the application installation.
    [string]
    $InstallPath = "c:/Ed-Fi",
    # Root directory for web application installs.
    [string]
    $WebRoot        = "Ed-Fi",   
    # Path for storing downloaded packages
    [string]
    $downloadPath   ="C:\\temp",
    # NuGet Feed for Ed-Fi packages
    [string]
    $EdFiNuGetFeed  = "https://pkgs.dev.azure.com/ed-fi-alliance/Ed-Fi-Alliance-OSS/_packaging/EdFi%40Release/nuget/v3/index.json",
    # Hashtable containing information about the databases and its server.
    [hashtable]
    $databasesConfig,
    # Hashtable containing Admin App settings and the installation directory.
    [hashtable]
    $adminAppConfig,
    # Hashtable containing Web API settings and the installation directory.
    [hashtable]
    $webApiConfig,
    # Hashtable containing SwaggerUI settings and the installation directory.
    [hashtable]
    $swaggerUIConfig,
    # Hashtable containing AMT settings and installation directory.
    [hashtable]
    $amtConfig,
    # Hashtable containing Bulk Load Client settings and installation directory.
    [hashtable]
    $bulkLoadClientConfig,
    # Hashtable containing LMS Toolkit settings and installation directory.
    [hashtable]
    $lmsToolkitConfig
)
$global:ErrorActionPreference = "Stop"
$global:ProgressPreference = "SilentlyContinue"

Import-Module -Name "$PSScriptRoot\modules\Configure-Windows.psm1" -Force
Import-Module -Force "$PSScriptRoot\confighelper.psm1"
# Read the configuration file.
$configuration = Format-ConfigurationFileToHashTable $configPath
$toolsPath = "$($downloadPath)\tools"
if(-not $databasesConfig){
    $databasesConfig= $configuration.databasesConfig
}
if(-not $adminAppConfig){
    $adminAppConfig= $configuration.adminAppConfig
}
if(-not $webApiConfig){
    $webApiConfig= $configuration.webApiConfig
}
if(-not $swaggerUIConfig){
    $swaggerUIConfig= $configuration.swaggerUIConfig
}
if(-not $amtConfig){
    $amtConfig= $configuration.amtConfig
}
if(-not $bulkLoadClientConfig){
    $bulkLoadClientConfig= $configuration.bulkLoadClientConfig
}
if(-not $lmsToolkitConfig){
    $lmsToolkitConfig= $configuration.lmsToolkitConfig
}
Set-TLS12Support
Set-ExecutionPolicy bypass -Scope CurrentUser -Force;

& "$PSScriptRoot/Install-ThirdPartyApplications.ps1" -ToolsPath $toolsPath

Write-Host "Creating Ed-Fi Suite parameter..."
$edfiSuiteParam = @{
    InstallPath         =$InstallPath
    WebRoot             =$WebRoot
    downloadPath        =$downloadPath
    EdFiNuGetFeed       =$EdFiNuGetFeed
    databasesConfig     =$databasesConfig
    adminAppConfig      =$adminAppConfig
    webApiConfig        =$webApiConfig
    swaggerUIConfig     =$swaggerUIConfig
    amtConfig           =$amtConfig
    bulkLoadClientConfig=$bulkLoadClientConfig
    lmsToolkitConfig    =$lmsToolkitConfig
}
Write-Host "Running Ed-Fi Install-EdFiTechnologySuite.ps1"
& "$PSScriptRoot/Install-EdFiTechnologySuite.ps1" @edfiSuiteParam

# Restart IIS, which also requires stopping the Windows Activation Service.
# This step is necessary in many cases for IIS to recognize and use the newly
# installed .NET Core Hosting Bundle
Stop-Service -name was -Force -Confirm:$False
Start-Service -name w3svc
Write-Host "Creating Ed-Fi Starter Kit parameter..."
$starterKitParam= @{
    lmsToolkitConfig            = $configuration.lmsToolkitConfig
    databasesConfig             = $configuration.databasesConfig
    ApiUrl                      = "https://$($env:computername)/$($configuration.webApiConfig.webApplicationName)"
    ToolsPath                   = "$($configuration.downloadDirectory)\tools"
    ConsoleBulkLoadDirectory    = "$($configuration.bulkLoadClientConfig.installationDirectory)"
    LMSToolkitDirectory         = Join-Path "$($configuration.lmsToolkitConfig.installationDirectory)" "LMS-Toolkit-$($configuration.lmsToolkitConfig.packageDetails.version)"
    WebRoot                     = $configuration.lmsToolkitConfig.webRootFolder
    OdsPlatformVersion          = $configuration.odsPlatformVersion
}
Write-Host "Running Ed-Fi Install-StarterKit.ps1..."
& "$PSScriptRoot/Install-StarterKit.ps1" @starterKitParam