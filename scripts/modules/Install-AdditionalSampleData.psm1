# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

$ErrorActionPreference = "Stop"

function Get-SchemaXSDFilesFor52 {
    param (
        [Parameter(Mandatory=$True)]
        [string]
        $SchemaDirectory
    )

    Write-Host "Downloading Schema XSD files"

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
        $xsdOut = "$SchemaDirectory/$_"
        Invoke-RestMethod -Uri "$xsdUrl/$_" -OutFile $xsdOut
    }
}

function New-BulkClientKeyAndSecret {
    param (
        [Parameter(Mandatory=$True)]
        [string]
        $ClientKey,

        [Parameter(Mandatory=$True)]
        [string]
        $ClientSecret
    )

    Write-Host "Creating temporary credentials for the bulk upload process"

    $params = @{
        Database = "EdFi_Admin"
        HostName = "localhost"
        InputFile = Resolve-Path -Path "./bulk-api-client.sql"
        OutputSqlErrors = $True
        Variable = @(
            "ClientKey=$ClientKey",
            "ClientSecret=$ClientSecret"
        )
    }
    Invoke-SqlCmd @params
}

function Remove-BulkClientKeyAndSecret {

    Write-Host "Removing temporary bulk load credentials"

    $query = @"
DELETE FROM dbo.ApiClient WHERE [name] = 'Client Bulk Loader';
"@

    $params = @{
        Database = "EdFi_Admin"
        HostName = "localhost"
        Query = $query
        OutputSqlErrors = $True
    }
    Invoke-SqlCmd @params
}

function Invoke-BulkLoadInternetAccessData {
    param (
        [Parameter(Mandatory=$True)]
        [string]
        $ClientKey,

        [Parameter(Mandatory=$True)]
        [string]
        $ClientSecret,

        [switch]
        $UsingPlatformVersion52,

        [Parameter(Mandatory=$True)]
        [string]
        $BulkLoadExe
    )

    Write-Host "Preparing to upload additional sample data..."

    $bulkTemp = "$PSScriptRoot/bulk-temp"
    New-Item -Path $bulkTemp -ItemType Directory -Force | Out-Null

    New-BulkClientKeyAndSecret -ClientKey $ClientKey -ClientSecret $ClientSecret

        $url = "https://$(hostname)/WebApi"

    $bulkParams = @(
        "-b", $url,
        "-d", (Resolve-Path -Path $skDataDir),
        "-k", $ClientKey,
        "-s", $ClientSecret,
        "-w", (Resolve-Path -Path $bulkTemp)
    )

    if ($UsingPlatformVersion52) {
        # There is a known bug in 5.2 where the bulk load client cannot
        # download schema from the API itself. Workaround: have the schema
        # files available locally. This bug will be resolved in the next
        # major release.
        $schemaDirectory = "$PSScriptRoot/schemas"
        New-Item -Path $schemaDirectory -ItemType Directory -Force | Out-Null
        Get-SchemaXSDFiles -SchemaDirectory $schemaDirectory

        $bulkParams.Add("-x")
        $bulkParams.Add((Resolve-Path -Path $schemaDirectory))
    }

    Write-Host -ForegroundColor Magenta "Executing: $bulkLoader " @bulkParams
    &$BulkLoadExe @params

    Remove-BulkClientKeyAndSecret
}

Export-ModuleMember Invoke-BulkLoadInternetAccessData
