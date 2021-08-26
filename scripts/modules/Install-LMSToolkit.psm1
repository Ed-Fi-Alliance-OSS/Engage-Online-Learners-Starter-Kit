# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function Install-Python {
    &choco install python3 --version 3.9.6 -y

    # This package does not add Python and Pip to the path
    $additions = "C:\Python39\;C:\Python39\Scripts"
    $env:PATH = "$env:PATH;$additions"

    $value = [Environment]::GetEnvironmentVariable("PATH", "Machine")
    $value = "$value;$additions"
    [Environment]::SetEnvironmentVariable("PATH", $value, "Machine")
}

function Install-Poetry {
    (Invoke-WebRequest -Uri https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py -UseBasicParsing).Content | python -
    &refreshenv

    $env:PATH = "$env:PATH;$env:USERPROFILE\.poetry\bin"
}

function New-EnvFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True, ValueFromPipeline = $true)]
        [string]
        $Contents,

        [Parameter(Mandatory=$True)]
        [string]
        $Directory
    )

    $Contents | Out-File "$Directory/.env" -Encoding ascii
}

function Install-LMSSampleData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [string]
        $InstallDir
    )

    $lmsDirectory = "$InstallDir/LMS-Toolkit-main"

    try {
        Push-Location -Path "$lmsDirectory/src/lms-ds-loader"
        &poetry install

        # Upload sample LMS data into the `lms` schema
        &poetry run python ./edfi_lms_ds_loader/ `
            --csvpath (Resolve-Path -Path "../../docs/starter-kit-sample")
    }
    catch {throw}
    finally {
        Pop-Location
    }

    # Copy assignment information into the `lmsx` schema
    try {
        Push-Location -Path "$lmsDirectory/src/lms-harmonizer"
        &poetry install
        &poetry run python ./edfi_lms_harmonizer/
    }
    catch {throw}
    finally {
        Pop-Location
    }
}

function Install-LMSToolkit {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [string]
        $DownloadPath,

        [Parameter(Mandatory=$True)]
        [string]
        $InstallDir
    )

    # Download the LMS Toolkit source
    $url = "https://github.com/Ed-Fi-Alliance-OSS/LMS-Toolkit/archive/refs/heads/main.zip"
    $lmsZip = "$DownloadPath/lms-main.zip"
    Invoke-RestMethod -Uri $url -OutFile $lmsZip
    Expand-Archive -Path $lmsZip -Destination $InstallDir -Force
    $lmsDirectory = "$InstallDir/LMS-Toolkit-main"

    @"
CANVAS_BASE_URL=[base URL of your canvas install]
CANVAS_ACCESS_TOKEN=[access token from an administrative account]
START_DATE=[extract courses that start from this date]
END_DATE=[extract courses that end by this date]
OUTPUT_DIRECTORY=$InstallDir/lms-data/csv
SYNC_DATABASE_DIRECTORY=$InstallDir/lms-data/canvas
FEATURE=activities, attendance, assignments, grades
"@ | New-EnvFile -Directory "$lmsDirectory/src/canvas-extractor"

    @"
CLASSROOM_ACCOUNT=[email address of the Google Classroom admin account, required]
START_DATE=[start date for usage data pull in yyyy-mm-dd format, optional]
END_DATE=[end date for usage data pull in yyyy-mm-dd format, optional]
OUTPUT_DIRECTORY=$InstallDir/lms-data/csv
SYNC_DATABASE_DIRECTORY=$InstallDir/lms-data/google
FEATURE=activities, attendance, assignments, grades
"@ | New-EnvFile -Directory "$lmsDirectory/src/google-classroom-extractor"

    @"
SCHOOLOGY_KEY=[Schoology API key]
SCHOOLOGY_SECRET=[Schoology API secret]
SCHOOLOGY_INPUT_DIRECTORY=$InstallDir/lms-data/schoology-activities
PAGE_SIZE=200
OUTPUT_DIRECTORY=$InstallDir/lms-data/csv
SYNC_DATABASE_DIRECTORY=$InstallDir/lms-data/schoology
FEATURE=activities, attendance, assignments, grades
"@ | New-EnvFile -Directory  "$lmsDirectory/src/schoology-extractor"

    @"
CSV_PATH=$InstallDir/lms-data/csv
DB_SERVER=localhost
DB_NAME=EdFi_ODS_2022
USE_INTEGRATED_SECURITY=True
"@ | New-EnvFile -Directory "$lmsDirectory/src/lms-ds-loader"

    @"
DB_SERVER=localhost
DB_NAME=EdFi_ODS_2022
USE_INTEGRATED_SECURITY=True
EXCEPTIONS_REPORT_DIRECTORY=$InstallDir/lms-data/harmonizer-exceptions
"@ | New-EnvFile -Directory "$lmsDirectory/src/lms-harmonizer"

    # Run the LMS DS Loader to create the `lms` schema tables
    try {
        Push-Location -Path "$lmsDirectory/src/lms-ds-loader"
        &poetry install

        # Don't want to load any data, so use a bogus directory
        &poetry run python ./edfi_lms_ds_loader/ `
            --csvpath $PSScriptRoot
    }
    catch {throw}
    finally {
        Pop-Location
    }

    # For now, we do not have a proper install of the LMSX extension, but
    # the tables for it are necesary for the next steps. Manually install them.
    try {
        Push-Location -Path "$lmsDirectory/extension/EdFi.Ods.Extensions.LMSX/Artifacts/MSSQL/Structure/ODS"
        @(
            "0010-EXTENSION-LMSX-Schemas.sql",
            "0020-EXTENSION-LMSX-Tables.sql",
            "0030-EXTENSION-LMSX-ForeignKeys.sql",
            "0040-EXTENSION-LMSX-IdColumnUniqueIndexes.sql",
            "0050-EXTENSION-LMSX-ExtendedProperties.sql"
        ) | ForEach-Object {
            Invoke-SqlCmdOnODS $_
        }
    }
    catch {throw}
    finally {
        Pop-Location
    }

    # Run the LMS Harmonizer to install additional support in the `lmsx` schema.
    try {
        Push-Location -Path "$lmsDirectory/src/lms-harmonizer"
        &poetry install
        &poetry run python ./edfi_lms_harmonizer/
    }
    catch {throw}
    finally {
        Pop-Location
    }

    # Certain descriptors are needed. Because the full LMSX extension is not installed
    # yet, we need an alternate method to insert  those descriptors.
    try {
        Push-Location -Path "$lmsDirectory/utils/amt-integration-tests"
        &poetry install
        &poetry run python ./LoadDescriptors.py `
            --server localhost `
            --dbname EdFi_ODS_2022 `
            --useintegratedsecurity True
    }
    catch {throw}
    finally {
        Pop-Location
    }
}

Export-ModuleMember *
