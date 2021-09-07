# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

<#
    .SYNOPSIS
        This builds a Starter Kit virtual machine on Hyper-V using Packer.

    .DESCRIPTION
        Configures Packer logging, Defines a network adapter and vm switch,
        compresses assessment PowerShell scripts, and initiates the packer build.
    .EXAMPLE
        PS C:\> .\build-vm.ps1
        Creates a virtual machine image that can be imported using the Hyper-V Manager
    .NOTES
        Sets the Packer debug mode and logging path variables at runtime.
#>
param(
    [string] $VMSwitch = "packer-hyperv-iso",
    [string] $ISOUrl,
    [switch] $SkipCreateVMSwitch,
    [switch] $SkipRunPacker
)

#Requires -RunAsAdministrator
#Requires -Version 5

$PackerFile = "win2019-eval.pkr.hcl"
$VariablesFile = "starter-kit-variables.json"

$global:ErrorActionPreference = "Stop"
$global:ProgressPreference = "SilentlyContinue"

Import-Module -Name $PSScriptRoot/packer-helper.psm1 -Force

# global vars
$buildPath = "$PSScriptRoot/build"
$logsPath = "$PSScriptRoot/logs"

function Invoke-CreateBuildAndLogsFolders {
    New-Item -ItemType Directory -Path $buildPath -Force | Out-Null
    New-Item -ItemType Directory -Path $logsPath -force | Out-Null
}

Invoke-ValidateDriveSpace -MinimumSpace 30
Invoke-CreateBuildAndLogsFolders

$starterKitZip = "$buildPath/starter-kit.zip"
New-StarterKitZip -DestinationFile $starterKitZip

Set-EnvironmentVariables -BuildPath $buildPath -LogsPath $logsPath

# Configure VMSwitch
if (-not ($SkipCreateVMSwitch)) {
    Invoke-CreateVMSwitch -VMSwitch $VMSwitch
}
else {
    Write-Output "Skipping VM Switch validation and creation."
}

# Kick off the packer build with the force to override prior builds
if (-not ($SkipRunPacker)) {
    $packerConfig = (Resolve-Path "$PSScriptRoot/$PackerFile").Path
    $packerVariables = (Resolve-Path "$PSScriptRoot/$VariablesFile").Path

    Invoke-Packer -ConfigPath $packerConfig -VariablesPath $packerVariables -VMSwitch $VMSwitch
}
else {
    Write-Output "Skipping Packer Execution"
}
