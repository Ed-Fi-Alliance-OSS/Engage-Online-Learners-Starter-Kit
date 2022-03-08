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
.PARAMETER PackageName
    BulkLoader Client Nuget PackageName.
.PARAMETER Version
    BulkLoader Client Nuget PackageVersion.
.PARAMETER InstallDir
    BulkLoader Client Installation directory.
.PARAMETER ToolsPath
    Path for storing installation tools.
.PARAMETER ToolsPath
    BulkLoader Client Nuget PackageVersion.
.PARAMETER edfiSource
    Ed-Fi nuget package feed source.
#>
function Install-ClientBulkLoader {
    param (
        # Nuget package name
        [string]
        $PackageName="EdFi.Suite3.BulkLoadClient.Console",
        
        # Nuget version
        [string]
        $PackageVersion="5.3",
        
        # Installation directory
        [string]
        $InstallDir="C:\\Ed-Fi\\Bulk-Load-Client",
        
        # Path for storing installation tools
        [string]
        $ToolsPath="C:\\temp\\tools",
        
        # Ed-Fi nuget package feed source.
        [string]
        $edfiSource="https://pkgs.dev.azure.com/ed-fi-alliance/Ed-Fi-Alliance-OSS/_packaging/EdFi%40Release/nuget/v3/index.json"
    )

    $params = @{
        PackageVersion = "$PackageVersion"
        PackageName = "$PackageName"
        toolsPath = $toolsPath
        edfiSource = $edfiSource
    }
    # Get nuget version.
    $PackageVersion = Get-NuGetPackageVersion @params

    &dotnet tool install `
        --tool-path $InstallDir `
        --version $packageVersion `
        --add-source $edfiSource `
        $PackageName

    Test-ExitCode
}

Export-ModuleMember Install-ClientBulkLoader
