###############################################################################
###############################################################################
##
##  Variable Definitions
##
###############################################################################
###############################################################################
# Used in setting up both DNS and the control planes.
variable "k8s_vip" {
  description = "Floating virtual IP of the external loadbalancer"
  type        = string
}

variable "k8s_vip_hostname" {
  description = "Hostname associated with the floating VIP"
  type        = string
}

###############################################################################
###############################################################################
##
##  Dynamic DNS
##
###############################################################################
###############################################################################
# These variables allow Terraform to dynamically update DNS with resource
# records for the VMs it creates (RFC 2845)
variable "dns_server" {
  description = "DNS server to receive updates"
  type        = string
}
variable "dns_key_name" {
  description = ""
  type        = string
}
variable "dns_key_algorithm" {
  description = ""
  type        = string
  default     = "hmac-md5"
}
variable "dns_key_secret" {
  description = ""
  type        = string
}


###############################################################################
###############################################################################
##
##  Cloud-init
##
###############################################################################
###############################################################################
variable "ci_user" {
  description = "Default cloud-init account"
  type        = string
}

variable "ci_password" {
  description = "Password for cloud-init account"
  type        = string
  sensitive   = true
}


###############################################################################
###############################################################################
##
##  Control host
##
###############################################################################
###############################################################################
variable "ssh_keystore" {
  description = "Local path to directory of SSH keys"
  type        = string
}


###############################################################################
###############################################################################
##
##  Proxmox
##
###############################################################################
###############################################################################
variable "endpoint" {
  description = "URL of the Proxmox cluster API"
  type        = string
}

variable "api_token" {
  description = "Proxmox API token"
  type        = string
}

variable "node_vlan_interfaces" {
  description = "Map of ethernet bridge interfaces by PVE node"
  type        = map(string)
}

variable "vm_storage" {
  description = "Name of Proxmox storage location where VM disks are stored"
  type        = string
  default     = "local-lvm"
}

variable "vm_template_storage" {
  description = "Proxmox node and storage name where VM templates are stored"
  type = object({
    node = string,
    name = string
  })
}


###############################################################################
###############################################################################
##
##  VLANs
##
###############################################################################
###############################################################################
variable "vlans" {
  description = "Map of VLAN objects indexed on name"
  type = list(object({
    vlan_id          = number,
    comment          = string
    ipv4_gateway     = string,
    ipv4_dns_servers = list(string)
  }))
}


###############################################################################
###############################################################################
##
##  Virtual Machines
##
###############################################################################
###############################################################################
variable "vms" {
  description = "The list of Proxmox VMs"
  type = list(object({
    vm_id            = number,
    hostname         = string,
    role             = string,
    pve_node         = string,
    cloud_init_image = string,
    hardware = object({
      cpu_cores = number,
      memory    = number,
      disk      = number
    })
    mac_address  = string,
    vlan_id      = number,
    ipv4_address = string
  }))
}
