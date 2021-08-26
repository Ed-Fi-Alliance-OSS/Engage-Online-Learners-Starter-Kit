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
$WebRoot = "C:/inetpub/Ed-Fi"
$skDir = "$EdFiDir/Engage-Online-Learners-Starter-Kit-main"
$skDataDir = "$skDir/data"

Function Get-StarterKitFiles {
    Write-Host "Downloading additional starter kit files"

    $file = "$skDir.zip"

    if (-not (Test-Path $file) -or $Force) {
        $uri = "https://github.com/Ed-Fi-Alliance-OSS/Student-Engagement-Starter-Kit/archive/refs/heads/main.zip"
        Invoke-RestMethod -Uri $uri -OutFile $file
    }

    Expand-Archive -Path $file -DestinationPath $skDir -Force
}

Function Install-LandingPage {
    Write-Host "Installing the landing page"

    Copy-Item -Path "$skDir/vm-docs/*" -Destination $WebRoot

    $new_object = New-Object -ComObject WScript.Shell
    $destination = $new_object.SpecialFolders.Item("AllUsersDesktop")
    $source_path = Join-Path -Path $destination -ChildPath "Start Here.url"

    $Shortcut = $new_object.CreateShortcut($source_path)
    $Shortcut.TargetPath = "https://$(hostname)/"
    $Shortcut.Save()
}

Function Invoke-BulkLoadInternetAccessData {
    Write-Host "Uploading additional sample data"

    $bulkTemp = "./bulk-temp"
    New-Item -Path $bulkTemp -ItemType Directory -Force | Out-Null

    $bulkLoader = "C:/Ed-Fi/Bulk-Load-Client/EdFi.BulkLoadClient.Console.exe"

    # Download the XSD
    $xsdUrl = "https://raw.githubusercontent.com/Ed-Fi-Alliance-OSS/Ed-Fi-ODS/v5.2/Application/EdFi.Ods.Standard/Artifacts/Schemas"
    $schemas = "./schemas"
    New-Item -Path $schemas -ItemType Directory -Force | Out-Null

    @(
        "Ed-Fi-Core.xsd",
        "Interchange-AssessmentMetadata.xsd",
        "Interchange-Descriptors.xsd",
        "Interchange-EducationOrgCalendar.xsd",
        "Interchange-EducationOrganization.xsd",
        "Interchange-Finance.xsd",
        "Interchange-MasterSchedule.xsd",
        "Interchange-Parent.xsd",
        "Interchange-PostSecondaryEvent.xsd",
        "Interchange-StaffAssociation.xsd",
        "Interchange-Standards.xsd",
        "Interchange-Student.xsd",
        "Interchange-StudentAssessment.xsd",
        "Interchange-StudentAttendance.xsd",
        "Interchange-StudentCohort.xsd",
        "Interchange-StudentEnrollment.xsd",
        "Interchange-StudentGrade.xsd",
        "Interchange-StudentGradebook.xsd",
        "Interchange-StudentIntervention.xsd",
        "Interchange-StudentProgram.xsd",
        "Interchange-StudentTranscript.xsd",
        "Interchange-Survey.xsd",
        "SchemaAnnotation.xsd"
    ) | ForEach-Object {
        $xsdOut = "./$schemas/$_"
        Invoke-RestMethod -Uri "$xsdUrl/$_" -OutFile $xsdOut
    }

    # Need to automate the process of getting a key and secret for the bulk
    # loader to upload the XML file.
    $params = @{
        Database = "EdFi_Admin"
        HostName = "localhost"
        InputFile = Resolve-Path -Path "./bulk-api-client.sql"
        OutputSqlErrors = $True
    }
    Invoke-SqlCmd @params

    $key = "consoleBulkLoader"
    $secret = "consoleBulkLoaderSecret"
    $year = "2022"
    $url = "https://$(hostname)/WebApi"

    $params = @(
        "-b", $url,
        "-d", (Resolve-Path -Path $skDataDir),
        "-k", $key,
        "-s", $secret,
        "-w", (Resolve-Path -Path $bulkTemp),
        "-x", (Resolve-Path -Path $schemas),
        "-y", $year
    )

    Write-Host -ForegroundColor Magenta "Executing: $bulkLoader " @params
    &$bulkLoader @params
}

function Set-WallPaper {
    Write-Output "Installing Ed-Fi wallpaper image"

    $url = "https://edfidata.s3-us-west-2.amazonaws.com/Starter+Kits/images/EdFiQuickStartBackground.png"
    Invoke-WebRequest -Uri $url -OutFile "c:/EdFiQuickStartBackground.png"

    Set-ItemProperty -path "HKCU:\Control Panel\Desktop" -name WallPaper -value "c:/EdFiQuickStartBackground.png"
    Set-ItemProperty -path "HKCU:\Control Panel\Desktop" -name WallpaperStyle -value "0" -Force
    rundll32.exe user32.dll, UpdatePerUserSystemParameters
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

Set-WallPaper

Get-StarterKitFiles
Invoke-BulkLoadInternetAccessData
Install-LandingPage

# Move the Power BI file to the desktop
$pbix = "$skDir/StudentEngagementDashboard.pbix"
Move-Item -Path $pbix -Destination "$env:USERPROFILE/Desktop"

# Restore the progress reporting
$ProgressPreference = "Continue"
