# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

#Requires -Version 5
#Requires -RunAsAdministrator

<#
    .SYNOPSIS
    Fully prepares a virtual machine to run the Ed-Fi branded "quick start".

    .DESCRIPTION
    Runs `install-toolkit.ps1` for application installs; see that script for
    more information on what it installs.

    This script adds the following:

    * Loads sample LMS data to augment the "Grand Bend" populated template
    * Installs a landing page with help information, along with a desktop
      shortcut
    * Installs an Ed-Fi branded desktop wallpaper image
    * Downloads the latest starter kit Power BI file on the desktop
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
    $ToolsPath = "$PSScriptRoot/.tools",

    # Force download of remote files, even if they already exist on the server
    [switch]
    $Force
)

$ErrorActionPreference = "Stop"

# Disabling the progress report from `Invoke-WebRequest`, which substantially
# slows the download time.
$ProgressPreference = "SilentlyContinue"

# Constants
$EdFiDir = "C:/Ed-Fi"
$WebRoot = "$EdFiDir/Web"
$skDir = "$EdFiDir/Starter-Kit-main"

Function Get-StarterKitFiles {
    $file = "$skDir.zip"

    if (-not (Test-Path $file) -or $Force) {
        $uri = "https://github.com/Ed-Fi-Alliance-OSS/Student-Engagement-Starter-Kit/archive/refs/heads/main.zip"
        Invoke-RestMethod -Uri $uri -OutFile $file
    }

    Expand-Archive -Path $file -DestinationPath $skDir -Force
}

Function Install-LandingPage {
    Write-Host "Installing the landing page"

    Copy-Item -Path "$skDir/vm-docs" -Destination $WebRoot -Recurse

    $indexContent = Get-Content -Path "$WebRoot/index.html" -Raw
    $indexContent -replace '@@DOMAINNAME@@', $(hostname) | Out-File -FilePath "$WebRoot/index.html"

    $new_object = New-Object -ComObject WScript.Shell
    $destination = $new_object.SpecialFolders.Item("AllUsersDesktop")
    $source_path = Join-Path -Path $destination -ChildPath "Start Here.url"

    $Shortcut = $new_object.CreateShortcut($source_path)
    $Shortcut.TargetPath = "https://$(hostname)/"
    $Shortcut.Save()
}

Function Move-DashboardToDesktop {
    $pbix = "$skDir/StudentEngagementDashboard.pbix"
    Move-Item -Path $pbix -Destination "$env:USERPROFILE/Desktop"
}

# Create a few directories
New-Item -Path $EdFiDir -ItemType "directory" -Force | Out-Null
New-Item -Path $WebRoot -ItemType Directory -Force | Out-Null

# Import all needed modules
Import-Module -Name "$PSScriptRoot/modules/Tool-Helpers.psm1" -Force
Import-Module -Name "$PSScriptRoot/modules/Configure-Windows.psm1" -Force
Import-Module -Name "$PSScriptRoot/modules/Install-LMSToolkit.psm1" -Force


./install-toolkit.ps1 -PlatformVersion $PlatformVersion -AdminAppVersion $AdminAppVersion -ToolsPath $ToolsPath

Install-LMSSampleData -InstallDir $EdFiDir

Get-StarterKitFiles
Install-LandingPage
Move-DashboardToDesktop

# TODO: in a future ticket, we'll need to download additional sample data for
# student internet access and bulk upload it. Look to Roadrunner work to
# determine how to create an appropriate key and secret.

# Restore the progress reporting
$ProgressPreference = "Continue"
