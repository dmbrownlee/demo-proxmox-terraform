# demo-proxmox-terraform Summary
This project provides example files demonstrating how to automate the creation and configuration of Proxmox virtual machines using a combination of Packer, Terraform and Ansible.  There is a lot learn when setting this up and, rather than being an exhaustive explanation, this project aims to provide a working example to tinker with while you explore the pieces you find interesting.

# Prerequisites
TL;DR: You will need:
- a Proxmox cluster (a single node cluster is fine) for which you have admin rights.
- a Linux client (workstation, laptop, or virtual machine) capable of running OCI Linux containers
- a local clone of this git repo

It is assumed you are familiar with Linux and, obviously, the more you already know about packer, terraform, ansible, containers, etc. the easier it will be for you.

## Create a terraform account within Proxmox
You will need to create a Proxmox account for Terraform and generate an API token it can use for authentication.  The process for how to do that is here:
https://github.com/Telmate/terraform-provider-proxmox/blob/master/docs/index.md

Once you have created the account and token, update ~/.proxmox.yml with your specifics.

## Install podman (or docker)
For repeatability, most work will be done from within a container with a specific set of preconfigured tools. You will need to install git and podman (or docker) to build and run this development container. I'm using podman on Debian Linux, but this should also work with Docker and other Linux distributions.  Since we are not yet working with the environment inside the container, you may need to alter these instuctions to fit your particular distribution if you using something different.

   ```shell
   sudo apt install -y git podman
   ```

## Clone this repository to your home directory
You need a local copy of this repo so you can create a development container for the rest of the exercises.
   ```shell
   cd && git clone https://github.com/dmbrownlee/demo-proxmox-terraform.git
   ```

At this point, you should have a copy of this repository locally and you should be able to run the 'hello-world' container with podman (or docker) using `podman run hello-world`.  If that looks good, change to the `~/demo-proxmox-terraform/devcontainer` directory and proceed with the instructions in the `README.md` file to build the development container.
