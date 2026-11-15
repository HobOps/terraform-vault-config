output "policies" {
  description = "Vault policy names managed by this module."
  value       = sort(keys(vault_policy.this))
}

output "kv_mount_paths" {
  description = "KV v2 mount paths created by this module."
  value       = sort(keys(vault_mount.kv))
}

output "kv_mount_path" {
  description = "Deprecated: first KV mount path, or null. Prefer kv_mount_paths."
  value       = try(sort(keys(vault_mount.kv))[0], null)
}

output "oidc_path" {
  description = "OIDC auth mount path (null if enable_oidc is false)."
  value       = var.enable_oidc ? vault_jwt_auth_backend.oidc[0].path : null
}

output "oidc_role_names" {
  description = "OIDC role names created in Vault (includes default when identity login is used)."
  value       = var.enable_oidc ? local.oidc_role_names : []
}

output "oidc_default_role" {
  description = "Default OIDC role used when the client does not specify one."
  value       = var.enable_oidc ? local.oidc_default_role : null
}

output "oidc_identity_users" {
  description = "Allowlisted OIDC emails and their Identity policies (blank Role login)."
  value       = var.enable_oidc ? local.oidc_identity_policies : {}
}

output "oidc_redirect_uris" {
  description = "Redirect URIs that must be registered on the OIDC provider."
  value       = var.oidc_redirect_uris
}

output "approle_path" {
  description = "AppRole auth mount path (null if enable_approle is false)."
  value       = var.enable_approle ? vault_auth_backend.approle[0].path : null
}

output "approle_role_ids" {
  description = "AppRole role_id values for workloads (not secret)."
  value = var.enable_approle ? {
    for name, role in vault_approle_auth_backend_role.this :
    name => role.role_id
  } : {}
}

output "approle_secret_ids" {
  description = "AppRole secret_id values for workloads (sensitive)."
  sensitive   = true
  value = var.enable_approle ? {
    for name, sid in vault_approle_auth_backend_role_secret_id.this :
    name => sid.secret_id
  } : {}
}
