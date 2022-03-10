# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

#Requires -Version 5
$ErrorActionPreference = "Stop"

Import-Module -Name "$PSScriptRoot/Tool-Helpers.psm1"
Import-Module -Force "$PSScriptRoot\nuget-helper.psm1"

<#
.SYNOPSIS
    Installs the Ed-Fi Databases.
.DESCRIPTION
    Installs the Ed-Fi Databases.
.PARAMETER toolsPath
    Path for storing installation tools.
.PARAMETER downloadPath
    Path for storing downloaded packages.
.PARAMETER databasesConfig
    Hashtable containing information about the databases and its server.

    $databasesConfig= @{
        applicationCredentials = @{
            databaseUser            = ""
            databasePassword        = ""
            useIntegratedSecurity   = $true
        },
        installCredentials = @{
            databaseUser            = ""
            databasePassword        = ""
            useIntegratedSecurity   = $true
        },
        engine              = "SQLServer"
        databaseServer      = "localhost"
        databasePort        = ""
        adminDatabaseName   = "EdFi_Admin"
        odsDatabaseName     = "EdFi_Ods"
        securityDatabaseName= "EdFi_Security"
        useTemplates        = $false
        noDuration          = $false
        dropDatabases       = $true
        apiMode             = "sharedinstance"
        odsDatabaseTemplateName = "populated"
        minimalTemplateSuffix   ="Ods_Minimal_Template"
        populatedTemplateSuffix ="Ods"
        populatedTemplateScript = "GrandBend"
        addAdminUser        = $false
        dbAdminUser         = "edfi",
        dbAdminUserPassword = "edfi",
        packageDetails= @{
            packageName = "EdFi.Suite3.RestApi.Databases"
            version     = "5.3"
        }
    }
.PARAMETER timeTravelScriptPath
    Time Travel Script file path.
.PARAMETER edfiSource
    Ed-Fi nuget package feed source.
#>
function Install-EdFiDbs() {
    [CmdletBinding()]
    param (
        # Path for storing installation tools
        [string] $toolsPath="C:\\temp\\tools",
        
        # Path for storing downloaded packages
        [string] $downloadPath="C:\\temp\\downloads",

        # Hashtable containing information about the databases and its server.
        [Parameter(Mandatory = $true)]
        [Hashtable] $databasesConfig,
        
        # Time Travel Script file path
        [string] $timeTravelScriptPath,
        
        # Ed-Fi nuget package feed source.
        [string]
        $edfiSource="https://pkgs.dev.azure.com/ed-fi-alliance/Ed-Fi-Alliance-OSS/_packaging/EdFi%40Release/nuget/v3/index.json"
    )

    Write-Host "---" -ForegroundColor Magenta
    Write-Host "Ed-Fi Databases module process starting..." -ForegroundColor Magenta
    Write-Host "Ed-Fi Databases engine: $($databasesConfig.engine)"
    $engine = $databasesConfig.engine
    if ($engine -ieq "Postgres") {
        $engine = "PostgreSQL"
    }

    $databasePort       = $databasesConfig.databasePort
    $databaseUser       = $databasesConfig.installCredentials.databaseUser
    $databasePassword   = $databasesConfig.installCredentials.databasePassword
    $useIntegratedSecurity = $databasesConfig.installCredentials.useIntegratedSecurity
    $dropDatabases      = $databasesConfig.dropDatabases
    $noDuration         = $databasesConfig.noDuration

    $packageDetails = @{
        packageName  = "$($databasesConfig.packageDetails.packageName)"
        version      = "$($databasesConfig.packageDetails.version)"
        toolsPath    = $toolsPath
        downloadPath = $downloadPath
        edfiSource   = $edfiSource
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
        SetValue -object $json -key "ConnectionStrings.EdFi_Ods" -value "server=$($databasesConfig.databaseServer);trusted_connection=True;database=$($databasesConfig.odsDatabaseName);Application Name=EdFi.Ods.WebApi"
        SetValue -object $json -key "ConnectionStrings.EdFi_Security" -value "server=$($databasesConfig.databaseServer);trusted_connection=True;database=$($databasesConfig.securityDatabaseName);persist security info=True;Application Name=EdFi.Ods.WebApi"
        SetValue -object $json -key "ConnectionStrings.EdFi_Admin" -value "server=$($databasesConfig.databaseServer);trusted_connection=True;database=$($databasesConfig.adminDatabaseName);Application Name=EdFi.Ods.WebApi"
        SetValue -object $json -key "ConnectionStrings.EdFi_Master" -value "server=$($databasesConfig.databaseServer);trusted_connection=True;database=master;Application Name=EdFi.Ods.WebApi"
    }
    else {
        SetValue -object $json -key "ConnectionStrings.EdFi_Ods" -value "server=$($databasesConfig.databaseServer);user id=$databaseUser;Password=$databasePassword;database=$($databasesConfig.odsDatabaseName);Application Name=EdFi.Ods.WebApi"
        SetValue -object $json -key "ConnectionStrings.EdFi_Security" -value "server=$($databasesConfig.databaseServer);user id=$databaseUser;Password=$databasePassword;database=$($databasesConfig.securityDatabaseName);persist security info=True;Application Name=EdFi.Ods.WebApi"
        SetValue -object $json -key "ConnectionStrings.EdFi_Admin" -value "server=$($databasesConfig.databaseServer);user id=$databaseUser;Password=$databasePassword;database=$($databasesConfig.adminDatabaseName);Application Name=EdFi.Ods.WebApi"
        SetValue -object $json -key "ConnectionStrings.EdFi_Master" -value "server=$($databasesConfig.databaseServer);user id=$databaseUser;Password=$databasePassword;database=master;Application Name=EdFi.Ods.WebApi"
    }
    if($databasesConfig.apiMode){
        Write-host "API MODE $($databasesConfig.apiMode)"
        SetValue -object $json -key "ApiSettings.Mode" -value "$($databasesConfig.apiMode)"
    }
    if($databasesConfig.engine){
        SetValue -object $json -key "ApiSettings.Engine" -value "$($databasesConfig.engine)"
    }
    if($databasesConfig.odsDatabaseTemplateName){
        SetValue -object $json -key "ApiSettings.OdsDatabaseTemplateName" -value "$($databasesConfig.odsDatabaseTemplateName)"
    }
    SetValue -object $json -key "ApiSettings.DropDatabases" -value "$($dropDatabases)"
    if($databasesConfig.minimalTemplateSuffix){
        SetValue -object $json -key "ApiSettings.MinimalTemplateSuffix" -value "$($databasesConfig.minimalTemplateSuffix)"
    }
    if($databasesConfig.populatedTemplateSuffix){
        SetValue -object $json -key "ApiSettings.PopulatedTemplateSuffix" -value "$($databasesConfig.populatedTemplateSuffix)"
    }
    if($databasesConfig.minimalTemplateScript){
        SetValue -object $json -key "ApiSettings.MinimalTemplateScript" -value "$($databasesConfig.minimalTemplateScript)"
    }
    if($databasesConfig.populatedTemplateScript){
        SetValue -object $json -key "ApiSettings.PopulatedTemplateScript" -value "$($databasesConfig.populatedTemplateScript)"
    }
    
    $json | ConvertTo-Json | Out-File (Join-Path $EdFiRepositoryPath "configuration.json")
    write-host "JSON CONFIG: $json"
    $env:toolsPath = (Join-Path (Get-RootPath) 'tools')
   # Although we have no plugins, the install does not react well when the
    # directory does not exist.
    New-Item -Path c:/plugin -Type Directory -Force | Out-Null
    
    Initialize-DeploymentEnvironment 
   
    # Initialize-DeploymentEnvironment -OdsDatabaseTemplateName "populated"
    # Bring the years up to now instead of 2010-2011
    if($timeTravelScriptPath){
        $timeTravelDbConn = @{
            FileName            = $timeTravelScriptPath
            DatabaseServer      = $databasesConfig.databaseServer
            DatabaseUserName    = $databasesConfig.installCredentials.databaseUser
            DatabasePassword    = $databasesConfig.installCredentials.databasePassword
            DatabaseName        = $databasesConfig.odsDatabaseName
        }
        Write-Host "Executing Time Travel script..."
        Invoke-SqlCmdOnODS @timeTravelDbConn
    }
}

function SetValue($object, $key, $Value)
{
    $p1,$p2 = $key.Split(".")
    if($p2) { SetValue -object $object.$p1 -key $p2 -Value $Value }
    else { return $object.$p1 = $Value }
}
Export-ModuleMember Install-EdFiDbs