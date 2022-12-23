# Install-EdFiTechnologySuite.ps1

## SYNOPSIS

Prepare a single-server environment for running the Engage Online Learners
Starter Kit by installing the Ed-Fi Technology Suite 3.

## SYNTAX

### __AllParameterSets

```powershell
Install-EdFiTechnologySuite.ps1 
    [[-configPath] <String>] [[-InstallPath] <String>] [[-WebRoot] <String>] [[-downloadPath] <String>] 
    [[-EdFiNuGetFeed] <String>] [[-databasesConfig] <Hashtable>] [[-adminAppConfig] <Hashtable>] [[-webApiConfig] 
    <Hashtable>] [[-swaggerUIConfig] <Hashtable>] [[-amtConfig] <Hashtable>] [[-bulkLoadClientConfig] <Hashtable>] 
    [[-lmsToolkitConfig] <Hashtable>] [<CommonParameters>]
```

## DESCRIPTION

This script fully prepares a stand-alone system to run the software listed
below.
It is not recommended for production installations, which typically
would span across several servers instead of consolidating on a single one
(for example, separate web and database servers).
However, it may be a
useful model for setting up a set of custom deployment scripts for
production: for example, it could be duplicated for each server, and the
irrelevant installs for that server could be removed.
This script is being
developed and tested for Windows Server 2019, and should also work in
Windows 10 - though not as thoroughly tested there.

Windows configuration

* Enables TLS 1.2 support
* Enables long file names at the OS level
* Installs IIS and all of its feature components that are required for
  hosting .NET Core web applications

Ed-Fi software:

* Ed-Fi ODS/API for Suite 3, version 5.3
* Ed-Fi Client Side Bulk Loader for Suite 3, version 5.3
* Ed-Fi SwaggerUI for Suite 3, version 5.3
* Ed-Fi ODS Admin App for Suite 3, version 2.3
* Ed-Fi Analytics Middle Tier, latest development work (`main` branch)
* Ed-Fi LMS Toolkit, latest development work (`main` branch).

Note: the Analytics Middle Tier and LMS Toolkit are installed from the
`main` branch by default because these are the primary two systems that are
under development to support this Starter Kit.
Experimentally, you can
change the versions to any tag from those code repositories and the install
process will alternately download that tag instead of `main`.


## EXAMPLES

### Example 1: EXAMPLE 1

```powershell
.\Install-EdFiTechnologySuite.ps1
```

Installs with all default parameters from the json config file.

### Example 2: EXAMPLE 2

```powershell
.\Install-EdFiTechnologySuite.ps1 -configPath c:/temp/config.json
```

Attempts to run the install with a complete configuration json file with all the parameters.

### Example 3: EXAMPLE 3

```powershell
.\Install-EdFiTechnologySuite.ps1 -databasesConfig $databasesConfig `
    -adminAppConfig $configuration.adminAppConfig `
    -webApiConfig $configuration.webApiConfig `
    -swaggerUIConfig $configuration.swaggerUIConfig `
    -amtConfig $configuration.amtConfig `
    -bulkLoadClientConfig $configuration.bulkLoadClientConfig `
    -lmsToolkitConfig $configuration.lmsToolkitConfig `
```

Attempts to run the install with all the components configuration.

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
        version= "3.0.1"
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
      installBulkLoadClient= $true
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
