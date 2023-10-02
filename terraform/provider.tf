# See the argument reference documentation for how to configure the Proxmox
# Provider for Terraform:
# https://github.com/Telmate/terraform-provider-proxmox/blob/master/docs/index.md
provider "proxmox" {
  pm_api_url          = var.my_api_url
  pm_api_token_secret = var.my_api_token_secret
  pm_api_token_id     = var.my_api_token_id
  pm_tls_insecure     = true
  pm_log_enable       = true
  pm_log_file         = "terraform-plugin-proxmox.log"
  pm_debug            = true
  pm_log_levels = {
    _default    = "debug"
    _capturelog = ""
  }
}
