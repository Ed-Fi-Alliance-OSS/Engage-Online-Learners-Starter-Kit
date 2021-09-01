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

    * Ed-Fi ODS/API for Suite 3, version 5.2
    * Ed-Fi Client Side Bulk Loader for Suite 3, version 5.2
    * Ed-Fi SwaggerUI for Suite 3, version 5.2
    * Ed-Fi ODS Admin App for Suite 3, version 2.2
    * Ed-Fi Analytics Middle Tier, latest development work (`main` branch)
    * Ed-Fi LMS Toolkit, latest development work (`main` branch).

    Note: the Analytics Middle Tier and LMS Toolkit are installed from the
    `main` branch by default because these are the primary two systems
    that are under development to support this Starter Kit. Experimentally,
    you can change the versions to any tag from those code repositories and
    the install process will alternately download that tag instead of `main`.
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

    # Root directory for downloads and tool installation
    [string]
    $InstallPath = "c:/Ed-Fi",

    # Root directory for web application installs.
    [string]
    $WebRoot = "c:/inetpub/Ed-Fi",

    # Branch or tag to use when installing the Analytics Middle Tier.
    [string]
    $AnalyticsMiddleTierVersion = "main",

    # Branch or tag to use when installing the LMS Toolkit.
    [string]
    $LMSToolkitVeresion = "main",

    # NuGet Feed for Ed-Fi pacakges
    [string]
    $EdFiNuGetFeed = "https://pkgs.dev.azure.com/ed-fi-alliance/Ed-Fi-Alliance-OSS/_packaging/EdFi%40Release/nuget/v3/index.json"
)

$global:ErrorActionPreference = "Stop"

# Disabling the progress report from `Invoke-WebRequest`, which substantially
# slows the download time.
$global:ProgressPreference = "SilentlyContinue"

# Create a few directories
New-Item -Path $InstallPath -ItemType Directory -Force | Out-Null
New-Item -Path $WebRoot -ItemType Directory -Force | Out-Null

# Import all needed modules
Import-Module -Name "$PSScriptRoot/modules/Tool-Helpers.psm1" -Force
Import-Module -Name "$PSScriptRoot/modules/Configure-Windows.psm1" -Force
Import-Module -Name "$PSScriptRoot/modules/Install-EdFiPlatform.psm1" -Force
Import-Module -Name "$PSScriptRoot/modules/Install-LMSToolkit.psm1" -Force

# Setup Windows, required tools, frameworks, and user applications
Invoke-RefreshPath
Enable-LongFileNames
$NuGetExe = Install-NugetCli -ToolsPath $InstallPath

# Install Components from the Ed-Fi platform
$common = @{
    DownloadPath = $InstallPath
    NuGetExe = $NuGetExe
    PackageVersion = $PlatformVersion
    EdFiFeed = $EdFiNuGetFeed
    ToolsPath = $InstallPath
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
    EdFiFeed = $EdFiNuGetFeed
    PackageVersion = $PlatformVersion
    InstallDir = "$InstallPath/Bulk-Load-Client"
    NuGetExe = $NuGetExe
}
Install-ClientBulkLoader @params

# Now install the LMS Toolkit.
$params = @{
    DownloadPath = $InstallPath
    InstallDir = $InstallPath
    BranchOrTag = $LMSToolkitVeresion
}
Install-LMSToolkit @params

# Analytics MiddleTier *must* come after the LMS Toolkit
$params = @{
    AmtOptions = "EWS RLS Indexes Engage"
    DownloadPath = $InstallPath
    BranchOrTag = $AnalyticsMiddleTierVersion
}
Install-AnalyticsMiddleTier @params
