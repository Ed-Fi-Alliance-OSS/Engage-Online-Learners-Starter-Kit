# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

#Requires -Version 5
#Requires -RunAsAdministrator

<#
    .SYNOPSIS
    Prepare a single-server environment for running the Engage Online Learners
    Starter Kit.

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

    Third party components:

    * Chocolatey
    * .NET Core 3.1 SDK and hosting bundle
    * Python 3.9 and Poetry
    * SQL Server Express 2019 and SQL Management Studio
    * Google Chrome
    * Microsoft Visual Studio Code
    * Microsoft Power BI Desktop

    Ed-Fi software:

    * Ed-Fi ODS/API for Suite 3, version 5.2
    * Ed-Fi Client Side Bulk Loader for Suite 3, version 5.2
    * Ed-Fi SwaggerUI for Suite 3, version 5.2
    * Ed-Fi ODS Admin App for Suite 3, version 2.2
    * Ed-Fi Analytics Middle Tier, latest development work (`main` branch)
    * Ed-Fi LMS Toolkit, latest development work (`main` branch).
#>
param (
    # Major and minor software version number (x.y format) for the ODS/API platform
    # components: Web API, SwaggerUI, Client Side Bulk Loader.
    [string]
    $PlatformVersion = "5.2",

    # Major and minor software software version number (x.y format) for the ODS
    # Admin App.
    [string]
    $AdminAppVersion = "2.2",

    # Temporary directory for downloaded components.
    [string]
    $ToolsPath = "$PSScriptRoot/.tools"
)

$ErrorActionPreference = "Stop"

# Disabling the progress report from `Invoke-WebRequest`, which substantially
# slows the download time.
$ProgressPreference = "SilentlyContinue"

# Constants
$EdFiFeed = "https://pkgs.dev.azure.com/ed-fi-alliance/Ed-Fi-Alliance-OSS/_packaging/EdFi%40Release/nuget/v3/index.json"
$EdFiDir = "C:/Ed-Fi"
$WebRoot = "c:/inetpub/Ed-Fi"

# Create a few directories
New-Item -Path $EdFiDir -ItemType Directory -Force | Out-Null
New-Item -Path $WebRoot -ItemType Directory -Force | Out-Null

# Import all needed modules
Import-Module -Name "$PSScriptRoot/modules/Tool-Helpers.psm1" -Force
Import-Module -Name "$PSScriptRoot/modules/Configure-Windows.psm1" -Force
Import-Module -Name "$PSScriptRoot/modules/Install-Applications.psm1" -Force
Import-Module -Name "$PSScriptRoot/modules/Install-EdFiPlatform.psm1" -Force
Import-Module -Name "$PSScriptRoot/modules/Install-LMSToolkit.psm1" -Force

# Setup Windows, required tools, frameworks, and user applications
Enable-LongFileNames
Set-TLS12Support
Set-ExecutionPolicy bypass -Scope CurrentUser -Force;
$NuGetExe = Install-NugetCli -ToolsPath $ToolsPath
Install-Choco

$applicationSetupLog = "application-setup.log"
Install-DotNet -LogFile $applicationSetupLog
Install-SQLServer -LogFile $applicationSetupLog
Install-VisualStudioCode -LogFile $applicationSetupLog
Install-GoogleChrome -LogFile $applicationSetupLog
Install-PowerBI -LogFile $applicationSetupLog -DownloadPath $ToolsPath

# The install steps above don't fully setup the _current_ shell's
# path, so we need to take care of it manually.
$env:PATH="$env:PATH;C:\Program Files\dotnet\;C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\"

# Install Components from the Ed-Fi platform
$common = @{
    DownloadPath = $ToolsPath
    NuGetExe = $NuGetExe
    PackageVersion = $PlatformVersion
    EdFiFeed = $EdFiFeed
    ToolsPath = $ToolsPath
}
Install-Databases @common `
    -ConfigurationFilePath "$PSScriptRoot/configuration.json"  `
    -TimeTravelScriptPath "$PSScriptRoot/time-travel.sql"

$common["WebRoot"] = $WebRoot
Install-WebApi @common
Install-Swagger @common

$common["PackageVersion"] = $AdminAppVersion
Install-AdminApp @common

$params = @{
    EdFiFeed = $EdFiFeed
    PackageVersion = $PlatformVersion
    InstallDir = "$EdFiDir/Bulk-Load-Client"
    NuGetExe = $NuGetExe
}
Install-ClientBulkLoader @params

# Now install the LMS Toolkit.
Install-Python
Install-Poetry

$params = @{
    DownloadPath = $ToolsPath
    InstallDir = $EdFiDir
}
Install-LMSToolkit @params

# Analytics MiddleTier *must* come after the LMS Toolkit
$params = @{
    AmtOptions = "EWS RLS Indexes Engage"
    DownloadPath = $ToolsPath
}
Install-AnalyticsMiddleTier @params

# Restore the progress reporting
$ProgressPreference = "Continue"
