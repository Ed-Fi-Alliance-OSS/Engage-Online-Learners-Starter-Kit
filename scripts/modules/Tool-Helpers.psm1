# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"


$NuGetInstaller = "https://dist.nuget.org/win-x86-commandline/v5.3.1/nuget.exe"

function Install-NugetCli {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [string]
        $ToolsPath
    )

    if (-not $(Test-Path $ToolsPath)) {
        mkdir $ToolsPath | Out-Null
    }

    $NugetExe = "$ToolsPath/nuget.exe"

    if (-not $(Test-Path $NugetExe)) {
        Write-Host "Downloading nuget.exe official distribution from " $NuGetInstaller
        Invoke-RestMethod -Uri $NuGetInstaller -OutFile $NugetExe
    }
    else {
        $info = Get-Command $NugetExe
        Write-Host "Found nuget exe in: $toolsPath"

        if ("5.3.1.0" -ne $info.Version.ToString()) {
            Write-Host "Updating nuget.exe official distribution from " $NuGetInstaller
            Invoke-RestMethod -Uri $NuGetInstaller -OutFile $NugetExe
        }
    }

    return $NugetExe
}

function Get-NuGetPackageVersion {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [string]
        $EdFiFeed,

        [Parameter(Mandatory=$True)]
        [string]
        $NuGetExe,

        [Parameter(Mandatory=$True)]
        [string]
        $PackageName,

        [Parameter(Mandatory=$True)]
        [string]
        $PackageVersion
    )
    Write-Host "Looking latest patch of $PackageName version $PackageVersion"

    # If version is provided with just Major.Minor, then lookup all
    # available versions and find the latest patch for that release
    if ($PackageVersion -match "^\d\.\d$") {
        $params = @(
            "list",
            "-Source", $EdFiFeed,
            "-AllVersions",
            $PackageName
        )

        Write-Host $NugetExe @params
        $response = &$NuGetExe @params

        $response -Split [Environment]::NewLine | ForEach-Object {
            $v = ($_ -Split " ")[1]

            if ($v -match "$PackageVersion\.\d") {
                $PackageVersion = $v
            }
        }
    }

    return $PackageVersion
}

function Install-NuGetPackage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [string]
        $ToolsPath,

        [Parameter(Mandatory=$True)]
        [string]
        $NuGetExe,

        [Parameter(Mandatory=$True)]
        [string]
        $EdFiFeed,

        [Parameter(Mandatory=$True)]
        [string]
        $PackageName,

        [Parameter(Mandatory=$True)]
        [string]
        $PackageVersion
    )

    $params = @{
        NuGetExe = $NuGetExe
        EdFiFeed = $EdFiFeed
        PackageName = $PackageName
        PackageVersion = $PackageVersion
    }
    $PackageVersion = Get-NuGetPackageVersion @params

    $params = @(
        "install",
        "-Source", $EdFiFeed,
        "-OutputDirectory", $ToolsPath,
        "-Version", $PackageVersion,
        $PackageName
    )

    Write-Host "Installing package $PackageName version $PackageVersion"
    &$NugetExe @params | Out-Host

    return "$ToolsPath/$PackageName.$PackageVersion"
}

function Invoke-SqlCmdOnODS {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [string]
        $FileName
    )

    &sqlcmd -S localhost -E -d EdFi_ODS_2022 -b -i $FileName
}

Export-ModuleMember *
