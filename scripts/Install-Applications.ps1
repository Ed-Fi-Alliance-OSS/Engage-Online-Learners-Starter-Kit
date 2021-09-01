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

    Please review the script files above for more information on the actions
    they take.
#>
param (
    # Temporary directory for downloaded components.
    [string]
    $ToolsPath = "$PSScriptRoot/.tools",

    # Major and minor software version number (x.y format) for the ODS/API platform
    # components: Web API, SwaggerUI, Client Side Bulk Loader.
    [string]
    $OdsPlatformVersion = "5.2",

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
$global:ProgressPreference = "SilentlyContinue"

Import-Module -Name "$PSScriptRoot/modules/Configure-Windows.psm1" -Force

Set-TLS12Support
Set-ExecutionPolicy bypass -Scope CurrentUser -Force;

./Install-ThirdPartyApplications.ps1 -ToolsPath $ToolsPath

./Install-EdFiTechnologySuite.ps1 -PlatformVersion $OdsPlatformVersion `
    -AdminAppVersion $AdminAppVersion `
    -InstallPath $InstallPath `
    -WebRoot $WebRoot `
    -AnalyticsMiddleTierVersion $AnalyticsMiddleTierVersion `
    -EdFiNuGetFeed $EdFiNuGetFeed

# NOTE: an astute reader might wonder why we're not calling Install-StarterKit.ps1 here.
# The reason is simple: the scripts above install some tools that are required for
# the full starter kit install and... sadly... require a reboot.

Write-Host @"
All of the initial components have been installed. Now we need to finish installing the
Starter Kit specific components, one of which is sample data. Loading the sample data
requires accessing the running API; the API relies on the .NET Core Hosting Bundle;
and the hosting bundle does not work on some VM's without a restart. Next steps:

1. Restart your virtual machine
2. Run `Install-StarterKit.ps1`
3. Check out the "Start Here" shortcut on the desktop.
"@
