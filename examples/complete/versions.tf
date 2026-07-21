terraform {
  required_version = ">= 1.3"
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = ">= 4.0, < 6"
    }
    sops = {
      source  = "carlpett/sops"
      version = "~> 1.3"
    }
  }
}
