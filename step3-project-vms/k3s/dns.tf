###############################################################################
###############################################################################
##
##  Variable Definitions
##
###############################################################################
###############################################################################
variable "k3s_cnames" {
  description = "List of CNAME resource records to point to the cluster"
  type        = list(string)
  default     = []
}

variable "enable_live_cnames" {
  description = "Create additional CNAME resource records for live services?"
  type        = bool
  default     = false
}

variable "enable_dev_cnames" {
  description = "Create additional CNAME resource records for dev services?"
  type        = bool
  default     = false
}

###############################################################################
###############################################################################
##
##  Resource Definitions
##
###############################################################################
###############################################################################
resource "dns_a_record_set" "k3s_vip" {
  zone = "${var.site_domain}."
  name = var.k3s_vip_hostname
  addresses = [ var.k3s_vip ]
  ttl = 300
}

resource "dns_cname_record" "k3s_cnames" {
  depends_on = [
    resource.dns_a_record_set.k3s_vip
  ]
  count = var.enable_live_cnames ? length(var.k3s_cnames) : 0
  zone = "${var.site_domain}."
  name  = var.k3s_cnames[count.index]
  cname = "${var.k3s_vip_hostname}.${var.site_domain}."
  ttl = 300
}

resource "dns_cname_record" "k3s_vip_cnames" {
  depends_on = [
    resource.dns_a_record_set.k3s_vip
  ]
  count = length(var.k3s_cnames)
  zone = "${var.site_domain}."
  name  = "${var.k3s_vip_hostname}-${var.k3s_cnames[count.index]}"
  cname = "${var.k3s_vip_hostname}.${var.site_domain}."
  ttl = 300
}

resource "dns_cname_record" "k3s_dev_cnames" {
  depends_on = [
    resource.dns_a_record_set.k3s_vip
  ]
  count = var.enable_dev_cnames ? length(var.k3s_cnames) : 0
  zone = "${var.site_domain}."
  name  = "dev-${var.k3s_cnames[count.index]}"
  cname = "${var.k3s_vip_hostname}.${var.site_domain}."
  ttl = 300
}

resource "dns_a_record_set" "k3s_initial_cp" {
  for_each    = { for vm in var.vms : vm.hostname => vm if vm.role == "k3s_initial_cp" }
  zone = "${var.site_domain}."
  name = each.key
  addresses = [ split("/", each.value.ipv4_address)[0] ]
  ttl = 300
}

resource "dns_a_record_set" "k3s_servers" {
  for_each    = { for vm in var.vms : vm.hostname => vm if vm.role == "k3s_server" }
  zone = "${var.site_domain}."
  name = each.key
  addresses = [ split("/", each.value.ipv4_address)[0] ]
  ttl = 300
}

resource "dns_a_record_set" "k3s_agents" {
  for_each    = { for vm in var.vms : vm.hostname => vm if vm.role == "k3s_agent" }
  zone = "${var.site_domain}."
  name = each.key
  addresses = [ split("/", each.value.ipv4_address)[0] ]
  ttl = 300
}

resource "dns_a_record_set" "k3s_db_workers" {
  for_each    = { for vm in var.vms : vm.hostname => vm if vm.role == "k3s_db_worker" }
  zone = "${var.site_domain}."
  name = each.key
  addresses = [ split("/", each.value.ipv4_address)[0] ]
  ttl = 300
}
