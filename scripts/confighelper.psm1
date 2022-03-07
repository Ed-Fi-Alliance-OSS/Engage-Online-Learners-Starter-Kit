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
       
        databasesConfig = Convert-PsObjectToHashTable $configJson.databases

        adminAppConfig = Convert-PsObjectToHashTable $configJson.adminApp

        webApiConfig = Convert-PsObjectToHashTable $configJson.webapi

        swaggerUIConfig = Convert-PsObjectToHashTable $configJson.swaggerui

        amtConfig = Convert-PsObjectToHashTable $configJson.AMT

        bulkLoadClientConfig = Convert-PsObjectToHashTable $configJson.bulkLoadClientConfig

        lmsToolkitConfig =  Convert-PsObjectToHashTable $configJson.lmsToolkit
    }

    return $formattedConfig
}

Export-ModuleMember Format-ConfigurationFileToHashTable
