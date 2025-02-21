# demo-proxmox-terraform Summary
This project provides example files demonstrating how to automate the creating and configuration of virtual machines in Proxmox using Terraform and Ansible.  There is a lot learn when setting this up and, rather than being an exhaustive explanation, this project aims to provide a working example to tinker with while you explore the pieces you find interesting.

## Prerequisites
TL;DR: You will need:
- a Proxmox cluster (a single node is fine, a three node cluster is better) for which you have admin rights.
- Terraform and Ansible installed

If you can't or don't want to install Terraform and Ansible, I have a container with the neccessary tools pre-installed in its own repo: https://github.com/dmbrownlee/demo-containers/tree/main/devcontainer.  Of course, that requires a podman/docker installation to use.

> [!note] I'm actually using Open Tofu, a fork of Terraform and that is what is installed in my container image.  Just substitute `tofu` wherever you see `terraform` in the commands.

It is assumed you are familiar with Linux and, obviously, the more you already know about terraform, ansible, containers, etc. the easier it will be for you.

## Introduction
### Terraform
This project involves multiple steps, each with its own directory.  As indicated by the directory names, the steps should be done in order.  Change into the directory and read the README.md for the procedure for each step.

Generally, each directory is its own Terraform project which automates an isolated task.  The Terraform projects work as templates for the resources to be managed and can be re-used for multiple distinct cases by using different Terraform variable files (they have a `.tfvars` extension).  For example, there is a directory with a Terraform project that maintains ISO images of installation media downloaded from the Internet and uploaded to the Proxmox cluster.  You can create a `debian.tfvars` variable file containing the details of the installation media for Debian and another `ubuntu.tfvars` variable file containing the details of the installation media for Ubuntu and then use the Terraform project to manage either (or both, described next).

Terraform stores the state of the resources it manages in a "workspace" and you have one workspace by default named "default".  With only one workspace, if you run `terraform apply -var-file debian.tfvars` to download the Debian installation media to your Proxmox ISO storage and then run `terraform apply -var-file ubuntu.tfvars`, Terraform will delete the Debian installation media from your Proxmox cluster before downloading the Ubuntu installation media because the details of the Debian installation media do not exist in the `ubuntu.tfvars` file and Terraform assumes you no longer want those resources.  Likely, this is not what you will want most of the time.  If you want to use multiple variable files simultaneously within a single project directory, you will need to create a workspace for each.  You can create a new workspace called "debian" and switch to it with `terraform workspace new debian`.  Use `terraform workspace list` to list the workspaces which already exist and identify which workspace you are currently using (as denoted with an asterisk).  Use `terraform workspace select ubuntu` to switch to the "ubuntu" workspace (if you have already created one).  For other workspace related commands, there is `terraform workspace help`.

> [!note:] You cannot delete the "default" workspace.  Creating a workspace creates a new directory for storing state files and the "default" workspace uses the current directory as the state directory when no other workspace has been selected.

Switching between workspaces is a common occurence so it is helpful to adopt some conventions to make this easier.  First, name your variable files using the workspace name with a `.tfvars` extension (i.e. the `debian.tfvars` will be used with the "debian" workspace and the `ubuntu.tfvars` file will be used with the "ubuntu" workspace).  Next, create shell aliases that use these workspace names.  Besides saving yourself some typing, using aliases will save you from forgetting to pass the variable file as an option or, worse, using the wrong variable file as an argument.  Here are the aliases I'm using:

> [!note:] As mentioned above, I'm using the Open Tofu fork of Terraform so my aliases use `tofu` instead of `terraform`.  Adjust for your environment as needed.

```shell
# List all workspaces and note which is current
alias twl='tofu workspace list'

# Change to a different workspace
alias tws='tofu workspace select'

# Check the state of the resources in this workspace
alias tsl='tofu state list'

# Create/modify the resources defined in this workspace
alias ta='tofu apply -var-file $(tofu workspace show).tfvars -parallelism=1'

# Destroy the managed resources
alias td='tofu destroy -var-file $(tofu workspace show).tfvars'
```

### Ansible
Terraform is all you need to manage VLANs, installation media, virtual machine templates, virtual machines, DNS records, etc.  If you always want a clean OS installation in your virtual machines, you are good to go.  Ansible can be used when you want to configure your virtual machines for specific uses after they have been provisioned.  Technically, you can run Ansbile from within your Terraform configs, but down that road lies madness.  Keep provisioning virtual machines seperate from configuring them.  The reason is you will repeatedly run Ansible playbooks many times as you tweak them during development and you don't want to waste time tearing down virtual machines and recreating them on every run.  Run Ansible independent of Terraform and when you think you have your Ansible playbooks dialed in, you can then use Terraform to delete the virtual machines and test everything from scratch.

Even though you will run Ansible separately, Terraform is still helpful in that it can dynamically add the virtual machines it creates to your Ansible inventory file and you will see I do this in my example projects.  In my projects, I keep all the Ansible content within a `ansible` subdirectory of the Terraform project.  As with the Terraform variable files, I have a separate Ansible variable file for each workspace matching `ansible/*.vars`.  I could have done this differently by using workspace specific playbooks, for example.  However, the way I'm doing this now is by passing the name of the workspace when running `ansible-playbook` and letting the playbooks include the variable file for the workspace based on that.  This works well and let's me create these aliases for Ansible:

```shell
# Run the main playbook for the project (usually just includes smaller playbooks)
alias ap='ansible-playbook -e tf_workspace=$(tofu workspace show) ansible/playbook.yml'

# Run specific playbook prefixed with ./ansible/... (used while testing)
alias pb='ansible-playbook -e tf_workspace=$(tofu workspace show)'
```

> [!note:] The Terraform and Ansible variable files are where you configure information specific to your site.  These files contain sensitive information so the included `.gitignore` file tells git to ignore them so you don't accidentally commit them to a public git repo.  You will want to backup these files using some other means.

The end result of all the above is that I can create lots of different environments to experiment in.  For example, when I want to spin up a six node Kubernetes cluster with an external loadbalancer in front of three control plane nodes in order to practice for the CKAD exam, I can just run this and wait:

```shell
cd k8s
tws ckad
ta
ap
```

When I'm done, I can destroy it like it never happened with `td`.

Ready to jump in?

## Getting started
First, if you are reading this on GitHub, you will want to clone this repo to the workstation (or container) where you will be running Terraform and Ansible.
```shell
git clone https://github.com/dmbrownlee/demo-proxmox-terraform.git
```
Better still, fork it and clone your own repo via SSH so you can commit your own projects.

> [!note:] Don't forget to `git pull` repo updates periodically to make sure you're getting the latest contents.

There are a couple of things you need to do before you can use Terrafrom with Proxmox.  You will only have to do this once (unless you completely reinstall your Proxmox cluster in which case you're starting from square one).

- [Configure Proxmox for use with Terraform](prereq-proxmox-setup/)

Once Proxmox is setup, we can have Terraform manage installation media downloads and build virtual machine templates we can use as starting points for our projects.

- [Use Terraform to manage installation media in Proxmox's ISO storage](step1-installation-media/)
- [Use Terraform to create virtual machine templates](step2-virtual-machine-templates/)

Lastly, I have some sample projects (each with their own README.md) you can use as a starting point for your own.

- [Use Terraform (and Ansible) to provision and configure virtual machines for projects](step3-project-vms/)
