# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

#Requires -Version 5
#Requires -RunAsAdministrator

<#
    .SYNOPSIS
    Installs third-party components useful for running the Engage Online
    Learners Starter Kit by installing third-party components.

    .DESCRIPTION
    This script fully prepares a stand-alone system to run the software listed
    below. It is not recommended for production installations.

    * Chocolatey
    * .NET Core 3.1 SDK and hosting bundle for IIS
    * Python 3.9 and Poetry
    * SQL Server Express 2019 and SQL Management Studio
    * Google Chrome
    * Microsoft Visual Studio Code
    * Microsoft Power BI Desktop
#>
param (
    # Temporary directory for downloaded components.
    [string]
    $ToolsPath = "$PSScriptRoot/.tools"
)

$ErrorActionPreference = "Stop"

# Disabling the progress report from `Invoke-WebRequest`, which substantially
# slows the download time.
$ProgressPreference = "SilentlyContinue"

New-Item -Path $ToolsPath -ItemType Directory -Force | Out-Null

# Import all needed modules
Import-Module -Name "$PSScriptRoot/modules/Install-Applications.psm1" -Force
Import-Module -Name "$PSScriptRoot/modules/Tool-Helpers.psm1" -Force

Install-Choco

$applicationSetupLog = "$PSScriptRoot/application-setup.log"
Install-DotNet -LogFile $applicationSetupLog
Install-SQLServer -LogFile $applicationSetupLog
Install-VisualStudioCode -LogFile $applicationSetupLog
Install-GoogleChrome -LogFile $applicationSetupLog
Install-PowerBI -LogFile $applicationSetupLog -DownloadPath $ToolsPath
Install-Python -LogFile $applicationSetupLog
Install-Poetry -LogFile $applicationSetupLog

Invoke-RefreshPath
