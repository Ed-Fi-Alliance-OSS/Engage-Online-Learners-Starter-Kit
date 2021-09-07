# Install-StarterKit.ps1

## SYNOPSIS

Installs Ed-Fi branding and other components required for a
Engage Online Learners Starter Kit "quick start" machine.

## SYNTAX

### __AllParameterSets

```powershell
Install-StarterKit.ps1 [[-ToolsPath <String>]] [[-ConsoleBulkLoadDirectory <String>]] [[-LMSToolkitDirectory <String>]] [[-WebRoot <String>]] [[-OdsPlatformVersion <String>]] [<CommonParameters>]
```

## DESCRIPTION

This script performs the following actions:

* Loads sample LMS data to augment the "Grand Bend" populated template
* Installs a landing page with help information, along with a desktop
  shortcut
* Installs an Ed-Fi branded desktop wallpaper image
* Downloads the latest starter kit Power BI file on the desktop

Assumes that you have already downloaded and installed the LMS Toolkit

## PARAMETERS

### -ConsoleBulkLoadDirectory

The directory in which the Console Bulk Loader was downloaded

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values:

Required: True (None) False (All)
Position: 1
Default value: C:/Ed-Fi/Bulk-Load-Client
Accept pipeline input: False
Accept wildcard characters: False
DontShow: False
```

### -LMSToolkitDirectory

The directory in which the LMS Toolkit was downloaded and installed.

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values:

Required: True (None) False (All)
Position: 2
Default value: c:/ed-fi/LMS-Toolkit-main
Accept pipeline input: False
Accept wildcard characters: False
DontShow: False
```

### -OdsPlatformVersion

{{ Fill OdsPlatformVersion Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values:

Required: True (None) False (All)
Position: 4
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

Root directory for web applications.

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values:

Required: True (None) False (All)
Position: 3
Default value: c:/inetpub/Ed-Fi
Accept pipeline input: False
Accept wildcard characters: False
DontShow: False
```
