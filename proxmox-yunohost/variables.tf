###############################################################################
###############################################################################
##
##  Ansible
##
###############################################################################
###############################################################################
variable "ansible_replayable" {
  description = "Flag whether or not Ansible playbooks can be run again."
  type        = bool
  default     = true
}

variable "sleep_seconds_before_remote_provisioning" {
  description = "The number of seconds to wait after booting before trying SSH"
  type        = number
}

variable "ssh_private_key_files" {
  description = "A map of SSH private key paths"
  type        = map(string)
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
##  Flags for development and testing
##
###############################################################################
###############################################################################
variable "want_ansible_output" {
  type    = bool
  default = false
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
}

variable "vm_template_storage" {
  description = "Proxmox node and storage name where VM templates are stored"
  type = object({
    node = string,
    name = string
  })
}


/* /1* ############################################################################### *1/ */
/* /1* ############################################################################### *1/ */
/* /1* ## *1/ */
/* /1* ##  Site-specific data *1/ */
/* /1* ## *1/ */
/* /1* ############################################################################### *1/ */
/* /1* ############################################################################### *1/ */
/* /1* variable "site_domain" { *1/ */
/* /1*   description = "The DNS domain (used in cloud-init data when creating VMs)" *1/ */
/* /1*   type        = string *1/ */
/* /1*   default     = "example.com" *1/ */
/* /1* } *1/ */


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
