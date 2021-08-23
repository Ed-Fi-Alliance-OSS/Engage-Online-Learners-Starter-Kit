# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function Set-WallPaper {
    Write-Output "Installing Ed-Fi wallpaper image"

    $url = "https://edfidata.s3-us-west-2.amazonaws.com/Starter+Kits/images/EdFiQuickStartBackground.png"
    Invoke-WebRequest -Uri $url -OutFile "c:/EdFiQuickStartBackground.png"

    Set-ItemProperty -path "HKCU:\Control Panel\Desktop" -name WallPaper -value "c:/EdFiQuickStartBackground.png"
    Set-ItemProperty -path "HKCU:\Control Panel\Desktop" -name WallpaperStyle -value "0" -Force
    rundll32.exe user32.dll, UpdatePerUserSystemParameters
}

function Set-TLS12Support {
    Write-Host "Enabling TLS 1.2"

    if (-not [Net.ServicePointManager]::SecurityProtocol.HasFlag([Net.SecurityProtocolType]::Tls12)) {
        [Net.ServicePointManager]::SecurityProtocol += [Net.SecurityProtocolType]::Tls12
    }
}

function Enable-LongFileNames {
    Write-Host "Enabling long file name support"

    if (Test-Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem') {
        Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -name "LongPathsEnabled" -Value 1 -Verbose -Force
    }
}

Export-ModuleMember *
