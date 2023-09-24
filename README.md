# demo-proxmox-terraform
Files for demonstrating packer, terraform and ansible in conjunction with proxmox.

# Getting Started
This porject provides hands-on labs for learning to automate the Proxmox virtual machines using a combination of Packer, Terraform and Ansible.  It is assumed you are familiar with Linux and have Proxmox installed on a machine on your network.  Familiarity with Python and OCI containers may also be helpful, but hopefully not necessary.

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
