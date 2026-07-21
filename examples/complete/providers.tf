data "sops_file" "vault_secrets" {
  source_file = local.secrets_file
  input_type  = "yaml"
}

provider "vault" {
  address          = local.vault_address
  token            = data.sops_file.vault_secrets.data["vault.token"]
  skip_child_token = true
}
