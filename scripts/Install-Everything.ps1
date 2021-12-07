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
#>
param (
    # Temporary directory for downloaded components.
    [string]
    $ToolsPath = "$PSScriptRoot/.tools",

    # Major and minor software version number (x.y format) for the ODS/API platform
    # components: Web API, SwaggerUI, Client Side Bulk Loader.
    [string]
    $OdsPlatformVersion = "5.3",

    # Major and minor software software version number (x.y format) for the ODS
    # Admin App.
    [string]
    $AdminAppVersion = "2.3",

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

    # NuGet Feed for Ed-Fi packages
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

# Restart IIS, which also requires stopping the Windows Activation Service.
# This step is necessary in many cases for IIS to recognize and use the newly
# installed .NET Core Hosting Bundle
Stop-Service -name was -Force -Confirm:$False
Start-Service -name w3svc

./Install-StarterKit.ps1 `
    -ToolsPath  $ToolsPath `
    -ConsoleBulkLoadDirectory "$InstallPath/Bulk-Load-Client" `
    -LMSToolkitDirectory "$InstallPath/LMS-Toolkit-main" `
    -WebRoot $WebRoot `
    -OdsPlatformVersion $OdsPlatformVersion
