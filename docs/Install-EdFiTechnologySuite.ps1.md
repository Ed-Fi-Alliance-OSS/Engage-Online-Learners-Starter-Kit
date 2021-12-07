# Install-EdFiTechnologySuite.ps1

## SYNOPSIS

Prepare a single-server environment for running the Engage Online Learners
Starter Kit by installing the Ed-Fi Technology Suite 3.

## SYNTAX

### __AllParameterSets

```powershell
Install-EdFiTechnologySuite.ps1 [[-PlatformVersion <String>]] [[-AdminAppVersion <String>]] [[-InstallPath <String>]] [[-WebRoot <String>]] [[-AnalyticsMiddleTierVersion <String>]] [[-LMSToolkitVersion <String>]] [[-EdFiNuGetFeed <String>]] [<CommonParameters>]
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

Installs with all default parameters

### Example 2: EXAMPLE 2

```powershell
.\Install-EdFiTechnologySuite.ps1 -PlatformVersion 5.1
```

Attempts to run the install with the Ed-Fi ODS/API Platform for Suite 3,
version 5.1 (which is not formally supported at this time, but might work).

### Example 3: EXAMPLE 3

```powershell
.\Install-EdFiTechnologySuite.ps1  -LMSToolkitVersion "1.1"
```

Use the version tag "1.1" instead of installing from the `main` branch of
the LMS Toolkit.

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
Position: 1
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
Position: 4
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
Position: 6
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
Position: 2
Default value: c:/Ed-Fi
Accept pipeline input: False
Accept wildcard characters: False
DontShow: False
```

### -LMSToolkitVersion

Branch or tag to use when installing the LMS Toolkit.

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

### -PlatformVersion

Major and minor software version number (x.y format) for the ODS/API platform
components: Web API, SwaggerUI, Client Side Bulk Loader.

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values:

Required: True (None) False (All)
Position: 0
Default value: 5.2
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
Default value: c:/inetpub/Ed-Fi
Accept pipeline input: False
Accept wildcard characters: False
DontShow: False
```
