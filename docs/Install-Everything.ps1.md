# Install-Everything.ps1

## SYNOPSIS

Performs complete setup of a virtual machine for the Engage Online Learners
Starter Kit.

## SYNTAX

### __AllParameterSets

```powershell
Install-Everything.ps1 [[-ToolsPath <String>]] [[-OdsPlatformVersion <String>]] [[-AdminAppVersion <String>]] [[-InstallPath <String>]] [[-WebRoot <String>]] [[-AnalyticsMiddleTierVersion <String>]] [[-LMSToolkitVeresion <String>]] [[-EdFiNuGetFeed <String>]] [<CommonParameters>]
```

## DESCRIPTION

Performs complete setup of a virtual machine for the Engage Online Learners
Starter Kit, appropriate for use on any Windows 2019 Server whether
on-premises or running in a cloud provider (tested in desktop Hyper-V and on
AWS EC2).

This script enables TLS 1.2 support and sets the execution policy to enable
running additional scripts.
Then it calls the following:

1. Install-ThirdPartyApplications.ps1
2. Install-EdFiTechnologySuite.ps1
3. Install-StarterKit.ps1

Please review the script files above for more information on the actions
they take.

## PARAMETERS

### -AdminAppVersion

Major and minor software software version number (x.y format) for the ODS
Admin App.

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values:

Required: True (None) False (All)
Position: 2
Default value: 2.2
Accept pipeline input: False
Accept wildcard characters: False
DontShow: False
```

### -AnalyticsMiddleTierVersion

Branch or tag to use when installing the Analytics Middle Tier.

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values:

Required: True (None) False (All)
Position: 5
Default value: main
Accept pipeline input: False
Accept wildcard characters: False
DontShow: False
```

### -EdFiNuGetFeed

NuGet Feed for Ed-Fi packages

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values:

Required: True (None) False (All)
Position: 7
Default value: https://pkgs.dev.azure.com/ed-fi-alliance/Ed-Fi-Alliance-OSS/_packaging/EdFi%40Release/nuget/v3/index.json
Accept pipeline input: False
Accept wildcard characters: False
DontShow: False
```

### -InstallPath

Root directory for downloads and tool installation

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values:

Required: True (None) False (All)
Position: 3
Default value: c:/Ed-Fi
Accept pipeline input: False
Accept wildcard characters: False
DontShow: False
```

### -LMSToolkitVeresion

Branch or tag to use when installing the LMS Toolkit.

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values:

Required: True (None) False (All)
Position: 6
Default value: main
Accept pipeline input: False
Accept wildcard characters: False
DontShow: False
```

### -OdsPlatformVersion

Major and minor software version number (x.y format) for the ODS/API platform
components: Web API, SwaggerUI, Client Side Bulk Loader.

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values:

Required: True (None) False (All)
Position: 1
Default value: 5.2
Accept pipeline input: False
Accept wildcard characters: False
DontShow: False
```

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

### -WebRoot

Root directory for web application installs.

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values:

Required: True (None) False (All)
Position: 4
Default value: c:/inetpub/Ed-Fi
Accept pipeline input: False
Accept wildcard characters: False
DontShow: False
```
