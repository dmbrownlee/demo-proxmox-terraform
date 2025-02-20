variable "endpoint" {
  description = "URL of the Proxmox cluster API"
  type        = string
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
