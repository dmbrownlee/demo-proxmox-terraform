###############################################################################
###############################################################################
##
##  Variables
##
###############################################################################
###############################################################################
variable "bridges" {
  description = "A list of bridge objects"
  type = list(object({
    name      = string,
    node_name = string,
    # address          = string,
    # address6         = string,
    # autostart        = bool,
    comment = string,
    # gateway          = string,
    # gateway6         = string,
    # mtu              = number,
    # ports            = list(string),
    vlan_aware = bool,
  }))
}


###############################################################################
###############################################################################
##
##  Resources
##
###############################################################################
###############################################################################
resource "proxmox_virtual_environment_network_linux_bridge" "bridges" {
  for_each = tomap({
    for bridge in var.bridges : "${bridge.node_name}:${bridge.name}" => bridge
  })
  name       = each.value.name
  node_name  = each.value.node_name
  # address    = each.value.address
  # address6   = each.value.address6
  # autostart  = each.value.autostart
  comment    = each.value.comment
  # gateway    = each.value.gateway
  # gateway6   = each.value.gateway6
  # mtu        = each.value.mtu
  # ports      = []
  vlan_aware = each.value.vlan_aware
}
