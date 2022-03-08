# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.
#Requires -version 5

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
Import-Module -Name "$PSScriptRoot/Tool-Helpers.psm1" -Force

<#
.SYNOPSIS
    Installs the Ed-Fi LMSToolkit.
.DESCRIPTION
    Installs the Ed-Fi LMSToolkit.
.PARAMETER webSiteName
    IIS web site name.
.PARAMETER downloadPath
    Path for storing downloaded packages.
.PARAMETER InstallDir
    Installation directory.
.PARAMETER lmsToolkitConfig
    Hashtable containing lmsToolkit settings and the installation directory
    $lmsToolkit= @{
        installationDirectory= "C:\\Ed-Fi\\"
        webRootFolder= "c:\\inetpub\\Ed-Fi"
        pathToWorkingDir= "C:\\Ed-Fi\\QuickStarts\\LMS-Toolkit"
        packageDetails = @{
            packageURL  = "https://github.com/Ed-Fi-Alliance-OSS/LMS-Toolkit"
            version     = "main"
        }
        sampleData= @{
            key= "dfghjkl34567"
            secret= "4eryftgjh-pok%^K`$E%RTYG"
        }
    }
.PARAMETER databasesConfig
    Hashtable containing information about the databases and its server
    $databasesConfig= @{
        applicationCredentials= @{
            databaseUser            = ""
            databasePassword        = ""
            useIntegratedSecurity   = $true
        }
        installCredentials= @{
            databaseUser            = ""
            databasePassword        = ""
            useIntegratedSecurity   = $true
        }
        engine                = "SQLServer"
        databaseServer        = "localhost"
        databasePort          = ""
        adminDatabaseName     = "EdFi_Admin"
        odsDatabaseName       = "EdFi_Ods"
        securityDatabaseName  = "EdFi_Security"
        apiMode               = "sharedinstance"
    }
#>
function Install-LMSToolkit {
    [CmdletBinding()]
    param (
        [string]
        $DownloadPath= "C:\\temp\\downloads",
        
        [string]
        $InstallDir =  "C:\\Ed-Fi\\",
        
        # Hashtable containing information about the lmsToolkit.
        [Parameter(Mandatory=$True)]
        [Hashtable]
        $lmsToolkitConfig,
        
        # Hashtable containing information about the databases and its server.
        [Parameter(Mandatory=$True)]
        [Hashtable]
        $databasesConfig
    )
    
    $BranchOrTag = "$($lmsToolkitConfig.packageDetails.version)"

    $DatabaseServer = "$($databasesConfig.databaseServer)"

    $UseIntegratedSecurity = "$($databasesConfig.installCredentials.useIntegratedSecurity)"
    
    $DatabaseUserName = "$($databasesConfig.installCredentials.databaseUser)"

    $DatabasePassword = "$($databasesConfig.installCredentials.databasePassword)"

    $DatabaseName = "$($databasesConfig.odsDatabaseName)"
    
    # Download the LMS Toolkit source
    $lmsZip = "$DownloadPath/lms-toolkit.zip"
    try {
        # ... first assume that a branch name was given
        $url = "$($lmsToolkitConfig.packageDetails.packageURL)/archive/refs/heads/$BranchOrTag.zip"
        Invoke-RestMethod -Uri $url -OutFile $lmsZip
    }
    catch {
        # ... now try treating as a tag instead, and if it fails, let it bubble up
        $url = "$($lmsToolkitConfig.packageDetails.packageURL)/archive/refs/tags/$BranchOrTag.zip"
        Invoke-RestMethod -Uri $url -OutFile $lmsZip
    }

    Expand-Archive -Path $lmsZip -Destination $InstallDir -Force
    $lmsDirectory = "$InstallDir/LMS-Toolkit-$BranchOrTag"

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
if ("$($DatabaseUserName)"){
    @"
CSV_PATH=$InstallDir/lms-data/csv
DB_SERVER=$DatabaseServer
DB_NAME=$DatabaseName
DB_USERNAME="$($DatabaseUserName)"
DB_PASSWORD="$($DatabasePassword)"
"@ | New-EnvFile -Directory "$lmsDirectory/src/lms-ds-loader"

    @"
DB_SERVER=$DatabaseServer
DB_NAME=$DatabaseName
DB_USERNAME="$($DatabaseUserName)"
DB_PASSWORD="$($DatabasePassword)"
EXCEPTIONS_REPORT_DIRECTORY=$InstallDir/lms-data/harmonizer-exceptions
"@ | New-EnvFile -Directory "$lmsDirectory/src/lms-harmonizer"

}
else{
@"
CSV_PATH=$InstallDir/lms-data/csv
DB_SERVER=$DatabaseServer
DB_NAME=$DatabaseName
USE_INTEGRATED_SECURITY="True"
"@ | New-EnvFile -Directory "$lmsDirectory/src/lms-ds-loader"

    @"
DB_SERVER=$DatabaseServer
DB_NAME=$DatabaseName
USE_INTEGRATED_SECURITY="True"
EXCEPTIONS_REPORT_DIRECTORY=$InstallDir/lms-data/harmonizer-exceptions
"@ | New-EnvFile -Directory "$lmsDirectory/src/lms-harmonizer"
}
    # Run the LMS DS Loader to create the `lms` schema tables
    try {
        Push-Location -Path "$lmsDirectory/src/lms-ds-loader"
        &poetry install

        Test-ExitCode

        # Don't want to load any data, so use a bogus directory
        &poetry run python ./edfi_lms_ds_loader/ `
            --csvpath $PSScriptRoot

        Test-ExitCode
    }
    catch {throw}
    finally {
        Pop-Location
    }

    # For now, we do not have a proper install of the LMSX extension, but
    # the tables for it are necesary for the next steps. Manually install them.
    try {
        $databaseConfig= @{
            DatabaseServer = "$($DatabaseServer)"
            DatabaseUserName = "$($DatabaseUserName)"
            DatabasePassword = "$($DatabasePassword)"
            DatabaseName = "$($DatabaseName)"
        }
        
        Push-Location -Path "$lmsDirectory/extension/EdFi.Ods.Extensions.LMSX/Artifacts/MSSQL/Structure/ODS"
        @(
            "0010-EXTENSION-LMSX-Schemas.sql",
            "0020-EXTENSION-LMSX-Tables.sql",
            "0030-EXTENSION-LMSX-ForeignKeys.sql",
            "0040-EXTENSION-LMSX-IdColumnUniqueIndexes.sql",
            "0050-EXTENSION-LMSX-ExtendedProperties.sql"
        ) | ForEach-Object {
            Invoke-SqlCmdOnODS $_ @databaseConfig
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
        Test-ExitCode

        &poetry run python ./edfi_lms_harmonizer/
        Test-ExitCode
    }
    catch {throw}
    finally {
        Pop-Location
    }

    # Certain descriptors are needed. Because the full LMSX extension is not
    # installed yet, we need an alternate method to insert those descriptors -
    # can't bulk upload them through the API.
    try {
        Push-Location -Path "$lmsDirectory/utils/amt-integration-tests"
        &poetry install
        Test-ExitCode

        $cmd = "poetry run python ./LoadDescriptors.py --server $DatabaseServer --dbname $DatabaseName"

        if ($DatabaseUserName) {
            $cmd += " --username $DatabaseUserName --password $DatabasePassword"
        }
        else {
            $cmd += " --useintegratedsecurity True"
        }

        Invoke-Expression $cmd
        Test-ExitCode
    }
    catch {throw}
    finally {
        Pop-Location
    }
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
        $LmsDirectory
    )

    try {
        Push-Location -Path "$LmsDirectory/src/lms-ds-loader"
        &poetry install

        # Upload sample LMS data into the `lms` schema
        &poetry run python ./edfi_lms_ds_loader/ `
            --csvpath (Resolve-Path -Path "../../docs/starter-kit-sample")
    }
    catch {throw}
    finally {
        Pop-Location
    }

    Test-ExitCode

    # Copy assignment information into the `lmsx` schema
    try {
        Push-Location -Path "$LmsDirectory/src/lms-harmonizer"
        &poetry install
        &poetry run python ./edfi_lms_harmonizer/
    }
    catch {throw}
    finally {
        Pop-Location
    }

    Test-ExitCode
}



Export-ModuleMember *
