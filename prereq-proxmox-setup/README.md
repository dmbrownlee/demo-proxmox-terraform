# Prepare Proxmox for use with Terraform
## Keep your software up to date
This repo uses the bpg/proxmox provider plugin for Terraform ([https://registry.terraform.io/providers/bpg/proxmox/latest/docs](https://registry.terraform.io/providers/bpg/proxmox/latest/docs)) which gets frequent updates.  I also push updates to this repo as well.  Make sure you `git pull` to stay current.

If this is the first time you are are using the contents of this directory, you will need to initialize Terraform.  If you don't recall, it doesn't hurt to run it again.
```shell
# This will install the necessary Terraform plugins
terraform init
```

After pulling the latest contents for this repo, you may see Terraform complain about needing newer plugins for the current content.  Just run `terraform init -upgrade` to install the plugins matching the content.  There is also the possibility that at some point in the future you will upgrade to a newer version of Terraform that this project expects.  You can try updating the Terraform version specified in the `main.tf` in the top level directory of each project and that usually works without other changes, but it could break things if the new Terraform is not backwards compatible.  Thankfully, this has not happened yet and updating the `main.tf` has always been the fix so far. 

## Ensure you can SSH to your Proxmox nodes as root
The bpg/proxmox provider for Terraform uses the Proxmox REST API when possible, but certain actions within Proxmox can only be done by an administrator from the command line.  This means the plugin will need to SSH into your Proxmox node(s) as root.  I suggest configuring an SSH keypair for your Proxmox admin account, authorizing the key, and loading the identity into your locally running ssh-agent.  In short, setup password-less SSH for root to your Proxmox nodes before continuing.

## Create an account for Terraform in Proxmox
See [https://registry.terraform.io/providers/bpg/proxmox/latest/docs#authentication](https://registry.terraform.io/providers/bpg/proxmox/latest/docs#authentication) for the plugin authentication details.

By default, Proxmox has a root account and you could use an API token with that.  However, it's better to create a Proxmox account specifically for Terraform and generate an API token it can use for authentication.  Given the types of configuration changes we will make with Terraform, the Terraform account will still have extensive prrivileges, but we can restritct it where possible and disable it entirely if need be without affecting the root account.

You only need to creaate a `terraform` account in Proxmox once and the Terraform configs in this directory will create the Terraform role and account with the necessary permissions.  This is the only Terraform configuration that will use your Proxmox root account to interact with the REST API.  All the other project directories in this repo will use the newly created Terrafrom account.

The rest of the Terraform demo assumes you have configured an administrative account for Terraform in your Proxmox cluster and Terraform will be using that.  For your convenience, the files in this directory can help you configure this account.

```shell
# Make a copy of the example variable file provided without the .example extension.
cp terraform.tfvars.example terraform.tfvars
cp terraform-account.auto.tfvars.example terraform-account.auto.tfvars

# Update the contents of this file with information for your site, specifically,
# the endpoint URL for your Proxmox cluster.
vim terraform.tfvars

# You don't need to change this unless you want to use a different name on the
# account.
vim terraform-account.auto.tfvars

# Create the account for Terraform in Proxmox
terraform apply
```

> [!note:] You probably won't be managing multiple Proxmox users from this project, but if you still want to use the `ta` alias for `terraform apply`, you can can create a "terraform" workspace with `terraform workspace new terraform` or create an empty file named `default.yaml`.  Either will allow the alias to work.

Terraform will prompt you for your Proxmox root@pam password.  This is the only time the demo will ask for your root password.  Terraform will inform you of the changes it plans to make and, if you agree, enter "yes" when prompted.

# Create an API token for the terraform account within Proxmox
Here are the steps for creating an API token for the `terraform@pve` account:

> [!note:] If you changed the default account name, adjust these steps as appropriate.

1. Select your cluster in the Server view on the left side of the Proxmox web interface.
1. In the menu to the right of the Server view, navigate to `Permissions > API Tokens`.  You can add and remove API Tokens from this pane.
1. Click the `Add` button to create a new API Token for `terraform@pve`.  For the `Token ID`, pick a descriptive word (I'll use "demo" in this example).  Uncheck the `Privilege Separation` checkbox.
1. Click the `Add` button and the token ID and Token secrete will be displayed.
1. Copy the Token ID and Token Secret someplace safe as there is no way to retrieve it once you close the dialog.

In the other Terraform project directories you will set an `api_token` variable in a `.tfvars` file to a string that combines the Token ID and Secret separated by an equals sign.  For example, if your Token ID is "terraform@pve!demo" and the Secret is "01234567-89ab-cdef-0123-456789abcdef", you will set `api_token` to "terraform@pve!demo=01234567-89ab-cdef-0123-456789abcdef".
