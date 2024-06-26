# Set to true if you want Terraform to provision the K8S control plane nodes
# and worker nodes as well as the associated load balancers.
variable "want_k8s" {
  type    = bool
  default = false
}

# Set to true if you want to see the output of ansible playbooks
variable "want_ansible_output" {
  type    = bool
  default = false
}

# Set to true if you want Terraform to provision minikube
variable "want_minikube" {
  type    = bool
  default = false
}

# Set to true if you want Terraform to provision k3s
variable "want_k3s" {
  type    = bool
  default = false
}

# Set to true if you want Terraform to provision k3s
variable "want_k3s_master" {
  type    = bool
  default = true
}

# Set to true if you want Terraform to provision k3s
variable "want_k3s_servers" {
  type    = bool
  default = true
}

# Set to true if you want Terraform to provision k3s
variable "want_k3s_agents" {
  type    = bool
  default = true
}

# Set to true if you want Terraform to provision yunohost
variable "want_yunohost" {
  type    = bool
  default = false
}

# Set to true if you want Terraform to provision photos (immich) in k3s
variable "want_k3s_photos" {
  type    = bool
  default = false
}

variable "site_domain" {
  description = "The DNS domain (used in cloud-init data when creating VMs)"
  type        = string
  default     = "example.com"
}

variable "node_vlan_interfaces" {
  type = map(string)
}

variable "ssh_keystore" {
  description = "Path to directory of SSH keys"
  type        = string
  default     = "~/keys"
}

variable "vlans" {
  description = "Map of VLAN objects indexed on name"
  type = list(object({
    vlan_id          = number,
    comment          = string
    ipv4_gateway     = string,
    ipv4_dns_servers = list(string)
  }))
}

variable "ansible_replayable" {
  description = "Flag whether or not Ansible playbooks can be run again."
  type        = bool
  default     = true
}

variable "vm_templates" {
  description = "Map of VM template objects keyed on template name"
  type = map(object({
    vm_id            = number,
    url       = string,
    file_name = string
  }))
}

#===========================================================
# These variables are used by the Terraform Proxmox provider
#
# Rather than editng the default values here, you can
# override them in terraform.tfvars
#===========================================================
variable "api_token" {
  description = "Proxmox API token"
  type        = string
}

variable "endpoint" {
  description = "URL of the Proxmox cluster API"
  type        = string
  default     = "https://pve1.example.com:8006/"
}

variable "ci_user" {
  description = "Default cloud-init account"
  type        = string
  default     = "ansible"
}

variable "ci_password" {
  description = "Password for cloud-init account"
  type        = string
  sensitive   = true
}

variable "ssh_private_key_files" {
  description = "A map of SSH private key paths"
  type        = map(string)
}

variable "sleep_seconds_before_remote_provisioning" {
  description = "The number of seconds to wait after booting before trying SSH"
  type        = number
}

#=========================
# ISO image storage
#=========================
variable "iso_storage" {
  type = object({
    node = string,
    name = string
  })
}

#=========================
# VM template storage
#=========================
variable "vm_template_storage" {
  description = "Proxmox node and storage name where VM templates are stored"
  type = object({
    node = string,
    name = string
  })
}

#=========================
# VM storage
#=========================
variable "vm_storage" {
  description = "Name of Proxmox storage location where VM disks are stored"
  type        = string
}
