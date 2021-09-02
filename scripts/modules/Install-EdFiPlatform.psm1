# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

Import-Module -Name "$PSScriptRoot/Tool-Helpers.psm1" -Force

function Install-Databases {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [string]
        $DownloadPath,

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
        $PackageVersion,

        [Parameter(Mandatory=$True)]
        [string]
        $ConfigurationFilePath,

        [Parameter(Mandatory=$True)]
        [string]
        $TimeTravelScriptPath
    )

    $params = @{
        PackageVersion = $PackageVersion
        PackageName  ="EdFi.Suite3.RestApi.Databases"
        NuGetExe = $NuGetExe
        EdFiFeed = $EdFiFeed
        ToolsPath = $ToolsPath
    }
    $databases = Install-NuGetPackage @params

    Import-Module "$databases/Deployment.psm1" -Force -Global

    Copy-Item -Path $ConfigurationFilePath -Destination $databases

    # Although we have no plugins, the install does not react well when the
    # directory does not exist.
    New-Item -Path c:/plugin -Type Directory -Force | Out-Null

    $params = @{
        InstallType = "SharedInstance"
        Engine = "SqlServer"
        DropDatabases = $True
    }
    Initialize-DeploymentEnvironment @params

    # Bring the years up to now instead of 2010-2011
    Invoke-SqlCmdOnODS -File $TimeTravelScriptPath
}

function Install-WebApi {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [string]
        $DownloadPath,

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
        $PackageVersion,

        [Parameter(Mandatory=$True)]
        $WebRoot
    )

    $params = @{
        PackageName = "EdFi.Suite3.Installer.WebApi"
        PackageVersion = $PackageVersion
        NuGetExe = $NuGetExe
        EdFiFeed = $EdFiFeed
    }
    $webApi = Install-NuGetPackage @params -ToolsPath $ToolsPath

    Import-Module "$webApi/Install-EdFiOdsWebApi.psm1" -Force -Global

    $params["PackageName"] = "EdFi.Suite3.Ods.WebApi"
    $PackageVersion = Get-NuGetPackageVersion @params

    $params = @{
        PackageVersion = $PackageVersion
        DownloadPath = $DownloadPath
        ToolsPath = $DownloadPath
        InstallType = "SharedInstance"
        DbConnectionInfo = @{
            Engine="SqlServer"
            Server="localhost"
            UseIntegratedSecurity=$true
        }
        WebSitePath = (Resolve-Path $WebRoot)
    }

    Install-EdFiOdsWebApi @params
}

function Install-Swagger {
    param (
        [Parameter(Mandatory=$True)]
        [string]
        $DownloadPath,

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
        $PackageVersion,

        [Parameter(Mandatory=$True)]
        $WebRoot
    )

    $params = @{
        PackageName = "EdFi.Suite3.Installer.SwaggerUI"
        PackageVersion = $PackageVersion
        NuGetExe = $NuGetExe
        EdFiFeed = $EdFiFeed
    }
    $swagger = Install-NuGetPackage @params -ToolsPath $ToolsPath

    Import-Module "$swagger/Install-EdFiOdsSwaggerUI.psm1" -Force -Global

    $params["PackageName"] = "EdFi.Suite3.Ods.SwaggerUI"
    $PackageVersion = Get-NuGetPackageVersion @params

    $params = @{
        PackageVersion = $PackageVersion
        DownloadPath = $DownloadPath
        ToolsPath = $DownloadPath
        WebApiVersionUrl = "https://$(hostname)/WebApi"
        DisablePrepopulatedCredentials = $True
        WebSitePath = (Resolve-Path $WebRoot)
    }

    Install-EdFiOdsSwaggerUI @params
}

function Install-ClientBulkLoader {
    param (
        [Parameter(Mandatory=$True)]
        [string]
        $NuGetExe,

        [Parameter(Mandatory=$True)]
        [string]
        $EdFiFeed,

        [Parameter(Mandatory=$True)]
        [string]
        $PackageVersion,

        [Parameter(Mandatory=$True)]
        [string]
        $InstallDir
    )

    $params = @{
        PackageVersion = $PackageVersion
        PackageName = "EdFi.Suite3.BulkLoadClient.Console"
        NuGetExe = $NuGetExe
        EdFiFeed = $EdFiFeed
    }

    $PackageVersion = Get-NuGetPackageVersion @params

    &dotnet tool install `
        --tool-path $InstallDir `
        --version $packageVersion `
        --add-source $EdFiFeed `
        EdFi.Suite3.BulkLoadClient.Console

    Test-ExitCode
}

function Install-AdminApp {
    param (
        [Parameter(Mandatory=$True)]
        [string]
        $DownloadPath,

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
        $PackageVersion,

        [Parameter(Mandatory=$True)]
        $WebRoot
    )

    $params = @{
        PackageName = "EdFi.Suite3.Installer.AdminApp"
        PackageVersion = $PackageVersion
        NuGetExe = $NuGetExe
        EdFiFeed = $EdFiFeed
    }
    $adminApp = Install-NuGetPackage @params -ToolsPath $ToolsPath

    Import-Module "$adminApp/Install-EdFiOdsAdminApp.psm1" -Force -Global

    $params["PackageName"] = "EdFi.Suite3.Ods.AdminApp"
    $PackageVersion = Get-NuGetPackageVersion @params

    $params = @{
        PackageVersion = $packageVersion
        DownloadPath = $DownloadPath
        ToolsPath = $DownloadPath
        DbConnectionInfo = @{
            Engine="SqlServer"
            Server="localhost"
            UseIntegratedSecurity=$true
        }
        OdsDatabaseName = "EdFi_Ods"
        OdsApiUrl = "https://$(hostname)/WebApi"
        AdminAppFeatures = @{
            ApiMode = "SharedInstance"
        }
        WebSitePath = (Resolve-Path $WebRoot)
    }

    Install-EdFiOdsAdminApp @params
}

function Install-AnalyticsMiddleTier {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [string]
        $DownloadPath,

        [string]
        $AmtOptions = "RLS",

        [string]
        $BranchOrTag = "main"
    )

    Write-Host "Installing the Analytics Middle Tier"

    # Download the AMT source
    $amtZip = "$DownloadPath/amt.zip"
    try {
        # ... first assume that a branch name was given
        $url = "https://github.com/Ed-Fi-Alliance-OSS/Ed-Fi-Analytics-Middle-Tier/archive/refs/heads/$BranchOrTag.zip"
        Invoke-RestMethod -Uri $url -OutFile $amtZip
    }
    catch {
        # ... now try treating as a tag instead, and if it fails, let it bubble up
        $url = "https://github.com/Ed-Fi-Alliance-OSS/Ed-Fi-Analytics-Middle-Tier/archive/refs/tags/$BranchOrTag.zip"
        Invoke-RestMethod -Uri $url -OutFile $amtZip
    }

    Invoke-RestMethod -Uri $url -OutFile $amtZip
    Expand-Archive -Path $amtZip -Destination $DownloadPath -Force
    $amtDirectory = "$DownloadPath/Ed-Fi-Analytics-Middle-Tier-$BranchOrTag"

    # Install the core collection, plus: Engage, EWS, RLS, and Indexes
    $sln = "$amtDirectory/src/EdFi.AnalyticsMiddleTier.sln"
    $proj = "$amtDirectory/src/EdFi.AnalyticsMiddleTier.Console/EdFi.AnalyticsMiddleTier.Console.csproj"
    &dotnet restore $sln
    Test-ExitCode
    &dotnet build $sln
    Test-ExitCode

    # AMT does not like the way that the options come through when you just
    # run something like
    #     dotnet run --connectionString $connString --options $AmtOptions
    # The argument parser can't handle something about the way the options come
    # through. A work around is to create the entire command as a string and
    # then invoke it as an expression.
    $connString = "server=localhost;database=EdFi_ODS;integrated security=SSPI"
    $command = "&dotnet run -p $proj --connectionString '$connstring' --options $AmtOptions"
    Write-Host -ForegroundColor Magenta -Object $command
    Invoke-Expression $command
    Test-ExitCode
}

Export-ModuleMember *
