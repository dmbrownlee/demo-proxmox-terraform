#===========================================================
# These variables are used by the Terraform Proxmox provider
#
# Rather than editng the default values here, you can
# override them in terraform.tfvars
#===========================================================
variable "api_token" {
  description = "Proxmox API token"
  type        = string
}

variable "endpoint" {
  description = "URL of the Proxmox cluster API"
  type        = string
  default     = "https://pve1.example.com:8006/"
}
