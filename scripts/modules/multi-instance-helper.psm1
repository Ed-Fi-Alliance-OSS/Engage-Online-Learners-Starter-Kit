# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

function Test-ApiMode {
    param (
        [String] $apiMode
    )
    if ((Test-MultiInstanceMode $apiMode) -or $apiMode -ieq "sharedinstance") {
        return
    }
    Write-Error "Please configure valid api mode. Valid Input: SharedInstance, DistrictSpecific or YearSpecific"
    Exit -1
}

function Test-YearSpecificMode {
    param (
        [String] $apiMode
    )
    if ($apiMode -ieq "yearspecific") {
        return $true
    }
    return $false
}

function Test-MultiInstanceMode {
    param (
        [String] $apiMode
    )
    if ((Test-YearSpecificMode $apiMode) -or $apiMode -ieq "districtspecific") {
        return $true
    }
    return $false
}

function Get-OdsTokens {
    param (
        [Array] $odsTokensArray,
        [string] $apiMode
    )
    if ((Test-MultiInstanceMode $apiMode) -and $odsTokensArray.Count -eq 0) {
        Write-Error "Please configure valid ods tokens configuration. For DistrictSpecific and YearSpecific modes, there must be atleast one OdsToken(OdsYear) specified. Please specify an array of non-empty OdsTokens(OdsYears)."
        Exit -1
    }
    if ($odsTokensArray.Count -gt 0) {
        $odsTokensArray | ForEach-Object -Process {
            if ([string]::IsNullOrEmpty($_))
            {
                Write-Error "Empty OdsTokens(OdsYears) are not allowed. Please specify an array of non-empty OdsTokens(OdsYears)."
                Exit -1
            }
        }
        return [String]::Join(";", $odsTokensArray)
    }
    return ""
}