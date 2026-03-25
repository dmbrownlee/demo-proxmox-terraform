###############################################################################
###############################################################################
##
##  Resource Definitions
##
###############################################################################
###############################################################################
resource "dns_a_record_set" "portainer" {
  for_each  = { for vm in var.vms : vm.hostname => vm if vm.role == "portainer" }
  zone      = "${each.value.domain}."
  name      = each.key
  addresses = [split("/", each.value.ipv4_address)[0]]
  ttl       = 300
}
