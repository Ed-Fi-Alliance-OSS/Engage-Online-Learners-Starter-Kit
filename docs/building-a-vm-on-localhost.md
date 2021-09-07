# Building a VM on Localhost

**Option 1**: Manually create a virtual machine in Hyper-V, and follow the setup
instructions in [Building a VM on AWS](building-a-vm-on-aws.md)

**Option 2**: [install Packer](https://learn.hashicorp.com/tutorials/packer/get-started-install-cli) and run
[build-vm.ps1](../packer/build-vm.ps1)

When following the second option, the VM image will be created in the
`packer/dist` directory. Packer unloads the VM from Hyper-V, so you will only
have the _image_ available, not an actual VM. In Hyper-V Manager, click on
"Import Virtual Machine..." and navigate to the `dist` directory. Follow the
prompts and you will have a running virtual machine.
