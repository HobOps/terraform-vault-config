# SOPS-encrypted secrets for this Vault:
# - vault.token
# - google_oidc.client_id / google_oidc.client_secret
# - approle_secret_ids.<role> (optional)
module "vault_config" {
  source = "../.."

  enable_oidc    = local.enable_oidc
  enable_approle = local.enable_approle
  kv_mounts      = local.kv_mounts

  policies = local.policies

  oidc_client_id     = data.sops_file.vault_secrets.data["google_oidc.client_id"]
  oidc_client_secret = data.sops_file.vault_secrets.data["google_oidc.client_secret"]
  oidc_hosted_domain = local.oidc_hosted_domain
  oidc_redirect_uris = local.oidc_redirect_uris
  oidc_roles         = local.oidc_roles
  oidc_users         = local.oidc_users

  approle_roles = {
    for name, role in local.approle_roles : name => merge(role, {
      secret_id = try(data.sops_file.vault_secrets.data["approle_secret_ids.${name}"], null)
    })
  }
}

output "oidc_role_names" {
  value = module.vault_config.oidc_role_names
}

output "approle_role_ids" {
  value = module.vault_config.approle_role_ids
}

output "approle_secret_ids" {
  sensitive = true
  value     = module.vault_config.approle_secret_ids
}

output "oidc_redirect_uris" {
  value = module.vault_config.oidc_redirect_uris
}
