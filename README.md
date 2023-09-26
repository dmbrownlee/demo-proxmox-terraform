# demo-proxmox-terraform Summary
This project provides example files demonstrating how to automate the creation and configuration of Proxmox virtual machines using a combination of Packer, Terraform and Ansible.  There is a lot learn when setting this up and, rather than being an exhaustive explanation, this project aims to provide a working example to tinker with while you explore the pieces you find interesting.

# Prerequisites
TL;DR: You will need:
- a Proxmox cluster (a single node cluster is fine) for which you have admin rights.
- a Linux client (workstation, laptop, or virtual machine) capable of running OCI Linux containers

It is assumed you are familiar with Linux and, obviously, the more you already know about packer, terraform, ansible, containers, etc. the easier it will be for you.

# Getting Started
The example files here will spin up a Debian virtual machine in Proxmox.  Before we can run them, we need to do some initial setup.  Specifically, we need to:
- Download the Debian installation media
- Create a terraform account within Proxmox
- Build a development container with all the necessary tools

## Download the Debian installation media

## Create a terraform account within Proxmox

## Build a development container with all the necessary tools
For repeatability, most work will be done from within a container with a specific set of preconfigured tools. Of course, the exception to this is you will need to be able to build and run this development container on your Linux distribution. I'm using podman and Debian, but as far as I know, this should also work with Docker and other Linux distributions.  However, if you use a different Linux distrubtion, the names of the packages and commands to install them may differ and you will need to adjust them accordingly.

1. Install git and podman
   ```shell
   sudo apt install -y git podman
   ```
1. Clone this repository to your home directory
   ```shell
   cd && git clone https://github.com/dmbrownlee/demo-proxmox-terraform.git
   ```

At this point, you should have a copy of this repository locally and you should be able to view the version of podman (or docker) with `podman -v`.  If that looks good, change to the `~/demo-proxmox-terraform/devcontainer` directory and proceed with the instructions in the `README.md` file there.
