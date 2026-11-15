check "oidc_requires_credentials" {
  assert {
    condition = !var.enable_oidc || (
      var.oidc_client_id != null && var.oidc_client_id != "" &&
      var.oidc_client_secret != null && var.oidc_client_secret != ""
    )
    error_message = "enable_oidc=true requires oidc_client_id and oidc_client_secret."
  }
}

check "oidc_requires_redirect_uris" {
  assert {
    condition     = !var.enable_oidc || length(var.oidc_redirect_uris) > 0
    error_message = "enable_oidc=true requires oidc_redirect_uris (UI + CLI callbacks)."
  }
}

resource "vault_jwt_auth_backend" "oidc" {
  count = var.enable_oidc ? 1 : 0

  path               = var.oidc_path
  type               = "oidc"
  description        = "OIDC SSO for human operators"
  oidc_discovery_url = var.oidc_discovery_url
  oidc_client_id     = var.oidc_client_id
  oidc_client_secret = var.oidc_client_secret
  default_role       = local.oidc_default_role
  bound_issuer       = var.oidc_bound_issuer

  tune {
    default_lease_ttl  = var.oidc_default_lease_ttl
    max_lease_ttl      = var.oidc_max_lease_ttl
    listing_visibility = "unauth"
  }
}

# Domain login role (Role blank). Anyone matching hd can enter with no secrets access.
# Extra access is granted later via Identity entities (oidc_users / oidc_roles.bound_emails).
resource "vault_jwt_auth_backend_role" "oidc_default" {
  count = var.enable_oidc ? 1 : 0

  backend         = vault_jwt_auth_backend.oidc[0].path
  role_name       = "default"
  role_type       = "oidc"
  user_claim      = "email"
  oidc_scopes     = var.oidc_scopes
  token_policies  = ["default"]
  token_ttl       = 3600
  token_max_ttl   = 14400
  token_type      = "default"
  bound_audiences = [var.oidc_client_id]

  allowed_redirect_uris = var.oidc_redirect_uris

  # Only enforce Workspace domain — do NOT bind email here (provider mangles JSON lists).
  bound_claims = var.oidc_hosted_domain != null && var.oidc_hosted_domain != "" ? {
    hd = var.oidc_hosted_domain
  } : {}

  claim_mappings = {
    email = "email"
    name  = "name"
  }

  depends_on = [vault_policy.this]
}

# Optional named roles (bound_emails empty): selected explicitly at login (e.g. ops).
resource "vault_jwt_auth_backend_role" "oidc_open" {
  for_each = var.enable_oidc ? local.oidc_open_role_bindings : {}

  backend         = vault_jwt_auth_backend.oidc[0].path
  role_name       = each.value.role_name
  role_type       = "oidc"
  user_claim      = "email"
  oidc_scopes     = var.oidc_scopes
  token_policies  = each.value.token_policies
  token_ttl       = each.value.token_ttl
  token_max_ttl   = each.value.token_max_ttl
  token_type      = "default"
  bound_audiences = [var.oidc_client_id]

  allowed_redirect_uris = var.oidc_redirect_uris

  bound_claims = var.oidc_hosted_domain != null && var.oidc_hosted_domain != "" ? {
    hd = var.oidc_hosted_domain
  } : {}

  claim_mappings = {
    email = "email"
    name  = "name"
  }

  depends_on = [vault_policy.this]
}

# Extra policies for specific humans (applied on top of the default login token).
resource "vault_identity_entity" "oidc_user" {
  for_each = var.enable_oidc ? local.oidc_identity_policies : {}

  name     = each.key
  policies = each.value

  depends_on = [vault_policy.this]
}

resource "vault_identity_entity_alias" "oidc_user" {
  for_each = var.enable_oidc ? local.oidc_identity_policies : {}

  name           = each.key
  mount_accessor = vault_jwt_auth_backend.oidc[0].accessor
  canonical_id   = vault_identity_entity.oidc_user[each.key].id
}
