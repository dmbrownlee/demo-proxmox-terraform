# This block specifies the version number of Terraform (I'm actually using
# OpenTofu) and the required provider plugins Terraform will install when
# running 'terraform init' (or 'terraform init -upgrade' when the version
# numbers are updated).  The '~>' notation is like >= except that the actual
# version must have the same major number.
terraform {
  required_version = "~> 1.9.1"
  required_providers {
    dns = {
      source  = "hashicorp/dns"
      version = "~> 3.4.3"
    }
  }
}

provider "dns" {
  update {
    server        = var.dns_server
    key_name      = var.dns_key_name
    key_algorithm = var.dns_key_algorithm
    key_secret    = var.dns_key_secret
  }
}

