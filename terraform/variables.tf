# These variables are for the Proxmox provider
variable "my_api_url" {
  description = "URL of the Proxmox cluster API"
  type        = string
}

variable "my_api_token_secret" {
  description = "Proxmox API token secret"
  type        = string
}

variable "my_api_token_id" {
  description = "Proxmox API token ID"
  type        = string
}

# These variables describe VM resources
variable "cores" {
  description = "The number of CPU cores per socket"
  type        = number
  default     = 1
}

variable "memory" {
  description = "The amount of RAM (in MB)"
  type        = number
  default     = 1024
}

variable "disk_size" {
  description = "The size of the virtual hard disk"
  type        = string
  default     = "40G"
}

# These variables designate how many VMs to create and where
variable "vm_count" {
  description = "The number of VMs to create"
  type        = number
}

variable "target_node" {
  description = "The Proxmox node on which to create the VMs"
  type        = string
}

variable "storage" {
  description = "The Proxmox storage pool on which to place the VM disks"
  type        = string
  default     = "local-lvm"
}

variable "vlan" {
  description = "The VLAN tag for the primary network interface"
  type        = string
  default     = ""
}
