# Prerequisites
It is assumed you already have `terraform` installed.

# Create an account for Terraform
The rest of the Terraform demo assumes you have configured an administrative account for Terraform in your Proxmox cluster and Terraform will be using that.  For your convenience, the files in this directory can help you configure this account.

```shell
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars  # Update the contents of this file with your site's info
terraform init        # This will install the necessary Terraform plugins
terraform apply
```

Terraform will prompt you for your Proxmox root@pam password.  This is the only time the demo will ask for your root password.  Terraform will inform you of the changes it plans to make and, if you agree, enter "yes" when prompted.  After the Terraform account is created, the rest of the demo will use that account.

# Create an API token for the terraform account within Proxmox
Here are the steps for creating an API token for the `terraform@pve` account:

1. Select your cluster in the Server view on the left side of the Proxmox web interface.
1. In the menu to the right of the Server view, navigate to `Permissions > API Tokens`.  You can add and remove API Tokens from this pane.
1. Click the `Add` button to create a new API Token for `terraform@pve`.  For the `Token ID`, pick a descriptive word (I'll use "demo" in this example).  Uncheck the `Privilege Separation` checkbox.
1. Click the `Add` button and the token ID and Token secrete will be displayed.
1. Copy the Token ID and Token Secret someplace safe as there is no way to retrieve it once you close the dialog.
