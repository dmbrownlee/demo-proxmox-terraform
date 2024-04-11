# For each node in our Proxmox cluster, we want to loop through all the VLANs.
# However, we cannot do nested for_each loops in Terraform resources so we
# need to create a flattened local list of objects that contains that contains
# the same elements that would have been produced by the nested loops.  See
# https://developer.hashicorp.com/terraform/language/functions/flatten#flattening-nested-structures-for-for_each
# for an explanation and example.

locals {
  node_vlans = flatten([
    for node in data.proxmox_virtual_environment_nodes.available_nodes.names : [
      for vlan in var.vlans : {
        node_name = node
        name      = "${var.node_vlan_interfaces[node]}.${vlan.vlan_id}"
        interface = var.node_vlan_interfaces[node]
        vlan      = vlan.vlan_id
        comment   = vlan.comment
      }
    ]
  ])
}

resource "proxmox_virtual_environment_network_linux_vlan" "vlans" {
  for_each = tomap({
    for node_vlan in local.node_vlans : "${node_vlan.node_name}.${node_vlan.vlan}" => node_vlan
  })
  node_name = each.value.node_name
  name      = each.value.name
  interface = each.value.interface
  vlan      = each.value.vlan
  comment   = each.value.comment
}
