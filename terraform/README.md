# Proxmox Variables
Terraform needs three pieces of information in order to connect to Proxmox, the API URL, the ID of the authentication token to use, and that token's secret.  The name of the token is arbitrary, but it is associated with a specific login and that account must have enough access rights to create and destroy virtual machines as needed by terraform.  The token secret will only be displayed when you create the token.  If you lose it, you will need to generate a new token.

In `variables.tf`, We've defined my_api_url, my_api_token_id, and my_api_token_secret as the variables in which to store these three values. We can populate these variables with values in three ways, on the command line, in the environment, and it a terraform.tfvars file.

## Command line method
If you are a glutten for punishment, you can type these out everytime you run terraform:
```shell
terraform apply -var "my_api_url=https..." -var "my_api_token
my_api_url          = "https://pve1.example.com:8006/api2/json"
my_api_token_secret = "01234567-89ab-cdef-0123-456789abcdef"
my_api_token_id     = "terraform@pve!token1"
```ini
Yeah, we're not going to do that.

## Environment method
Terraform automatically populates variables from the environment variables beginning with TF_VAR_ so you could add the following to your .bashrc or similar:
```shell
export TF_VAR_my_api_url='https://pve1.example.com:8006/api2/json'
export TF_VAR_my_api_token_secret='01234567-89ab-cdef-0123-456789abcdef'
export TF_VAR_my_api_token_id='terraform@pve!demo'
```
The issue with this method is that you might not want these values in your environment where they can be read by any process you start.

## Terraform varaible values file
Lastly, you can save the values in a file with a .tfvars extension and terraform with assign those values automatically.  This isn't a bad way to go, but make sure you don't accidentally check them into a publically accessible git repo (the .gitignore file in this repo ignores these files).

```ini
# terraform.tfvars
my_api_url          = "https://pve1.example.com:8006/api2/json"
my_api_token_secret = "01234567-89ab-cdef-0123-456789abcdef"
my_api_token_id     = "terraform@pve!token1"
```

# Login
provision_username  = "ansible"
