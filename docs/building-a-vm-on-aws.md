# Building a VM on AWS

One of the aims of the Ed-Fi Starter Kits is to provide virtual machine images
on AWS, so that prospective users of the starter kit can easily start up their
own instance and investigate the software. This developer-oriented document
describes the processes for creating and maintaining such images.

## Starting from Scratch

1. Sign-in to the Ed-Fi account on AWS, and choose region `US East - Ohio`.
2. Navigate to EC2 and "Launch an Instance".
3. Choose the Windows 2019 Base image. Do not choose one of the images with SQL
   Server or other software. Do not choose one with "Core" in the name, as that
   will not have a desktop experience. Actual base image used for the first VM:
   `amazon/Windows_Server-2019-English-Full-Base-2021.08.11`.
4. Start up the instance.
5. The password will be encrypted with a key that you choose while following the
   steps above. Now you ned to go to the list of all instances. Select the new
   instance, then click on the Actions button at the top and go to Security >
   Get Windows password. This will let you temporarily upload your private key
   to decrypt the password. Save this password somewhere secure for others on
   the team to access it.
6. Connect to the new instance via RDP, using the IP address listed on the
   instance's "Details" panel.
7. Now that you have a running instance, you need to install all of the software
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

8. Now you can open a PowerShell window. It will be in administrative mode
   automatically, as required to run the script. Navigate to the directory with
   the scripts and run `Install-Everything.ps1`. If everything has
   been done right, it will run for a while and install everything needed.
9. Review and address any errors.

## Creating an Amazon Machine Image (AMI)

1. Do not run SysPrep! It will cause problems for the self-signed cert and break
   access to the database.
2. Navigate to the Instances list and select the instance that you want to
   capture as an image.
3. In the Actions menu, select Images and templates > Create Image.
4. The web site will walk you through the process. Some input parameters:
   * AMI Name: `Ed-Fi Engage Online Learners Starter Kit`
   * Description: `Contains all tools required to run the Ed-Fi "Engage Online
     Learners" Starter Kit. https://techdocs.ed-fi.org/display/SK`
   * Tags:
     * Starter-Kit: `Engage Online Learners`
     * Version: bump from the previous pre-release or Semantic version number as
       appropriate.
5. Image creation takes a few minutes. When the AMI is ready in the AMIs list,
   select the new AMI and look at the Permissions panel below the list. Change
   the permission from Private to Public.
