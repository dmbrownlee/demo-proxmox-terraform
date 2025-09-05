###############################################################################
###############################################################################
##
##  Variables
##
###############################################################################
###############################################################################
variable "vlans" {
  description = "A list of vlan objects"
  type = list(object({
    comment          = string,
    interface        = string,
    node_name        = string,
    vlan_id          = number,
    # ipv4_gateway     = string,
    # ipv4_dns_servers = list(string),
    # netblock         = string,
  }))
}


###############################################################################
###############################################################################
##
##  Resources
##
###############################################################################
###############################################################################
resource "proxmox_virtual_environment_network_linux_vlan" "vlans" {
  for_each = tomap({
    for vlan in var.vlans : "${vlan.node_name}:${vlan.interface}.${vlan.vlan_id}" => vlan
  })
  name      = "${each.value.interface}.${each.value.vlan_id}"
  comment   = each.value.comment
  interface = each.value.interface
  node_name = each.value.node_name
  vlan      = each.value.vlan_id
  # ipv4_gateway     = each.value.ipv4_gateway
  # ipv4_dns_servers = each.value.ipv4_dns_servers
  # netblock         = each.value.netblock
}
