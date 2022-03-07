# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

#Requires -Version 5
Import-Module -force "$PSScriptRoot\nuget-helper.psm1"
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
        $ToolsPath,
        [Parameter(Mandatory=$True)]
        [string]
        $edfiSource
    )

    $params = @{
        PackageVersion = "$PackageVersion"
        PackageName = "$PackageName"
        toolsPath = $toolsPath
        edfiSource = $edfiSource
   }
    
    $PackageVersion = Get-NuGetPackageVersion @params

    &dotnet tool install `
        --tool-path $InstallDir `
        --version $packageVersion `
        --add-source $edfiSource `
        $PackageName

    Test-ExitCode
}

Export-ModuleMember Install-ClientBulkLoader
