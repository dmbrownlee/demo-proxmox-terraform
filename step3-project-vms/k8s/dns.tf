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

variable "k8s_vip_domain" {
  description = "DNS domain for VIP and CNAMEs"
  type        = string
}

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
  zone = "${var.k8s_vip_domain}."
  name = var.k8s_vip_hostname
  addresses = [ var.k8s_vip ]
  ttl = 86400
}

resource "dns_cname_record" "k8s_vip_cnames" {
  depends_on = [
    resource.dns_a_record_set.k8s_vip
  ]
  count = length(var.k8s_vip_cnames)
  zone = "${var.k8s_vip_domain}."
  name  = var.k8s_vip_cnames[count.index]
  cname = "${var.k8s_vip_hostname}.${var.k8s_vip_domain}."
  ttl = 86400
}

resource "dns_a_record_set" "k8s_nodes" {
  for_each    = { for vm in var.vms : vm.hostname => vm }
  zone = "${each.value.domain}."
  name = each.key
  addresses = [ split("/", each.value.ipv4_address)[0] ]
  ttl = 86400
}
