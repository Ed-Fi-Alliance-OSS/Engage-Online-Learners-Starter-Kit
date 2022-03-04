# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

#Requires -Version 5
#Requires -RunAsAdministrator
param(
    [parameter(Position=0,Mandatory=$true)][Hashtable]$configuration
)
$ErrorActionPreference = "Stop"

Import-Module -Name "$PSScriptRoot/Tool-Helpers.psm1" -Force -ArgumentList $configuration
Import-Module -Force "$PSScriptRoot\nuget-helper.psm1"  -ArgumentList $configuration

<#
.SYNOPSIS
    Installs the Ed-Fi Databases.
.DESCRIPTION
    Installs the Ed-Fi Databases.
.EXAMPLE
    PS c:\> Install-EdFiDbs
#>

function SetValue($object, $key, $Value)
{
    $p1,$p2 = $key.Split(".")
    if($p2) { SetValue -object $object.$p1 -key $p2 -Value $Value }
    else { return $object.$p1 = $Value }
}

function Install-EdFiDbs() {
    [CmdletBinding()]
    param (
        [string]
        [Parameter(Mandatory = $true)]
        [string] $toolsPath,
        [string]
        [Parameter(Mandatory = $true)]
        [string] $downloadPath,
        [Hashtable]
        [Parameter(Mandatory = $true)]
        [Hashtable] $databasesConfig,
        [Parameter(Mandatory = $true)]
        [string] $timeTravelScriptPath
    )

    Write-Host "---" -ForegroundColor Magenta
    Write-Host "Ed-Fi Databases module process starting..." -ForegroundColor Magenta
    Write-Host "Ed-Fi Databases engine: $($databasesConfig.engine)"
    $engine = $databasesConfig.engine
    if ($engine -ieq "Postgres") {
        $engine = "PostgreSQL"
    }

    $databasePort = $databasesConfig.databasePort
    $databaseUser = $databasesConfig.installCredentials.databaseUser
    $databasePassword = $databasesConfig.installCredentials.databasePassword
    $useIntegratedSecurity = $databasesConfig.installCredentials.useIntegratedSecurity
    $odsTemplate = $databasesConfig.odsTemplate
    $dropDatabases = $databasesConfig.dropDatabases
    $noDuration = $databasesConfig.noDuration

    $packageDetails = @{
        packageName  = "$($databasesConfig.packageDetails.packageName)"
        version      = "$($databasesConfig.packageDetails.version)"
        toolsPath    = $toolsPath
        downloadPath = $downloadPath
    }

    $EdFiRepositoryPath = Install-EdFiPackage @packageDetails
    $env:PathResolverRepositoryOverride = $pathResolverRepositoryOverride = "Ed-Fi-ODS;Ed-Fi-ODS-Implementation"

    $implementationRepo = $pathResolverRepositoryOverride.Split(';')[1]
    Import-Module -Force -Scope Global "$EdFiRepositoryPath\$implementationRepo\logistics\scripts\modules\path-resolver.psm1"

    Import-Module -Force -Scope Global (Join-Path $EdFiRepositoryPath "Deployment.psm1")
    Import-Module -Force -Scope Global $folders.modules.invoke("tasks\TaskHelper.psm1")

    # Validate arguments
    if (@("SQLServer", "PostgreSQL") -notcontains $engine) {
        write-ErrorAndThenExit "Please configure valid engine name. Valid Input: PostgreSQL or SQLServer."
    }
    if ($engine -eq "SQLServer") {
        if (-not $databasePassword) { $databasePassword = $env:SqlServerPassword }
        if (-not $databasePort) { $databasePort = 1433 }
        if ($useIntegratedSecurity -and ($databaseUser -or $databasePassword)) {
            Write-Info "Will use integrated security even though username and/or password was provided."
        }
        if (-not $useIntegratedSecurity) {
            if (-not $databaseUser -or (-not $databasePassword)) {
                write-ErrorAndThenExit "When not using integrated security, must provide both username and password for SQL Server."
            }
        }
    }
    else {
        if (-not $databasePort) { $databasePort = 5432 }
        if ($databasePassword) { $env:PGPASSWORD = $databasePassword }
    }

    $dbConnectionInfo = @{
        Server                = $databasesConfig.databaseServer
        Port                  = $databasesConfig.databasePort
        UseIntegratedSecurity = $databasesConfig.installCredentials.useIntegratedSecurity
        Username              = $databasesConfig.installCredentials.databaseUser
        Password              = $databasesConfig.installCredentials.databasePassword
        Engine                = $databasesConfig.engine
    }

    $adminDbConnectionInfo = $dbConnectionInfo.Clone()
    $adminDbConnectionInfo.DatabaseName = $databasesConfig.adminDatabaseName

    $odsDbConnectionInfo = $dbConnectionInfo.Clone()
    $odsDbConnectionInfo.DatabaseName = $databasesConfig.odsDatabaseName

    $securityDbConnectionInfo = $dbConnectionInfo.Clone()
    $securityDbConnectionInfo.DatabaseName = $databasesConfig.securityDatabaseName

    Write-Host "Starting installation..." -ForegroundColor Cyan

    #Changing config file
    $json = Get-Content (Join-Path $EdFiRepositoryPath "configuration.json") | ConvertFrom-Json
    if($useIntegratedSecurity){
        SetValue -object $json -key "ConnectionStrings.EdFi_Ods" -value "server=$($configuration.databasesConfig.databaseServer);trusted_connection=True;database=$($configuration.databasesConfig.odsDatabaseName);Application Name=EdFi.Ods.WebApi"
        SetValue -object $json -key "ConnectionStrings.EdFi_Security" -value "server=$($configuration.databasesConfig.databaseServer);trusted_connection=True;database=$($configuration.databasesConfig.securityDatabaseName);persist security info=True;Application Name=EdFi.Ods.WebApi"
        SetValue -object $json -key "ConnectionStrings.EdFi_Admin" -value "server=$($configuration.databasesConfig.databaseServer);trusted_connection=True;database=$($configuration.databasesConfig.adminDatabaseName);Application Name=EdFi.Ods.WebApi"
        SetValue -object $json -key "ConnectionStrings.EdFi_Master" -value "server=$($configuration.databasesConfig.databaseServer);trusted_connection=True;database=master;Application Name=EdFi.Ods.WebApi"
    }
    else {
        SetValue -object $json -key "ConnectionStrings.EdFi_Ods" -value "server=$($configuration.databasesConfig.databaseServer);user id=$databaseUser;Password=$databasePassword;database=$($configuration.databasesConfig.odsDatabaseName);Application Name=EdFi.Ods.WebApi"
        SetValue -object $json -key "ConnectionStrings.EdFi_Security" -value "server=$($configuration.databasesConfig.databaseServer);user id=$databaseUser;Password=$databasePassword;database=$($configuration.databasesConfig.securityDatabaseName);persist security info=True;Application Name=EdFi.Ods.WebApi"
        SetValue -object $json -key "ConnectionStrings.EdFi_Admin" -value "server=$($configuration.databasesConfig.databaseServer);user id=$databaseUser;Password=$databasePassword;database=$($configuration.databasesConfig.adminDatabaseName);Application Name=EdFi.Ods.WebApi"
        SetValue -object $json -key "ConnectionStrings.EdFi_Master" -value "server=$($configuration.databasesConfig.databaseServer);user id=$databaseUser;Password=$databasePassword;database=master;Application Name=EdFi.Ods.WebApi"
    }
    
    SetValue -object $json -key "ApiSettings.Mode" -value "$($configuration.databasesConfig.apiMode)"
    SetValue -object $json -key "ApiSettings.Engine" -value "$($configuration.databasesConfig.engine)"
    SetValue -object $json -key "ApiSettings.DropDatabases" -value "$($dropDatabases)"
    SetValue -object $json -key "ApiSettings.MinimalTemplateScript" -value "$($configuration.databasesConfig.minimalTemplateScript)"
    SetValue -object $json -key "ApiSettings.PopulatedTemplateScript" -value "$($configuration.databasesConfig.populatedTemplateScript)"
    SetValue -object $json -key "ApiSettings.OdsDatabaseTemplateName" -value "$odsTemplate"

    $json | ConvertTo-Json | Out-File (Join-Path $EdFiRepositoryPath "configuration.json")

    $env:toolsPath = (Join-Path (Get-RootPath) 'tools')
    Initialize-DeploymentEnvironment
    # Bring the years up to now instead of 2010-2011
    $timeTravelDbConn = @{
        FileName            = $timeTravelScriptPath
        DatabaseServer      = $databasesConfig.databaseServer
        DatabaseUserName    = $databasesConfig.installCredentials.databaseUser
        DatabasePassword    = $databasesConfig.installCredentials.databasePassword
        DatabaseName        = $databasesConfig.odsDatabaseName
    }

    Invoke-SqlCmdOnODS @timeTravelDbConn
}

Export-ModuleMember Install-EdFiDbs