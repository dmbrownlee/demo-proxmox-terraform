###############################################################################
###############################################################################
##
##  Variable Definitions
##
###############################################################################
###############################################################################
# Used in setting up both DNS and the control planes.
variable "k3s_vip" {
  description = "Floating virtual IP of the external loadbalancer"
  type        = string
}

variable "k3s_vip_hostname" {
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
