# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

function Convert-PsObjectToHashTable {
    param (
        $objectToConvert
    )

    $hashTable = @{}

    $objectToConvert.psobject.properties | ForEach-Object { $hashTable[$_.Name] = $_.Value }

    return $hashTable
}

function Format-ConfigurationFileToHashTable {
    param (
        [string] $configPath
    )

    $configJson = Get-Content $configPath | ConvertFrom-Json

    $formattedConfig = @{
        odsPlatformVersion =$configJson.odsPlatformVersion 
        downloadDirectory = $configJson.downloadDirectory
        installDirectory= $configJson.installDirectory
        EdFiNuGetFeed =  $configJson.EdFiNuGetFeed
        webSiteName = $configJson.webSiteName
        installDatabases = $configJson.installDatabases
        installEdFiDatabases = $configJson.installEdFiDatabases
        installAdminApp = $configJson.installAdminApp
        installWebApi = $configJson.installWebApi
        installSwaggerUI = $configJson.installSwaggerUI
        installAMT = $configJson.installAMT
        installPrerequisites = $configJson.installPrerequisites
        installLMSToolkit = $configJson.installLMSToolkit
        uninstallAdminApp = $configJson.uninstallAdminApp
        uninstallWebApi = $configJson.uninstallWebApi
        uninstallSwaggerUI = $configJson.uninstallSwaggerUI
        uninstallAMT = $configJson.uninstallAMT
		
        anyApplicationsToInstall = $configJson.installDatabases -or $configJson.installAdminApp -or $configJson.installWebApi -or $configJson.installSwaggerUI

        anyApplicationsToUninstall = $configJson.uninstallAdminApp -or $configJson.uninstallWebApi -or $configJson.uninstallSwaggerUI

        databasesConfig = Convert-PsObjectToHashTable $configJson.databases

        adminAppConfig = Convert-PsObjectToHashTable $configJson.adminApp

        webApiConfig = Convert-PsObjectToHashTable $configJson.webapi

        swaggerUIConfig = Convert-PsObjectToHashTable $configJson.swaggerui

        amtConfig = Convert-PsObjectToHashTable $configJson.AMT

        installBulkLoadClient = $configJson.installBulkLoadClient

        bulkLoadClientConfig = $configJson.bulkLoadClientConfig

        lmsToolkitConfig =  Convert-PsObjectToHashTable $configJson.lmsToolkit
    }

    return $formattedConfig
}

Export-ModuleMember Format-ConfigurationFileToHashTable
