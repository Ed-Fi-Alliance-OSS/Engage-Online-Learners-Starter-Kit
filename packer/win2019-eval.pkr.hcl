# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

variable "starter_kit_zip" {
  type    = string
}

variable "cpus" {
  type = string
}

variable "debug_mode" {
  type = string
}

variable "disk_size" {
  type = string
}

variable "headless" {
  type = string
}

variable "hw_version" {
  type = string
}

variable "iso_checksum" {
  type    = string
}

variable "iso_url" {
  type    = string
}

variable "memory" {
  type = string
}

variable "shutdown_command" {
  type = string
}

variable "vm_name" {
  type = string
}

variable "vm_switch" {
  type = string
}

variable "distribution_directory" {
  type = string
}

variable "user_name" {
  type = string
}

variable "password" {
  type = string
}

variable "base_image_directory" {
  type = string
}

variable "starter_kit_directory" {
  type = string
}

packer {
  required_plugins {
    comment = {
      version = ">=v0.2.23"
      source = "github.com/sylviamoss/comment"
    }
  }
}

source "hyperv-iso" "base-image" {
  communicator     = "winrm"
  cpus             = "${var.cpus}"
  disk_size        = "${var.disk_size}"
  floppy_files     = ["${path.root}/mnt/Autounattend.xml"]
  headless         = "${var.headless}"
  iso_checksum     = "${var.iso_checksum}"
  iso_url          = "${var.iso_url}"
  memory           = "${var.memory}"
  shutdown_command = "${var.shutdown_command}"
  switch_name      = "${var.vm_switch}"
  vm_name          = "${var.vm_name}"
  winrm_password   = "${var.password}"
  winrm_timeout    = "10000s"
  winrm_username   = "${var.user_name}"
  output_directory = "${path.root}/${var.distribution_directory}"
}

build {
  sources = ["source.hyperv-iso.base-image"]

  provisioner "comment" {
    comment     = "Copying required files to c:/${var.starter_kit_directory}/ in the virtual machine"
    ui          = true
    bubble_text = false
  }

  provisioner "file" {
    destination = "c:/${var.starter_kit_directory}/"
    sources     = [
      "${path.root}/build/${var.starter_kit_zip}"
    ]
  }

  provisioner "comment" {
    comment     = "Extract Starter Kit Files"
    ui          = true
    bubble_text = false
  }

  provisioner "powershell" {
    debug_mode        = "${var.debug_mode}"
    elevated_password = "${var.password}"
    elevated_user     = "${var.user_name}"
    inline            = [
      "$ErrorActionPreference = 'Stop'",
      "Set-Location c:/${var.starter_kit_directory}/",
      "Expand-Archive -Path ${var.starter_kit_zip} -Destination .",
    ]
  }

  # Developer note: why not run `Install-Everything.ps1`? Because this system
  # times out after 35 minutes. To avoid that, we'll just run the same steps
  # as that script, but split into separate provisioners here.

  provisioner "comment" {
    comment     = "Configure Windows in preparation for Starter Kit install"
    ui          = true
    bubble_text = false
  }

  provisioner "powershell" {
    debug_mode        = "${var.debug_mode}"
    elevated_password = "${var.password}"
    elevated_user     = "${var.user_name}"
    inline            = [
      "Import-Module -Name 'c:/${var.starter_kit_directory}/scripts/modules/Configure-Windows.psm1' -Force -Global",
      "Set-TLS12Support",
      "Set-ExecutionPolicy bypass -Scope CurrentUser -Force"
    ]
  }

  provisioner "comment" {
    comment     = "Install third party applications using default configuration values"
    ui          = true
    bubble_text = false
  }

  provisioner "powershell" {
    debug_mode        = "${var.debug_mode}"
    elevated_password = "${var.password}"
    elevated_user     = "${var.user_name}"
    inline            = [
      "c:/${var.starter_kit_directory}/scripts/Install-ThirdPartyApplications.ps1"
    ]
  }

  provisioner "comment" {
    comment     = "Install Ed-Fi Technology Suite using default configuration values"
    ui          = true
    bubble_text = false
  }

  provisioner "powershell" {
    debug_mode        = "${var.debug_mode}"
    elevated_password = "${var.password}"
    elevated_user     = "${var.user_name}"
    inline            = [
      "c:/${var.starter_kit_directory}/scripts/Install-EdFiTechnologySuite.ps1",
      "Stop-Service -name WAS -Force -Confirm:$False",
      "Start-Service -name W3SVC"
    ]
  }

  provisioner "comment" {
    comment     = "Install Starter Kit files using default configuration values"
    ui          = true
    bubble_text = false
  }

  provisioner "powershell" {
    debug_mode        = "${var.debug_mode}"
    elevated_password = "${var.password}"
    elevated_user     = "${var.user_name}"
    inline            = [
      "c:/${var.starter_kit_directory}/scripts/Install-StarterKit.ps1"
    ]
  }

  provisioner "comment" {
    comment     = "Optimizing the virtual machine size"
    ui          = true
    bubble_text = false
  }

  provisioner "powershell" {
    debug_mode        = "${var.debug_mode}"
    elevated_password = "${var.password}"
    elevated_user     = "${var.user_name}"
    inline            = [
      "$ErrorActionPreference = 'Stop'",
      "Remove-Item c:/${var.starter_kit_directory}/* -Recurse -Force",
      "Optimize-Volume -DriveLetter C"
    ]
  }
}
