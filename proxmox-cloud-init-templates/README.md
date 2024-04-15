# Configuring Proxmox with Terraform
This project is a work in progress.  Your mileage my vary.

## Prerequisites
This Terraform demo assumes you have configured an administrative account for Terraform in your Proxmox cluster and created an API Token for it.  If not, see [../proxmox-users/README.md](../proxmox-users/README.md).

## Create an API token for the terraform account within Proxmox
First, copy the example Terraform autovars file to `terraform.tfvars` (must be that name) and update the values in that file with your site's specific information.  In particular, you need to make sure the Proxmox API `endpoint` and `api-token` are correct or you won't get very far.

```shell
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars
```

Since we would like to edit the above file once and forget it, and since you might want to change the cloud-init images for which you are creating VM templates more often, the VM template configs are in their own file, vm-template.auto.tfvars (again, remove the .example extension after editing to taste).

Then, initialize Terraform.  This will download the Terraform plugins the demo project will use to communicated with Proxmox and run Ansible.

```shell
terraform init
```

There is a lot more to discuss about the various Terraform files and what they configure.  I've build it specifically for my needs, but you can read Terraform docs and try to tweak it for your own.  Once your happy with them, you can create a Terraform plan and review what will be done.

```shell
terraform plan -out my.plan
```

Finally, if it looks good, execute the plan.  The `-parallelism=2` option limits Terraform to running two tasks in parallel.  I find that running more than that in my environment leads to failures since Terraform cannot get file locks from Proxmox fast enough when cloning the same virtual machine template multiple times simultaneously.

```shell
terraform apply -parallelism=2 my.plan
```

Play with it.  Have fun.  When you're done, you can have Terraform undo all the changes.

```shell
terraform destroy
```
