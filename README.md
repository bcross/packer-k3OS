## Instructions
Currently supported platforms
* Windows 10 Hyper-V

Generate your ssh keys. It is recommended to store these in $env:USERPROFILE\.ssh. Just run ssh-keygen in command line/PowerShell.

Running RunMe.ps1 will run Bootstrap.ps1, then Build.ps1, then Deploy.ps1. Run Clean.ps1 to clean up all VMs and start over. 

You will be asked to allow Packer through the firewall. You only need to allow it to Public networks.

The scripts are designed to be quiet. As Packer runs, all output is stored in packer_logs. If it feels stuck, go there to see why.

Run Bootstrap.ps1 -Force to update binaries and the k3OS iso.

## What you end up with
* VMs stored in the vms folder.
* config file in $env:USERPROFILE\\.kube folder. This is used by kubectl and helm to communicate with the cluster.
* A fully functional Kubernetes cluster managed by Rancher.

## How to use it 
Add the master IP address from Build.ps1 and the hostname from Deploy.ps1 to your hosts file.

Go there with a browser.