# Manage virtual machine templates
This Terraform project creates virtual machine templates using the installation media managed in the previous project.  These virtual machine templates will be cloned to create virtual machines for subsequent projects.

> [!NOTE]
> As always, make sure you `git pull` to get the latest content.  As with the previous steps, run `terraform init` if this is your first time using this project.  If this is not your first time and Terraform is complaining the version numbers referenced in the files you just pulled are newer that the versions you have already downloaded, run `terraform init -update`.  Finally, if you are using a version of Terraform newer than what I'm using, you make need to update the version number for Terraform in `main.tf` and hope the new version is backwards compatible (or debug the issues that arrise).

Create a Terraform workspace for each collection of virtual machine templates you want to manage as a single unit.  You can have each workspace manage a single template or group of templates, the choice is yours.  The example files provided here group the virtual machines by ditribution, but that choice is arbitrary.  The key takeaway is that running `terraform apply` will handle all the templates specified in the corresponding `.tfvars` file.  Make copies of the example files with the `.example` extension removed and name that matches the workspace (assuming you will use the shell aliases).  Edit for your site's specifics, which ISO images you want downloaded, and from where you want to fetch them.  Here is what this process looks like using the example files for Debian and Ubuntu:

> [!TIP]
> Don't worry about the amount of RAM or CPU cores in the virtual machine template as these can easily be changed when you clone the template into a virtual machine.  Disk size can also be changed, but resizing the disk during cloning takes time so you probably want to specify a disk size in your template that you will use for the majority of your virtual machines to speed up the cloning.

> [!NOTE]
> Remember to substitute `terraform` below with `tofu` if you are using the Open Tofu fork of Terraform

```shell
# Create the "debian" workspace.  You can use the "tws" alias if it already exists.
terraform workspace new debian

# Copy the example file, removing the .example extension
cp debian.tfvars.example debian.tfvars

# Edit the Terraform variable file to specify the installation media to use
vim debian.tfvars

# Use the alias to download the Debian cloud-init images to Proxmox
ta

# Repeat the same steps for Ubuntu
terraform workspace new ubuntu
cp ubuntu.tfvars.example ubuntu.tfvars
vim ubuntu.tfvars
ta
```

You should now have virtual machine templates which you can clone into virtual machines for your projects.  From time to time, you will want to revisit your `.tfvars` files and update the virtual machine templates after you have updated the installation media used to create them.

## Notes about variables in the `.tfvars` files
Each element of the `vm_templates` map corresponds to a virtual machine template you want to manage.  Removing an element will delete the template when your run `terraform apply`.  The key for each element (e.g. `debian12-genericcloud-20250210`) is how you will identify which template you want to clone when creating virtual machines.  The `node_name` and `datastore` variables specify where you will save the finished template and `vm_id` is the unique identifier within the Proxmox cluster.

> [!WARNING]
> Proxmox identifies all virtual machines and virtual machine templates with a unique number which is specified by the `vm_id` attribute in the `.tfvars` file.  Terraform will fail to create the virtual machine template if the number is already in use by another virtual machine or template. It is your responsibility to ensure the `vm_id` you choose is not already in use.

vm_templates = {
  debian12-genericcloud-20250210 = {
    file_name = "local-lvm:iso/debian-12-genericcloud-amd64-20250210.qcow2.img",
    node_name = "pve1"
    vm_id     = 998,
    datastore = "local-lvm"
    disk_size = 4,
  },
  debian12-genericcloud-20250112 = {
    file_name = "local-lvm:iso/debian-12-genericcloud-amd64-20250112.qcow2.img",
    node_name = "pve1"
    vm_id     = 999,
    datastore = "local-lvm"
    disk_size = 4,
  },
}
