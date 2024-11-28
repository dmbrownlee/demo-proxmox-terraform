###############################################################################
###############################################################################
##
##  Variable Definitions
##
###############################################################################
###############################################################################

# Note: This file only defines the variables available.  The values for these
#       variables are assigned in the network.auto.tfvars file.

variable "bridges" {
  description = "A list of bridge names managed by this lab"
  type        = list(object({
    comment = string,
    name = string,
    node_name = string,
    vlan_aware = bool,
  }))
  default     = []
}

variable "vlans" {
  description = "Map of VLAN objects indexed on name"
  type = list(object({
    comment          = string,
    interface        = string,
    node_name        = string,
    vlan_id          = number,
  }))
}

###############################################################################
###############################################################################
##
##  Resource Definitions
##
###############################################################################
###############################################################################

resource "proxmox_virtual_environment_network_linux_bridge" "bridges" {
  for_each = tomap({ for bridge in var.bridges: "${bridge.node_name}-${bridge.name}" => bridge })
  comment    = each.value.comment
  name       = each.value.name
  node_name  = each.value.node_name
  vlan_aware = each.value.vlan_aware
}

resource "proxmox_virtual_environment_network_linux_vlan" "vlans" {
  depends_on = [
    proxmox_virtual_environment_network_linux_bridge.bridges
  ]
  for_each = tomap({ for vlan in var.vlans : "${vlan.node_name}-${vlan.interface}.${vlan.vlan_id}" => vlan })
  comment   = each.value.comment
  interface = each.value.interface
  name      = "${each.value.interface}.${each.value.vlan_id}"
  node_name = each.value.node_name
  vlan      = each.value.vlan_id
}
