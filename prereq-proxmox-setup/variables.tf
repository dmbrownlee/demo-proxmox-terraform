#===========================================================
# These variables are used by the Terraform Proxmox provider
#
# Rather than editng the default values here, you can
# override them in the terraform.tfvars file.
#===========================================================
variable "endpoint" {
  description = "URL of the Proxmox cluster API"
  type        = string
}

# Only this specific project uses these to variables.  Other
# projects will instead use an api_token which you will create
# for the account that this project is creating.
variable "pverootaccount" {
  description = "Default Proxmox administration account"
  type        = string
  default     = "root@pam"
}

variable "pverootpassword" {
  description = "Password for default Proxmox administration account"
  type        = string
  sensitive   = true
}
