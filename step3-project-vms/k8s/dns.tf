###############################################################################
###############################################################################
##
##  Variable Definitions
##
###############################################################################
###############################################################################
variable "k8s_vip_cnames" {
  description = "List of additional CNAME resource records to point to VIP"
  type        = list(string)
  default     = []
}

###############################################################################
###############################################################################
##
##  Resource Definitions
##
###############################################################################
###############################################################################
resource "dns_a_record_set" "k8s_vip" {
  zone = "${var.dns_domainname}."
  name = var.k8s_vip_hostname
  addresses = [ var.k8s_vip ]
  ttl = 300
}

resource "dns_cname_record" "k8s_vip_cnames" {
  depends_on = [
    resource.dns_a_record_set.k8s_vip
  ]
  count = length(var.k8s_vip_cnames)
  zone = "${var.dns_domainname}."
  name  = var.k8s_vip_cnames[count.index]
  cname = "${var.k8s_vip_hostname}.${var.dns_domainname}."
  ttl = 300
}

resource "dns_a_record_set" "k8s_nodes" {
  for_each    = { for vm in var.vms : vm.hostname => vm }
  zone = "${var.dns_domainname}."
  name = each.key
  addresses = [ split("/", each.value.ipv4_address)[0] ]
  ttl = 300
}
