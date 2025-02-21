# Manage virtual machines for projects
This directory is NOT a Terraform project, but contains subdirectories for example Terraform projects.  Most of these projects use the virtual machine templates created in the previous step to clone one or more virtual machines.

> [!NOTE]
> As always, make sure you `git pull` to get the latest content.

Each project subdirectory contains its own README.md file with detailed instructions.  Have fun creating your own projects!

> [!CAUTION]
> When you create a "full" clone of a virtual machine template, Proxmox makes a copy of the template's disk and gives the copy to the new virtual machine.  The alternative is "linked" clones which give the new virtual machine an overlay file system and use the template's disk underneath.  All my example files use "full" clones which take longer to spin up, but the disks can be resized and the new disks are independent of the disk images in the original template.  If you create "linked" clones in your projects, Terraform will not be able to delete templates if "linked" clones are still using them.  Just keep it simple and always use "full" clones unless you have a compelling reason not to.

# Project Links
## DNS
[static-dns](static-dns/)

This project is uses Terraform to manage resource records on my local DNS server for devices that exist outside of other Terraform projects.  These are DNS records for physical devices like network gear, NAS servers, Proxmox nodes, and IoT devices.  This project does not create any virtual machines (I'm instead running BIND in a container) so it does not require any of the previous projects used to create virtual machine templates, but it does require you to have a local DNS server configured to accept DNS updates.

## Kubernetes
[k8s](k8s/)

This is the project I used to spin up vanilla Kubernetes on Ubuntu virtual machines when studying for the CKAD and CKA exams.  The goal was to mimic the environment of the exams as closly as possible.  The Ansible playbooks install the Kubernetes command line tools (`kubeadm`, `kubectl`, `helm`, etc.) and configure short aliases for both exams.  In the CKAD example, the Kubernetes cluster is installed for you so you can begin using `kubectl` right away.  Since the CKA exam objectives list installing a cluster as an objective, the Ansible playbooks do not do this for you.  In both examples, the projects can optionally update your local DNS server if it is configured to allow updates.

## K3S
[k3s](k3s/)

This is the Kubernetes distribution I run at home for various reasons that are mostly historical.  Most of my Ansible playbook work is done here as I try out different apps for my home lab.  This project can optionally update your local DNS server if it is configured to allow updates.

## YunoHost
[yunohost](yunohost)

I set this up as a technology preview for a local user group that was interested in playing with YunoHost.  I don't use it myself, I don't think they have ever played with it, and I'm not even sure if it still works. It may go away soon.  

