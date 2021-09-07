# Building a VM on Localhost

## Option 1: Manually create a virtual machine in Hyper-V, and follow the setup

instructions in [Building a VM on AWS](building-a-vm-on-aws.md)

## Option 2: Use Packer

[install Packer](https://learn.hashicorp.com/tutorials/packer/get-started-install-cli) and run
[build-vm.ps1](../packer/build-vm.ps1)

When following the second option, the VM image will be created in the
`packer/dist` directory. Packer unloads the VM from Hyper-V, so you will only
have the _image_ available, not an actual VM. In Hyper-V Manager, click on
"Import Virtual Machine..." and navigate to the `dist` directory. Follow the
prompts and you will have a running virtual machine.

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
