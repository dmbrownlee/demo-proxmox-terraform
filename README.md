# demo-proxmox-terraform Summary
This project provides example files demonstrating how to automate the configuration of Proxmox and creation of virtual machines.  There is a lot learn when setting this up and, rather than being an exhaustive explanation, this project aims to provide a working example to tinker with while you explore the pieces you find interesting.

## Prerequisites
TL;DR: You will need:
- a Proxmox cluster (a single node is fine, a three node cluster is better) for which you have admin rights.
- Terraform and Ansible installed (alternatively, you can use my demo devcontainer which has been moved to its own repo: https://github.com/dmbrownlee/demo-containers/tree/main/devcontainer)

It is assumed you are familiar with Linux and, obviously, the more you already know about terraform, ansible, containers, etc. the easier it will be for you.

## Create a terraform account within Proxmox
By default, Proxmox has a root account and you could use an API token with that.  However, it's probably a better idea to create a Proxmox account specifically for Terraform and generate an API token it can use for authentication.  Given the types of configuration changes we will make with Terraform, the Terraform account will still have extensive prrivileges, but we can restritct it where possible and disable it entirely if need be without affecting the root account.

Since you only need to do this once, there is a separate directory with Terraform configs that will create the Terraform role and account with the necessary permissions to make setup easier.  This is the only Terraform configuration that needs to use the root account.  After that, the Terrafrom account will be used.  Follow the directions in that directory's [README.md](proxmox-users/README.md) before proceeding.

## Create the cloud-init template VMs.
The virtual lab networks in the project directories create virtual machines by cloning templates.  Before you try to spin up a lab network, make sure you have already run ```terraform apply``` from within the ```proxmox-cloud-init``` directory.

## Configure one (or more) virtual lab networks in Proxmox using Terraform
The Terraform configs in the various lab-* directories will configure VLANs, clone VM templates to various virtual machines, and then use Ansible to configure those virtual machines for different roles.  It is an evolving work in progress.  See the README.md in each project's directory for the latest info.
