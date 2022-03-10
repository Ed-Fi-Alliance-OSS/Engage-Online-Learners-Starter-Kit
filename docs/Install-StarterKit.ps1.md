# Install-StarterKit.ps1

## SYNOPSIS

Installs Ed-Fi branding and other components required for a
Engage Online Learners Starter Kit "quick start" machine.

## SYNTAX

### __AllParameterSets

```powershell
Install-StarterKit.ps1 [[-configPath] 
    <String>] [-lmsToolkitConfig] <Hashtable> [-databasesConfig] <Hashtable> [-ApiUrl] <String> [[-ToolsPath] 
    <String>] [[-ConsoleBulkLoadDirectory] <String>] [[-LMSToolkitDirectory] <String>] [[-WebRoot] <String>] 
    [[-OdsPlatformVersion] <String>] [<CommonParameters>]
```

## DESCRIPTION

This script performs the following actions:

* Loads sample LMS data to augment the "Grand Bend" populated template
* Installs a landing page with help information, along with a desktop shortcut
* Installs an Ed-Fi branded desktop wallpaper image
* Downloads the latest starter kit Power BI file on the desktop

Assumes that you have already downloaded and installed the LMS Toolkit

## PARAMETERS

### -configPath

Parameters configuration file.

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values:

Required: True (None) False (All)
Position: 1
Default value: $PSScriptRoot\configuration.json
Accept pipeline input: False
Accept wildcard characters: False
DontShow: False
```

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
### -lmsToolkitConfig

Hashtable containing LMS Toolkit settings and installation directory.
  $lmsToolkitConfig= @{
      installationDirectory= "C:\\Ed-Fi\\"
      webRootFolder= "c:\\inetpub\\Ed-Fi"
      pathToWorkingDir= "C:\\Ed-Fi\\QuickStarts\\LMS-Toolkit"
      sampleData= @{
          key= "dfghjkl34567"
          secret= "4eryftgjh-pok%^K```$E%RTYG"
      }
  }
```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:
Accepted values:

Required: True (None) False (All)
Position: 2
Default value: $lmsToolkitConfig = @{
      installationDirectory= "C:\\Ed-Fi\\"
      webRootFolder= "c:\\inetpub\\Ed-Fi"
      pathToWorkingDir= "C:\\Ed-Fi\\QuickStarts\\LMS-Toolkit"
      sampleData= @{
          key= "dfghjkl34567"
          secret= "4eryftgjh-pok%^K```$E%RTYG"
      }
  }
Accept pipeline input: False
Accept wildcard characters: False
DontShow: False
```

### -databasesConfig

Hashtable containing information about the databases and its server.
  $databasesConfig = @{
      installDatabases= $true,
      applicationCredentials= @{
          databaseUser= ""
          databasePassword= ""
          useIntegratedSecurity= $true
      }
      installCredentials= @{
          databaseUser= ""
          databasePassword= ""
          useIntegratedSecurity= $true
      }
      engine= "SQLServer"
      databaseServer= "localhost"
      databasePort= ""
      adminDatabaseName= "EdFi_Admin"
      odsDatabaseName= "EdFi_Ods"
      securityDatabaseName= "EdFi_Security"
  }

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:
Accepted values:

Required: True (None) False (All)
Position: 3
Default value: $databasesConfig = @{
      installDatabases= $true,
      applicationCredentials= @{
          databaseUser= ""
          databasePassword= ""
          useIntegratedSecurity= $true
      }
      installCredentials= @{
          databaseUser= ""
          databasePassword= ""
          useIntegratedSecurity= $true
      }
      engine= "SQLServer"
      databaseServer= "localhost"
      databasePort= ""
      adminDatabaseName= "EdFi_Admin"
      odsDatabaseName= "EdFi_Ods"
      securityDatabaseName= "EdFi_Security"
  }
Accept pipeline input: False
Accept wildcard characters: False
DontShow: False
```

### -ApiURL

Ed-Fi Web API.

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values:

Required: True (None) False (All)
Position: 4
Default value: https://$($env:computername)/WebAPI
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
Position: 5
Default value: "$PSScriptRoot/.tools"
Accept pipeline input: False
Accept wildcard characters: False
DontShow: False
```
### -ConsoleBulkLoadDirectory

The directory in which the Console Bulk Loader was downloaded.

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values:

Required: True (None) False (All)
Position: 6
Default value: "C:/Ed-Fi/Bulk-Load-Client"
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
Position: 7
Default value: c:/ed-fi/LMS-Toolkit-main
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
Position: 8
Default value: c:/inetpub/Ed-Fi
Accept pipeline input: False
Accept wildcard characters: False
DontShow: False
```

### -WebRoot

ODS platform version.

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values:

Required: True (None) False (All)
Position: 9
Default value: 5.3
Accept pipeline input: False
Accept wildcard characters: False
DontShow: False
```