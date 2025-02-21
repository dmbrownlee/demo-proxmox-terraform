# Manage installation media in Proxmox's ISO storage
This Terraform project directory is used to manage the ISO installation media images in the Proxmox cluster's ISO storage.  Specifically, I'm using it to manage the cloud-init images for both Debian and Ubuntu which I use to create virtual machine templates in the next step.

> [!note:] As always, make sure you `git pull` to get the latest content.

First, run `terraform init` if this is your first time using this project.  If this is not your first time and Terraform is complaining the version numbers referenced in the files you just pulled are newer that the versions you have already downloaded, run `terraform init -update`.  Finally, if you are using a version of Terraform newer than what I'm using, you make need to update the version number for Terraform in `main.tf` and hope the new version is backwards compatible (or debug the issues that arrise).

Next, create a Terraform workspace to manage a set of ISO images.  I group my workspaces by distribution, but that is not a requirement.  Make copies of the example files with the `.example` extension removed and name that matches the workspace (assuming you will use the shell aliases).  Edit for your site's specifics, which ISO images you want downloaded, and from where you want to fetch them.  Here is what this looks like using the example files for Debian and Ubuntu.

```shell
# Create the "debian" workspace.  You can use the "tws" alias if it already exists.
tofu workspace new debian

# Copy the example file using clever shell brace expansion  ;)
cp debian.tfvars{.example,}

# Edit the Terraform variable file to specify which ISO images you want to download.
vim debian.tfvars

# Use the alias to download the Debian cloud-init images to Proxmox
ta

# Follow the same steps for Ubuntu
tofu workspace new ubuntu
cp ubuntu.tfvars{.example,}
vim ubuntu.tfvars
ta
```

You should now have the downloaded installation media in your Proxmox ISO storage.  From time to time, you will want to revisit your `.tfvars` files and update the images and virtual machine templates you have on hand to minimize how much time the cloned cloud-init virtual machines spend updating packages on first boot.  If you remove a reference to an ISO file that Terraform previously installed, Terraform will remove it from the Proxmox ISO storage the next time you run `terraform apply`.

## A notes about variables in the `.tfvars` files
The `iso_storage` variable specifies a Proxmox node name and the name of the Proxmox storage.  If the storage name used is shared storage such as an NFS share used by all nodes, then it doesn't matter which node name you use for the upload.  All nodes with access to the shared storage will have access to anything uploaded there.

```hcl
iso_storage = {
  node = "pve1",
  name = "local-lvm"
}
```

Each entry in the `cloud_init_images` map is a cloud-init image to download to Proxmox ISO storage.  The map keys (e.g. `debian12-genericcloud-20250210`) are the strings you will use to identify which media to use when creating the virtual machine templates in the next step.

> [!note:] Proxmox is finicky about the filename extentions it lets you upload to the Proxmox ISO storage and does not like the `.qcow2` extension on the original file names in this example.  Appending `.img` to the filename used to store the file works around this limitation.

```hcl
cloud_init_images = {
  debian12-genericcloud-20250112 = {
    url       = "https://cloud.debian.org/images/cloud/bookworm/20250112-1990/debian-12-genericcloud-amd64-20250112-1990.qcow2",
    file_name = "debian-12-genericcloud-amd64-20250112.qcow2.img",
  },
  debian12-genericcloud-20250210 = {
    url       = "https://cloud.debian.org/images/cloud/bookworm/20250210-2019/debian-12-genericcloud-amd64-20250210-2019.qcow2",
    file_name = "debian-12-genericcloud-amd64-20250210.qcow2.img",
  },
}
