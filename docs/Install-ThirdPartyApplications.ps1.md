# Install-ThirdPartyApplications.ps1

## SYNOPSIS

Installs third-party components useful for running the Engage Online
Learners Starter Kit by installing third-party components.

## SYNTAX

### __AllParameterSets

```powershell
Install-ThirdPartyApplications.ps1 [[-ToolsPath <String>]] [<CommonParameters>]
```

## DESCRIPTION

This script fully prepares a stand-alone system to run the software listed
below.
It is not recommended for production installations.

* Chocolatey
* .NET Core 3.1 SDK and hosting bundle for IIS
* Python 3.9 and Poetry
* SQL Server Express 2019 and SQL Management Studio
* Google Chrome
* Microsoft Visual Studio Code
* Microsoft Power BI Desktop

## PARAMETERS

### -ToolsPath

Temporary directory for downloaded components.

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values:

Required: True (None) False (All)
Position: 0
Default value: "$PSScriptRoot/.tools"
Accept pipeline input: False
Accept wildcard characters: False
DontShow: False
```
