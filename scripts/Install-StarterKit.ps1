# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

#Requires -Version 5
#Requires -RunAsAdministrator

<#
    .SYNOPSIS
    Installs Ed-Fi branding and other components required for a
    Engage Online Learners Starter Kit "quick start" machine.

    .DESCRIPTION
    This script performs the following actions:

    * Loads sample LMS data to augment the "Grand Bend" populated template
    * Installs a landing page with help information, along with a desktop
      shortcut
    * Installs an Ed-Fi branded desktop wallpaper image
    * Downloads the latest starter kit Power BI file on the desktop

    Assumes that you have already downloaded and installed the LMS Toolkit
    
    .PARAMETER lmsToolkitConfig
    Hashtable containing LMS Toolkit settings and installation directory.
    $lmsToolkitConfig= @{
        installLMSToolkit= $true
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
    .PARAMETER databasesConfig
    Hashtable containing information about the databases and its server.
    $databasesConfig= @{
        installDatabases= $true
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
        useTemplates= $false
        noDuration= $false
        dropDatabases= $true
        apiMode= "sharedinstance"
    }
    
    .PARAMETER ApiUrl
    Ed-Fi Web API URL
    
    .PARAMETER ToolsPath
    Temporary directory for downloaded components.
 
    .PARAMETER ConsoleBulkLoadDirectory
    The directory in which the Console Bulk Loader was downloaded

    .PARAMETER LMSToolkitDirectory
    The directory in which the LMS Toolkit was downloaded and installed.
   
    .PARAMETER webRootFolder
    Root directory for web applications.
    
    .PARAMETER OdsPlatformVersion
    ODS Version
#>
param (
    # Hashtable containing LMS Toolkit settings and installation directory.
    [Hashtable]
    $lmsToolkitConfig=@{
        installLMSToolkit= $true
        installationDirectory= "C:\\Ed-Fi\\"
        webRootFolder= "c:\\inetpub\\Ed-Fi"
        pathToWorkingDir= "C:\\Ed-Fi\\QuickStarts\\LMS-Toolkit"
        packageDetails= @{
            packageURL= "https://github.com/Ed-Fi-Alliance-OSS/LMS-Toolkit"
            version= "main"
        }     
        sampleData= @{
            key= "dfghjkl34567"
            secret= "4eryftgjh-pok%^K```$E%RTYG"
        }
    },
    
    # Hashtable containing information about the databases and its server.
    [Hashtable]
    $databasesConfig= @{
        installDatabases= $true
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
        useTemplates= $false
        noDuration= $false
        dropDatabases= $true
        apiMode= "sharedinstance"
    },
    
    [string]
    $ApiUrl="https://$($env:computername)/WebApi",
    
    # Temporary directory for downloaded components.
    [string]
    $ToolsPath = "$PSScriptRoot/.tools",

    # The directory in which the Console Bulk Loader was downloaded
    [string]
    $ConsoleBulkLoadDirectory = "C:/Ed-Fi/Bulk-Load-Client",

    # The directory in which the LMS Toolkit was downloaded and installed.
    [string]
    $LMSToolkitDirectory = "c:/ed-fi/LMS-Toolkit-main",

    # Root directory for web applications.
    [string]
    $webRootFolder = "c:/inetpub/Ed-Fi",
    
    [string]
    $OdsPlatformVersion = "5.3"    
)
$ErrorActionPreference = "Stop"

# Import all needed modules
Import-Module -Name "$PSScriptRoot/modules/Tool-Helpers.psm1" -Force
Import-Module -Name "$PSScriptRoot/modules/Install-LMSToolkit.psm1" -Force
Import-Module -Name "$PSScriptRoot/modules/Install-AdditionalSampleData.psm1" -Force

function Install-LandingPage {
    Write-Host "Installing the landing page"
    Copy-Item -Path "$PSScriptRoot/../vm-docs/*" -Destination $webRootFolder

    $new_object = New-Object -ComObject WScript.Shell
    $destination = $new_object.SpecialFolders.Item("AllUsersDesktop")
    $source_path = Join-Path -Path $destination -ChildPath "Start Here.url"

    $Shortcut = $new_object.CreateShortcut($source_path)
    try {
        # For unknown reasons, some systems do not recognize the following
        $Shortcut.IconLocation = "$webRootFolder/favicon.ico"
    }
    catch {
        # Ignore any error that occurs
    }
    $Shortcut.TargetPath = "https://$(hostname)/"
    $Shortcut.Save()
}

function Set-WallPaper {
    Write-Output "Installing Ed-Fi wallpaper image"

    $url = "https://edfidata.s3-us-west-2.amazonaws.com/Starter+Kits/images/EdFiQuickStartBackground.png"
    Invoke-WebRequest -Uri $url -OutFile "c:/EdFiQuickStartBackground.png"

    Set-ItemProperty -path "HKCU:\Control Panel\Desktop" -name WallPaper -value "c:/EdFiQuickStartBackground.png"
    Set-ItemProperty -path "HKCU:\Control Panel\Desktop" -name WallpaperStyle -value "0" -Force
    &rundll32.exe user32.dll, UpdatePerUserSystemParameters
}

function Invoke-LoadSampleData {
    Install-LMSSampleData -LmsDirectory $LMSToolkitDirectory

    $bulkLoadExe = Join-Path "$($ConsoleBulkLoadDirectory)" "EdFi.BulkLoadClient.Console.exe"

    $params = @{
        lmsToolkitConfig = $lmsToolkitConfig
        databasesConfig = $databasesConfig
        ApiUrl =$ApiUrl
        BulkLoadExe = $bulkLoadExe
        UsingPlatformVersion52 = ($OdsPlatformVersion -eq "5.2")
    }

    Invoke-BulkLoadInternetAccessData @params
}

function Copy-PowerBiFileToDesktop {
    # Copy the Power BI file to the desktop for easy discoverability
    $pbix = "$PSScriptRoot/../StudentEngagementDashboard.pbix"
    Copy-Item -Path $pbix -Destination "$env:USERPROFILE/Desktop"
}

Invoke-LoadSampleData
Set-WallPaper
Install-LandingPage
Copy-PowerBiFileToDesktop
