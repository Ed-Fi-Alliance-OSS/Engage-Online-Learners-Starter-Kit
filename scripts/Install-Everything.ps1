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
    $ToolsPath = "$PSScriptRoot/.tools"
    

)
$global:ErrorActionPreference = "Stop"
$global:ProgressPreference = "SilentlyContinue"
$configPath = "$PSScriptRoot\configuration.json"
Import-Module -Force "$PSScriptRoot\confighelper.psm1"
$configuration = Format-ConfigurationFileToHashTable $configPath
Import-Module -Name "$PSScriptRoot/modules/Configure-Windows.psm1" -Force

Set-TLS12Support
Set-ExecutionPolicy bypass -Scope CurrentUser -Force;

& "$PSScriptRoot/Install-ThirdPartyApplications.ps1" -ToolsPath $ToolsPath
Write-Host "Adding EdFi Suite parameter"
$edfiSuiteParam=@{
    InstallPath=$configuration.installDirectory
    WebRoot=$configuration.webSiteName
    downloadPath=$configuration.downloadDirectory
    EdFiNuGetFeed=$configuration.EdFiNuGetFeed
    databasesConfig=$configuration.databasesConfig
    adminAppConfig=$configuration.adminAppConfig
    webApiConfig=$configuration.webApiConfig
    swaggerUIConfig=$configuration.swaggerUIConfig
    amtConfig=$configuration.amtConfig
    bulkLoadClientConfig=$configuration.bulkLoadClientConfig
    lmsToolkitConfig=$configuration.lmsToolkitConfig
}
& "$PSScriptRoot/Install-EdFiTechnologySuite.ps1" @edfiSuiteParam

# Restart IIS, which also requires stopping the Windows Activation Service.
# This step is necessary in many cases for IIS to recognize and use the newly
# installed .NET Core Hosting Bundle
Stop-Service -name was -Force -Confirm:$False
Start-Service -name w3svc

$starterKitParam= @{
    lmsToolkitConfig=$configuration.lmsToolkitConfig
    databasesConfig=$configuration.databasesConfig
    ApiUrl="https://$($env:computername)/$($configuration.webApiConfig.webApplicationName)"
    ToolsPath = "$($configuration.downloadDirectory)\tools"
    ConsoleBulkLoadDirectory = "$($configuration.bulkLoadClientConfig.installationDirectory)"
    LMSToolkitDirectory = Join-Path "$($configuration.lmsToolkitConfig.installationDirectory)" "LMS-Toolkit-$($configuration.lmsToolkitConfig.version)"
    WebRoot = $configuration.lmsToolkitConfig.webRootFolder
    OdsPlatformVersion = $configuration.odsPlatformVersion
}

& "$PSScriptRoot/Install-StarterKit.ps1" @starterKitParam