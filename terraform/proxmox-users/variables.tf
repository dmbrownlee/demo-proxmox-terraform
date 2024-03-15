variable "endpoint" {
  description = "URL of the Proxmox cluster API"
  type        = string
}

variable "pveroot_user" {
  description = "Proxmox administration account key filename"
  type        = string
  default     = "pveroot"
}

variable "rootaccount" {
  description = "Default Proxmox administration account"
  type        = string
  default     = "root@pam"
}

variable "rootpassword" {
  description = "Password for default Proxmox administration account"
  type        = string
  sensitive   = true
}

variable "terraform_proxmox_account" {
  description = "Terraform administration account"
  type        = string
  default     = "terraform@pve"
}

variable "ci_user" {
  description = "Default cloud-init user"
  type        = string
  default     = "ansible"
}

variable "ssh_keystore" {
  description = "Path to directory of SSH keys"
  type        = string
  default     = "~/keys"
}
