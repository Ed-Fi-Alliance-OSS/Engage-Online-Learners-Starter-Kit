# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.
#Requires -version 5

$ErrorActionPreference = "Stop"
Import-Module -Name "$PSScriptRoot/Tool-Helpers.psm1" -Force

function Get-SchemaXSDFilesFor52 {
    param (
        [Parameter(Mandatory=$True)]
        [string]
        $SchemaDirectory,
        [Parameter(Mandatory=$True)]
        [Hashtable]
        $bulkLoadClientConfig
    )

    Write-Host "Downloading Schema XSD files"
    $version = $bulkLoadClientConfig.packageODSSchema52Details.version
    $xsdUrl = "$($bulkLoadClientConfig.packageODSSchema52Details.packageUrl)/v$($version)/Application/EdFi.Ods.Standard/Artifacts/Schemas"
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
        $xsdOut = "$SchemaDirectory/$_"
        Invoke-RestMethod -Uri "$xsdUrl/$_" -OutFile $xsdOut
    }
}

function New-BulkClientKeyAndSecret {
    param (
        [Parameter(Mandatory=$True)]
        [Hashtable]
        $lmsToolkitConfig,
        [Parameter(Mandatory=$True)]
        [Hashtable]
        $databasesConfig
    )

    Write-Host "Creating temporary credentials for the bulk upload process"

    $file = (Resolve-Path -Path "$PSScriptRoot/bulk-api-client.sql")
    $params = 
    if($databasesConfig.installCredentials.useIntegratedSecurity){
        @{
            Database = "$($databasesConfig.adminDatabaseName)"
            Hostname = "$($databasesConfig.databaseServer)"
            ServerInstance = "$($databasesConfig.databaseServer)"
            InputFile = $file
            OutputSqlErrors = $True
            Variable = @(
                "ClientKey=$($lmsToolkitConfig.sampleData.key)",
                "ClientSecret=$($lmsToolkitConfig.sampleData.secret)"
            )
        } 
    }
    else{
        @{
            Database = "$($databasesConfig.adminDatabaseName)"
            Hostname = "$($databasesConfig.databaseServer)"
            ServerInstance = "$($databasesConfig.databaseServer)"
            UserName    = "$($databasesConfig.installCredentials.databaseUser)"
            Password    = "$($databasesConfig.installCredentials.databasePassword)"
            InputFile = $file
            OutputSqlErrors = $True
            Variable = @(
                "ClientKey=$($lmsToolkitConfig.sampleData.key)",
                "ClientSecret=$($lmsToolkitConfig.sampleData.secret)"
            )
        }
    }

    Invoke-SqlCmd @params
    Test-ExitCode
}

function Remove-BulkClientKeyAndSecret {
    param (   
        [Parameter(Mandatory=$True)]
        [Hashtable]
        $lmsToolkitConfig,
        [Parameter(Mandatory=$True)]
        [Hashtable]
        $databasesConfig   
    )

    Write-Host "Removing temporary bulk load credentials"

    $file = (Resolve-Path -Path "$PSScriptRoot/remove-bulk-api-client.sql")
    $params = 
    if($databasesConfig.installCredentials.useIntegratedSecurity){
        @{
            Database = "$($databasesConfig.adminDatabaseName)"
            HostName = "$($databasesConfig.databaseServer)"
            ServerInstance = "$($databasesConfig.databaseServer)"
            InputFile = $file
            OutputSqlErrors = $True
            Variable = @(
                "ClientKey=$($lmsToolkitConfig.sampleData.key)",
                "ClientSecret=$($lmsToolkitConfig.sampleData.secret)"
            )
        } 
    }
    else{
        @{
            Database = "$($databasesConfig.adminDatabaseName)"
            HostName = "$($databasesConfig.databaseServer)"
            ServerInstance = "$($databasesConfig.databaseServer)"
            UserName    = "$($databasesConfig.installCredentials.databaseUser)"
            Password    = "$($databasesConfig.installCredentials.databasePassword)"
            InputFile = $file
            OutputSqlErrors = $True
            Variable = @(
                "ClientKey=$($lmsToolkitConfig.sampleData.key)",
                "ClientSecret=$($lmsToolkitConfig.sampleData.secret)"
            )
        }
    }
    Invoke-SqlCmd @params
    Test-ExitCode
}

function Invoke-BulkLoadInternetAccessData {
    param (
        [Parameter(Mandatory=$True)]
        [Hashtable]
        $lmsToolkitConfig,
        [Parameter(Mandatory=$True)]
        [Hashtable]
        $databasesConfig,
        [Parameter(Mandatory=$True)]
        [switch]
        $UsingPlatformVersion52,
        [Parameter(Mandatory=$True)]
        [string]
        $BulkLoadExe,
        [Parameter(Mandatory=$True)]
        [string]
        $ApiUrl        
    )
    $ClientKey = "$($lmsToolkitConfig.sampleData.key)"
    $ClientSecret = "$($lmsToolkitConfig.sampleData.secret)"
    Write-Host "Preparing to upload additional sample data..."

    $bulkTemp = "$PSScriptRoot/bulk-temp"
    New-Item -Path $bulkTemp -ItemType Directory -Force | Out-Null

    New-BulkClientKeyAndSecret -lmsToolkitConfig $lmsToolkitConfig -databasesConfig $databasesConfig

    $bulkParams = @(
        "-b", $ApiUrl,
        "-d", (Resolve-Path -Path "$PSScriptRoot/../../data"),
        "-k", $ClientKey,
        "-s", $ClientSecret,
        "-w", (Resolve-Path -Path $bulkTemp)
    )

    if ($UsingPlatformVersion52) {
        # There is a known bug in 5.2 where the bulk load client cannot
        # download schema from the API itself. Workaround: have the schema
        # files available locally. This bug was fixed in release 5.3.
        Write-Host "Downloading XML schema files"

        $schemaDirectory = "$PSScriptRoot/schemas"
        New-Item -Path $schemaDirectory -ItemType Directory -Force | Out-Null
        Get-SchemaXSDFilesFor52 -SchemaDirectory $schemaDirectory

        $bulkParams += "-x"
        $bulkParams += (Resolve-Path -Path $schemaDirectory)
    }

    Write-Host -ForegroundColor Magenta "Executing: $BulkLoadExe " $bulkParams
    &$BulkLoadExe @bulkParams
    Test-ExitCode

    Remove-BulkClientKeyAndSecret -lmsToolkitConfig $lmsToolkitConfig -databasesConfig $databasesConfig

}

Export-ModuleMember Invoke-BulkLoadInternetAccessData
