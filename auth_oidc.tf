check "oidc_requires_credentials" {
  assert {
    condition = !var.enable_oidc || (
      var.oidc_client_id != null && var.oidc_client_id != "" &&
      var.oidc_client_secret != null && var.oidc_client_secret != ""
    )
    error_message = "enable_oidc=true requires oidc_client_id and oidc_client_secret."
  }
}

check "oidc_requires_roles" {
  assert {
    condition     = !var.enable_oidc || length(local.oidc_all_bindings) > 0
    error_message = "enable_oidc=true requires at least one oidc_roles or oidc_users entry."
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

resource "vault_jwt_auth_backend_role" "oidc" {
  for_each = var.enable_oidc ? local.oidc_all_bindings : {}

  backend        = vault_jwt_auth_backend.oidc[0].path
  role_name      = each.value.role_name
  role_type      = "oidc"
  user_claim     = "email"
  oidc_scopes    = var.oidc_scopes
  token_policies = each.value.token_policies
  token_ttl      = each.value.token_ttl
  token_max_ttl  = each.value.token_max_ttl
  token_type     = "default"

  allowed_redirect_uris = var.oidc_redirect_uris
  bound_audiences       = [var.oidc_client_id]

  bound_claims = merge(
    var.oidc_hosted_domain != null && var.oidc_hosted_domain != "" ? { hd = var.oidc_hosted_domain } : {},
    each.value.bound_email != null ? { email = each.value.bound_email } : {},
  )

  claim_mappings = {
    email = "email"
    name  = "name"
  }

  depends_on = [vault_policy.this]
}
