check "approle_requires_roles" {
  assert {
    condition     = !var.enable_approle || length(var.approle_roles) > 0
    error_message = "enable_approle=true requires at least one approle_roles entry."
  }
}

resource "vault_auth_backend" "approle" {
  count = var.enable_approle ? 1 : 0

  type        = "approle"
  path        = var.approle_path
  description = "AppRole auth for workloads"

  tune {
    default_lease_ttl = var.approle_default_lease_ttl
    max_lease_ttl     = var.approle_max_lease_ttl
  }
}

resource "vault_approle_auth_backend_role" "this" {
  for_each = var.enable_approle ? var.approle_roles : {}

  backend               = vault_auth_backend.approle[0].path
  role_name             = each.key
  token_policies        = each.value.token_policies
  token_ttl             = each.value.token_ttl
  token_max_ttl         = each.value.token_max_ttl
  secret_id_ttl         = each.value.secret_id_ttl
  token_bound_cidrs     = each.value.cidr_list
  secret_id_bound_cidrs = each.value.cidr_list
  bind_secret_id        = true

  depends_on = [vault_policy.this]
}

resource "vault_approle_auth_backend_role_secret_id" "this" {
  for_each = var.enable_approle ? var.approle_roles : {}

  backend   = vault_auth_backend.approle[0].path
  role_name = vault_approle_auth_backend_role.this[each.key].role_name
  cidr_list = each.value.cidr_list

  secret_id = try(local.approle_secret_ids_fixed[each.key], null)
}
