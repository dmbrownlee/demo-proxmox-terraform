###############################################################################
###############################################################################
##
##  Terraform/OpenTofu provider variables
##
###############################################################################
###############################################################################
# Variables defined here are used to configure the providers.

#==================== bpg/proxmox ====================
variable "endpoint" {
  description = "URL of the Proxmox cluster API"
  type        = string
}

variable "api_token" {
  description = "Proxmox API token"
  type        = string
}
