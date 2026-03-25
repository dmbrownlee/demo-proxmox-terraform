###############################################################################
###############################################################################
##
##  Variable Definitions
##
###############################################################################
###############################################################################
# variable "k3s_cnames" {
#   description = "List of CNAME resource records to point to the cluster"
#   type        = list(string)
#   default     = []
# }
#
# variable "enable_live_cnames" {
#   description = "Create additional CNAME resource records for live services?"
#   type        = bool
#   default     = false
# }
#
# variable "enable_dev_cnames" {
#   description = "Create additional CNAME resource records for dev services?"
#   type        = bool
#   default     = false
# }

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
