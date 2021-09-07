# Building a VM on Localhost

Two options are documented below: create the VM manually, or use Packer to
automate the process.

## Option 1: Manual

1. Create a virtual machine in Hyper-V. If you need a Windows 2019 server base
   image, then we recommend the [Windows 2019 evaluation edition
   iso](https://software-download.microsoft.com/download/pr/17763.737.190906-2324.rs5_release_svc_refresh_SERVER_EVAL_x64FRE_en-us_1.iso)
2. Now that you have a running instance, you need to install all of the software
   for it. In this repository, zip together the following directories and files
   and then copy and paste the zip file into the RDP session. Suggested
   location: `c:\Ed-Fi-Starter-Kit`.
   * [data](../data)
   * [scripts](../scripts)
   * [vm-docs](../vm-docs)
   * [StudentEngagementDashboard.pbix](../StudentEngagementDashboard.pbix)

   ```powershell
   $filesToZip = @(
     "$PSScriptRoot/../data",
     "$PSScriptRoot/../scripts",
     "$PSScriptRoot/../vm-docs",
     "$PSScriptRoot/../*.pbix"
   )
   Compress-Archive -Path $filesToZip -DestinationPath $DestinationFile -Force
   ```

3. Now you can open a PowerShell window. It will be in administrative mode
   automatically, as required to run the script. Navigate to the directory with
   the scripts and run `Install-Everything.ps1`. If everything has
   been done right, it will run for a while and install everything needed.
4. Review and address any errors.

## Option 2: Use Packer

[install Packer](https://learn.hashicorp.com/tutorials/packer/get-started-install-cli) and run
[build-vm.ps1](../packer/build-vm.ps1)

When following the second option, the VM image will be created in the
`packer/dist` directory. Packer unloads the VM from Hyper-V, so you will only
have the _image_ available, not an actual VM. In Hyper-V Manager, click on
"Import Virtual Machine..." and navigate to the `dist` directory. Follow the
prompts and you will have a running virtual machine.

NOTE: you can edit the `starter-kit-variables.json` file to tune some of the
settings. For example, if your computer has 16 GB of memory then you may need to
lower the amount reserved for the virtual machine, which defaults to 8 GB.

## build-vm.ps1

### SYNOPSIS

This builds a Starter Kit virtual machine on Hyper-V using Packer.

### SYNTAX

#### __AllParameterSets

```powershell
build-vm.ps1 [[-VMSwitch <String>]] [[-ISOUrl <String>]] [-SkipCreateVMSwitch] [-SkipRunPacker] [<CommonParameters>]
```

### DESCRIPTION

Configures Packer logging, Defines a network adapter and vm switch,
compresses assessment PowerShell scripts, and initiates the packer build.

### EXAMPLES

#### Example 1: EXAMPLE 1

```powershell
.\build-vm.ps1
```

Creates a virtual machine image that can be imported using the Hyper-V Manager

### PARAMETERS

#### -ISOUrl

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values:

Required: True (None) False (All)
Position: 1
Default value:
Accept pipeline input: False
Accept wildcard characters: False
DontShow: False
```

#### -SkipCreateVMSwitch

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:
Accepted values:

Required: True (None) False (All)
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
DontShow: False
```

#### -SkipRunPacker

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:
Accepted values:

Required: True (None) False (All)
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
DontShow: False
```

#### -VMSwitch

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values:

Required: True (None) False (All)
Position: 0
Default value: packer-hyperv-iso
Accept pipeline input: False
Accept wildcard characters: False
DontShow: False
```

### NOTES

Sets the Packer debug mode and logging path variables at runtime.
