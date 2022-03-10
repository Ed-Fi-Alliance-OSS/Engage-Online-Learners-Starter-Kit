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

### -InstallPath

Root directory for the application installation.

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values:

Required: True (None) False (All)
Position: 2
Default value: c:/Ed-Fi
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
Position: 3
Default value: Ed-Fi
Accept pipeline input: False
Accept wildcard characters: False
DontShow: False
```

### -downloadPath

Path for storing downloaded packages

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values:

Required: True (None) False (All)
Position: 4
Default value: C:\\temp
Accept pipeline input: False
Accept wildcard characters: False
DontShow: False
```

### -EdFiNuGetFeed

Branch or tag to use when installing the LMS Toolkit.

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values:

Required: True (None) False (All)
Position: 5
Default value: https://pkgs.dev.azure.com/ed-fi-alliance/Ed-Fi-Alliance-OSS/_packaging/EdFi%40Release/nuget/v3/index.json
Accept pipeline input: False
Accept wildcard characters: False
DontShow: False
```

### -databasesConfig

Hashtable containing information about the databases and its server.
 
```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:
Accepted values:

Required: True (None) False (All)
Position: 6
Default value: $databasesConfig = @{
      installDatabases= $true
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
      useTemplates= $false
      noDuration= $false
      dropDatabases= $true
      apiMode= "sharedinstance"
      odsDatabaseTemplateName= "populated"
      useIntegratedSecurity= $true,
      minimalTemplateSuffix="Ods_Minimal_Template"
      populatedTemplateSuffix="Ods"
      populatedTemplateScript= "GrandBend"
      addAdminUser= $false,
      dbAdminUser= "edfi"
      dbAdminUserPassword= "edfi"
      packageDetails= @{
          packageName= "EdFi.Suite3.RestApi.Databases"
          version= "5.3"
      }
  }
Accept pipeline input: False
Accept wildcard characters: False
DontShow: False
```

### -adminAppConfig

Hashtable containing Admin App settings and the installation directory.

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:
Accepted values:

Required: True (None) False (All)
Position: 7
Default value: $adminAppConfig = @{
    installAdminApp= $true
    appStartUp= "OnPrem"
    odsApi= @{
        apiUrl= ""
    }
    packageDetails= @{
      packageName= "EdFi.Suite3.ODS.AdminApp.Web"
      version= "2.3"
    }
    packageInstallerDetails= @{
        packageName= "EdFi.Suite3.Installer.AdminApp"
        version= "2.3"
    }
  }
Accept pipeline input: False
Accept wildcard characters: False
DontShow: False
```
### -webApiConfig

Hashtable containing Web API settings and the installation directory.

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:
Accepted values:

Required: True (None) False (All)
Position: 8
Default value: $webApiConfig = @{
    installWebApi= $true
    webApplicationName= "WebApi"
    webApiAppSettings= @{
        excludedExtensionSources= "Sample,Homograph"
        extensions= "true"
        profiles= "false"
        openApiMetadata= "true"
        aggregateDependencies= "true"
        tokenInfo= "true"
        composites= "true"
        changeQueries= "true"
        identityManagement= "false"
        ownershipBasedAuthorization= "false"
        uniqueIdValidation= "false"
    }
    packageDetails= @{
        packageName= "EdFi.Suite3.Ods.WebApi"
        version= "5.3"
    }
    packageInstallerDetails= @{
        packageName= "EdFi.Suite3.Installer.WebApi"
        version= "5.3"
    }
  }
Accept pipeline input: False
Accept wildcard characters: False
DontShow: False
```
### -swaggerUIConfig

Hashtable containing SwaggerUI settings and the installation directory.

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:
Accepted values:

Required: True (None) False (All)
Position: 9
Default value: $swaggerUIConfig = @{
    installSwaggerUI= $true
    WebApplicationName= "SwaggerUI"
    swaggerAppSettings= @{
        apiMetadataUrl= ""
        apiVersionUrl= ""
    }
    packageDetails= @{
        packageName= "EdFi.Suite3.Ods.SwaggerUI"
        version= "5.3"
    }
    packageInstallerDetails= @{
        packageName= "EdFi.Suite3.Installer.SwaggerUI"
        version= "5.3"
    }
  }
Accept pipeline input: False
Accept wildcard characters: False
DontShow: False
```
### -amtConfig

Hashtable containing AMT settings and installation directory.

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:
Accepted values:

Required: True (None) False (All)
Position: 10
Default value: $amtConfig = @{
    installAMT= $true
    amtDownloadPath= "C:\\temp\\downloads"
    amtInstallerPath= "C:\\temp\\tools"
    options= "EWS RLS Indexes Engage"
    install_selfContained= "true"
    selfContainedOS= "win10.x64"
    packageDetails= @{
        packageName= "EdFi.AnalyticsMiddleTier"
        packageURL= "https://github.com/Ed-Fi-Alliance-OSS/Ed-Fi-Analytics-Middle-Tier"
        version= "2.8.0"
    }
  }
Accept pipeline input: False
Accept wildcard characters: False
DontShow: False
```
### -bulkLoadClientConfig

Hashtable containing Bulk Load Client settings and installation directory.

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:
Accepted values:

Required: True (None) False (All)
Position: 11
Default value: $bulkLoadClientConfig = @{
      installBulkLoadClient= $true,
      installationDirectory= "C:\\Ed-Fi\\Bulk-Load-Client"
      packageDetails= @{
          packageName= "EdFi.Suite3.BulkLoadClient.Console"
          version= "5.3"
      }
      packageODSSchema52Details={
          packageURL= "https://raw.githubusercontent.com/Ed-Fi-Alliance-OSS/Ed-Fi-ODS/"
          version= "5.2"
      }
  }
Accept pipeline input: False
Accept wildcard characters: False
DontShow: False
```
### -lmsToolkitConfig

Hashtable containing LMS Toolkit settings and installation directory.

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:
Accepted values:

Required: True (None) False (All)
Position: 7
Default value: $lmsToolkitConfig = @{
      installLMSToolkit= $true
      installationDirectory= "C:\\Ed-Fi\\"
      webRootFolder= "c:\\inetpub\\Ed-Fi"
      pathToWorkingDir= "C:\\Ed-Fi\\QuickStarts\\LMS-Toolkit"
      packageDetails= @{
          packageURL= "https://github.com/Ed-Fi-Alliance-OSS/LMS-Toolkit"
          version= "main"
      }     
      sampleData= @{
          key= "dfghjkl34567"
          secret= "4eryftgjh-pok%^K```$E%RTYG"
      }
  }
Accept pipeline input: False
Accept wildcard characters: False
DontShow: False
```