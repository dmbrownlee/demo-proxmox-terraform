###############################################################################
###############################################################################
##
##  Variable Definitions
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

# These variables are for site specific DNS records
variable "site_domain" {
  description = "The DNS domain (used in cloud-init data when creating VMs)"
  type        = string
  default     = "example.com"
}

variable "static_a_records" {
  description = "List of static A record objects"
  type = list(object({
    name      = string,
    addresses = list(string)
  }))
  default = []
}

###############################################################################
###############################################################################
##
##  Resource Definitions
##
###############################################################################
###############################################################################
resource "dns_a_record_set" "static_a_records" {
  count     = length(var.static_a_records)
  zone      = "${var.site_domain}."
  name      = var.static_a_records[count.index].name
  addresses = var.static_a_records[count.index].addresses
  ttl       = 300
}
