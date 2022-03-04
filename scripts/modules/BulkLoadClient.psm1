# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

#Requires -Version 5
#Requires -RunAsAdministrator
param(
    [parameter(Position=0,Mandatory=$true)][Hashtable]$configuration
)
Import-Module -force "$PSScriptRoot\nuget-helper.psm1" -ArgumentList $configuration
$ErrorActionPreference = "Stop"
<#
.SYNOPSIS
    Installs the BulkLoader Client.
.DESCRIPTION
    Installs the BulkLoader Client.
#>
function Install-ClientBulkLoader {
    param (
        [Parameter(Mandatory=$True)]
        [string]
        $PackageName,
        [Parameter(Mandatory=$True)]
        [string]
        $PackageVersion,
        [Parameter(Mandatory=$True)]
        [string]
        $InstallDir,
        [Parameter(Mandatory=$True)]
        [string]
        $ToolsPath
    )

    $params = @{
        PackageVersion = "$PackageVersion"
        PackageName = "$PackageName"
        toolsPath = $toolsPath
   }
    
    $PackageVersion = Get-NuGetPackageVersion @params
    $EdFiFeed = Get-EdFiFeed
    &dotnet tool install `
        --tool-path $InstallDir `
        --version $packageVersion `
        --add-source $EdFiFeed `
        $PackageName

    Test-ExitCode
}

Export-ModuleMember Install-ClientBulkLoader
